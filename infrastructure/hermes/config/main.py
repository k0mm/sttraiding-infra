import os
import httpx
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import StreamingResponse

app = FastAPI(title="Hermes")

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "")
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "")
DOMAIN = os.getenv("DOMAIN", "sttraiding.ru")
DEEPSEEK_BASE = "https://api.deepseek.com/v1"
OPENROUTER_BASE = "https://openrouter.ai/api/v1"


def _client() -> httpx.AsyncClient:
    # Use trust_env=False so system HTTPS_PROXY is ignored for LLM API calls.
    # DeepSeek and OpenRouter are reachable directly; the xray SOCKS5 proxy
    # breaks TLS for these hosts.
    return httpx.AsyncClient(trust_env=False, timeout=120)


def _route(model: str) -> tuple[str, str]:
    if model.startswith("deepseek"):
        if not DEEPSEEK_API_KEY:
            raise HTTPException(503, detail="DeepSeek API key not configured")
        return DEEPSEEK_BASE, DEEPSEEK_API_KEY
    if not OPENROUTER_API_KEY:
        raise HTTPException(503, detail="OpenRouter API key not configured")
    return OPENROUTER_BASE, OPENROUTER_API_KEY


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/")
def index():
    return {
        "service": "hermes",
        "providers": {
            "deepseek": bool(DEEPSEEK_API_KEY),
            "openrouter": bool(OPENROUTER_API_KEY),
        },
    }


@app.get("/v1/models")
def list_models():
    models = []
    if DEEPSEEK_API_KEY:
        models += [
            {"id": "deepseek-chat", "object": "model"},
            {"id": "deepseek-reasoner", "object": "model"},
        ]
    if OPENROUTER_API_KEY:
        models += [
            {"id": "openrouter/auto", "object": "model"},
            {"id": "anthropic/claude-sonnet-4-5", "object": "model"},
            {"id": "google/gemini-2.5-flash-preview-05-20", "object": "model"},
            {"id": "meta-llama/llama-4-maverick", "object": "model"},
            {"id": "mistralai/mistral-small-3.2-24b-instruct", "object": "model"},
        ]
    return {"object": "list", "data": models}


@app.post("/v1/chat/completions")
async def chat_completions(request: Request):
    body = await request.json()
    model = body.get("model", "")
    base_url, api_key = _route(model)

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    if base_url == OPENROUTER_BASE:
        headers["HTTP-Referer"] = f"https://hermes.{DOMAIN}"
        headers["X-Title"] = "Hermes"

    async with _client() as client:
        if body.get("stream", False):
            async def generate():
                async with client.stream(
                    "POST", f"{base_url}/chat/completions",
                    headers=headers, json=body,
                ) as resp:
                    async for chunk in resp.aiter_bytes():
                        yield chunk
            return StreamingResponse(generate(), media_type="text/event-stream")

        resp = await client.post(
            f"{base_url}/chat/completions",
            headers=headers, json=body,
        )
        resp.raise_for_status()
        return resp.json()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)

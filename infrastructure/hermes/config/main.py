import os
from fastapi import FastAPI

app = FastAPI(title="Hermes")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/")
def index():
    vault = os.getenv("OBSIDIAN_VAULT", "/vault")
    return {"service": "hermes", "vault": vault}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)

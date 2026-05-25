#!/usr/bin/env bash
# scripts/setup-hooks.sh
set -euo pipefail

HOOKS_DIR=".git/hooks"

cat > "${HOOKS_DIR}/pre-commit" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "=== Pre-commit checks ==="

# 1. Нет .env файлов в staged
if git diff --cached --name-only | grep -qE '(^|/)\\.env$'; then
  echo "❌ BLOCKED: .env файл в коммите! Удали из staged: git reset HEAD .env"
  exit 1
fi

# 2. Нет секретов (простая эвристика)
if git diff --cached | grep -qiE '(password|secret|token|private_key)[[:space:]]*=[[:space:]]*[^<$[:space:]]{8,}'; then
  echo "❌ BLOCKED: Возможный секрет в коммите. Проверь изменения."
  exit 1
fi

# 3. Валидация YAML файлов в staged
staged_yaml=$(git diff --cached --name-only | grep -E '\\.ya?ml$' || true)
if [ -n "$staged_yaml" ]; then
  command -v yamllint &>/dev/null && echo "$staged_yaml" | xargs yamllint -d relaxed
fi

# 4. Валидация docker-compose файлов
staged_compose=$(git diff --cached --name-only | grep 'docker-compose' || true)
if [ -n "$staged_compose" ]; then
  echo "$staged_compose" | while read f; do
    docker compose -f "$f" config -q && echo "✓ Valid: $f"
  done
fi

echo "=== Pre-commit passed ==="
EOF

chmod +x "${HOOKS_DIR}/pre-commit"
echo "Pre-commit hook installed."
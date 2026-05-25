# GitHub Secrets — Инструкция по настройке

> **Важно:** Эти секреты нужно добавить через GitHub UI: `Settings → Secrets → Actions`

## Обязательные Secrets

| Secret Name | Как получить | Назначение |
|-------------|-------------|-----------|
| `SERVER_HOST` | IP сервера: `104.128.140.235` | Адрес сервера для деплоя |
| `SERVER_SSH_KEY` | `cat /Users/pavelurev/.ssh/id_ed25519_server` | Приватный SSH-ключ deploy-пользователя |
| `DEPLOY_USER` | `deploy` | Имя deploy-пользователя на сервере |
| `DOMAIN` | `sttraiding.ru` | Основной домен проекта |
| `LETSENCRYPT_EMAIL` | `admin@sttraiding.ru` | Email для Let's Encrypt сертификатов |
| `AUTHELIA_JWT_SECRET` | `openssl rand -hex 32` | JWT секрет для Authelia |
| `AUTHELIA_SESSION_SECRET` | `openssl rand -hex 32` | Сессионный секрет для Authelia |
| `REDIS_PASSWORD` | `openssl rand -base64 24` | Пароль для Redis |
| `RESTIC_PASSWORD` | `openssl rand -base64 32` | Пароль шифрования Restic |
| `YANDEX_WEBDAV_USER` | `k0mm` | Логин Яндекс.Диск |
| `YANDEX_WEBDAV_PASS` | `odkiiaoqvnuviaqw` | App-пароль Яндекс.Диск |
| `XRAY_CONFIG_B64` | `base64 infrastructure/xray/config.json` | Xray конфиг в base64 |
| `TELEGRAM_BOT_TOKEN` | `8766047437:AAHHXIY7_g9HN9Ug64iMLj4ye3Tpo7gL2yc` | Токен Telegram бота |
| `TELEGRAM_CHAT_ID` | `233666126` | ID чата для уведомлений |

## Генерация секретов

Выполните эти команды локально для генерации секретов:

```bash
# JWT и Session секреты для Authelia
openssl rand -hex 32
openssl rand -hex 32

# Redis password
openssl rand -base64 24

# Restic password
openssl rand -base64 32

# Xray config (сначала создать config.json, затем закодировать)
echo '{"config": "here"}' | base64
```

## Порядок добавления

1. Зайдите в репозиторий на GitHub
2. Перейдите: `Settings → Secrets and variables → Actions`
3. В разделе `Repository secrets` добавьте все перечисленные выше Secrets
4. Для каждого Secret нажмите `New repository secret` и вставьте значение

## Проверка

После добавления Secrets можно протестировать workflow:

1. Сделайте коммит в любую ветку
2. Проверьте что CI workflow запускается и проходит
3. Сделайте push в main ветку
4. Проверьте что deploy workflow запускается (но упадет из-за отсутствия доступа к серверу)
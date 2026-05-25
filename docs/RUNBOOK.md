# RUNBOOK.md — Что делать при инцидентах

## 1. Быстрая диагностика

```bash
make status                    # статус всех контейнеров
make test-smoke                # smoke-тесты всех сервисов
docker ps -a                   # все контейнеры включая остановленные
```

## 2. Сервис не запускается

```bash
# Смотрим логи
make logs-s SVC=traefik

# Рестарт одного сервиса
docker compose -f infrastructure/traefik/docker-compose.yml restart

# Пересоздать контейнер
docker compose -f infrastructure/traefik/docker-compose.yml up -d --force-recreate
```

## 3. Traefik: сертификат не выдаётся

**Симптомы:** HTTPS не работает, браузер показывает "не защищено"

```bash
# Проверить лог Traefik на ошибки ACME
make logs-s SVC=traefik | grep -i "acme\|cert\|tls\|error"

# DNS проверить
dig sttraiding.ru +short
dig auth.sttraiding.ru +short   # должен быть 104.128.140.235

# acme.json должен быть непустым
docker exec $(docker ps -q -f name=traefik) cat /etc/traefik/acme/acme.json | wc -c
```

**Решение:** Убедиться что порт 80 открыт (Let's Encrypt httpChallenge), DNS указывает на сервер.

## 4. Authelia: не пускает / петля редиректов

```bash
# Проверить здоровье
curl https://auth.sttraiding.ru/api/health

# Логи
make logs-s SVC=authelia

# Redis подключён?
docker exec $(docker ps -q -f name=redis) redis-cli ping
```

**TOTP не работает:** Убедись что время на сервере верное:
```bash
timedatectl status
```

## 5. Syncthing: синхронизация не работает

```bash
make logs-s SVC=syncthing

# Проверить что obsidian-vault volume смонтирован
docker exec $(docker ps -q -f name=syncthing) ls /vault
```

Порт 22000 (sync protocol) не открыт в UFW — используются relay серверы.
Если нужна прямая синхронизация: `ufw allow 22000`

## 6. Backup: резервная копия не создаётся

```bash
# Принудительный запуск
make backup-now

# Последние снапшоты
make backup-status

# Проверить rclone конфиг
docker exec $(docker ps -q -f name=backup) rclone lsd yandex: --config /backup/rclone.conf
```

## 7. Rollback деплоя

```bash
# На сервере
cd /opt/sttraiding

# Показать предыдущий коммит
cat .last-deploy-prev

# Откат к предыдущему коммиту
git checkout $(cat .last-deploy-prev)

# Перезапуск всех сервисов
make deploy-infra
```

## 8. Очистка Docker

```bash
# Только если уверен — удаляет неиспользуемые образы
docker system prune -f

# Список volumes (осторожно — не удалять data volumes!)
docker volume ls
```

## 9. Контакты и эскалация

- Репозиторий: github.com/sttraiding/sttraiding-infra
- Сервер: 104.128.140.235
- Логи деплоя: GitHub Actions → Actions → Deploy

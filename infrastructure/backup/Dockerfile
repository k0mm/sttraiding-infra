FROM alpine:3.19

RUN apk add --no-cache \
    bash \
    curl \
    rclone \
    restic \
    tzdata \
    && rm -rf /var/cache/apk/*

WORKDIR /backup

COPY scripts/ ./scripts/
RUN chmod +x scripts/*.sh

ENV RESTIC_REPOSITORY=/restic-cache
ENV TZ=Europe/Moscow

HEALTHCHECK --interval=60s --timeout=10s --retries=3 --start-period=10s \
  CMD restic --no-lock snapshots &>/dev/null || exit 1

CMD ["/backup/scripts/entrypoint.sh"]

#!/bin/bash
set -e

# データを保存するマウントポイント
MOUNTPOINT=/mnt/data

# 作業ディレクトリ（docker-compose.yml がある場所）
WORKDIR="/opt/compose"

# Nginx の設定ファイルのパス
OPENAI_SITE_NAME="openai"

# 使用するコマンドの絶対パス（systemd 対策）
DOCKER="/usr/bin/docker"
NGINX="/usr/sbin/nginx"

command -v "$DOCKER" >/dev/null || { err "Docker not found at $DOCKER"; exit 1; }
command -v "$NGINX"  >/dev/null || { err "Nginx not found at $NGINX"; exit 1; }

# 作業ディレクトリに移動
if [ ! -d "$WORKDIR" ]; then
  err "Working directory $WORKDIR does not exist"
  exit 1
fi
cd "$WORKDIR"

log() {
  echo "[INFO] $1"
}

err() {
  echo "[ERROR] $1" >&2
}

start() {
  # log "Creating openai & Prometheus directories"
  # mkdir -p $MOUNTPOINT/{openai,mimir,prometheus,loki,tempo,pyroscope}
  # chown 472:472 $MOUNTPOINT/openai
  # mkdir -p /etc/openai/provisioning/{dashboards,datasources,alerting,plugins}

  log "Linking Nginx site: $OPENAI_SITE_NAME"
  ln -sf "/etc/nginx/sites-available/$OPENAI_SITE_NAME" "/etc/nginx/sites-enabled/$OPENAI_SITE_NAME"

  log "Reloading Nginx"
  $NGINX -t && $NGINX -s reload

  log "Starting OpenAI with Docker Compose"
  $DOCKER compose up -d
}

stop() {
  log "Unlinking Nginx site: $OPENAI_SITE_NAME"
  rm -f "/etc/nginx/sites-enabled/$OPENAI_SITE_NAME"

  log "Reloading Nginx"
  $NGINX -t && $NGINX -s reload

  log "Stopping OpenAI"
  $DOCKER compose down
}


case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    log "Restarting via stop + start"
    stop
    start
    ;;
  *)
    err "Usage: $0 {start|stop|restart}"
    exit 1
    ;;
esac

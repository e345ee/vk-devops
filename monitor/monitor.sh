#!/bin/bash
#
# Скрипт мониторинга Java-приложения с котиком.
# Функционал:
#  - читает конфиг (APP_PORT, APP_URL, CHECK_INTERVAL_SEC, LOG_FILE, APP_START_CMD);
#  - выставляет переменную окружения PORT для Java-приложения;
#  - запускает приложение;
#  - каждые N секунд проверяет его доступность;
#  - логирует состояние и ошибки в LOG_FILE и stdout;
#  - при недоступности перезапускает приложение.
#

set -e

CONF_FILE="/app/hello-monitor.conf"

# Загружаем конфиг, если он существует
if [[ -f "$CONF_FILE" ]]; then
  # Если файл существует, то мы подгружаем перменные из него
  source "$CONF_FILE"
fi

# Значения по умолчанию, если чего-то нет в конфиге/окружении
APP_PORT="${APP_PORT:-8080}"
APP_URL="${APP_URL:-http://127.0.0.1:${APP_PORT}/health}"
CHECK_INTERVAL_SEC="${CHECK_INTERVAL_SEC:-10}"
LOG_FILE="${LOG_FILE:-/var/log/hello-monitor.log}"
APP_START_CMD="${APP_START_CMD:-java -jar /app/hello-cat.jar}"

#Создаем файл для логов, если нет.
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

#Принимаем уровень сообщения и само сообщения, формируем строку и пием в файл.
log() {
  local level="$1"
  local msg="$2"
  local line
  line="$(date '+%Y-%m-%d %H:%M:%S') [$level] $msg"
  echo "$line" | tee -a "$LOG_FILE"
}

#Инициализируем переменную, в которой будет лежать pid Java приложения
APP_PID=""

start_app() {
  # Пробрасываем порт в Java через переменную окружения PORT
  export PORT="$APP_PORT"
  log "INFO" "Starting app on port $APP_PORT: $APP_START_CMD"
  bash -c "$APP_START_CMD" &
  APP_PID=$!
  log "INFO" "App started with PID $APP_PID"
}

stop_app() {
  if [[ -n "$APP_PID" ]] && kill -0 "$APP_PID" 2>/dev/null; then
    log "INFO" "Stopping cat app (PID $APP_PID)..."
    kill "$APP_PID" || true
    wait "$APP_PID" 2>/dev/null || true
  fi
}

# Корректное завершение при остановке контейнера
trap 'log "INFO" "Received stop signal"; stop_app; exit 0' SIGTERM SIGINT

start_app

# Основной вечный цикл мониторинга
while true; do
  if curl -s --max-time 5 --head "$APP_URL" | grep "200" > /dev/null; then
    log "INFO" "Application is UP ($APP_URL)"
  else
    log "ERROR" "Application is DOWN ($APP_URL). Restarting..."
    stop_app
    start_app
  fi

  sleep "$CHECK_INTERVAL_SEC"
done

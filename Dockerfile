#Выбирает базовый образ для сборки Java-приложения, затем устанавливаем рабочию директорию в контенере
FROM eclipse-temurin:17-jdk AS build
WORKDIR /app

# Копируем исходник и компилируем
COPY app/src/HelloCatServer.java .
RUN javac HelloCatServer.java

# Рантайм слой
FROM eclipse-temurin:17-jre
WORKDIR /app

# Устанавливаем curl и bash для мониторинга
RUN apt-get update \
    && apt-get install -y curl bash \
    && rm -rf /var/lib/apt/lists/*

# Копируем скомпилированные классы
COPY --from=build /app/HelloCatServer*.class /app/

# Создаем директорию внутри контенера и переносим туда изображение кота
RUN mkdir -p /app/static
COPY app/static/cat.jpg /app/static/cat.jpg

# Скрипт мониторинга и конфиг
COPY monitor/monitor.sh /app/monitor.sh
COPY monitor/hello-monitor.conf /app/hello-monitor.conf

# Удаляем Windows-символы CRLF ("^M") и даём скрипту права на исполнение
RUN sed -i 's/\r$//' /app/monitor.sh /app/hello-monitor.conf \
    && chmod +x /app/monitor.sh

# Дефолтные параметры
ENV APP_PORT=8080 \
    CHECK_INTERVAL_SEC=10 \
    LOG_FILE="/var/log/hello-monitor.log"

EXPOSE 8080

# Eсли APP_URL не задан, собираем из APP_PORT
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD : "${APP_URL:=http://127.0.0.1:${APP_PORT}/health}" && curl -fs "$APP_URL" || exit 1

ENTRYPOINT ["/app/monitor.sh"]

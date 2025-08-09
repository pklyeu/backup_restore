FROM ubuntu:22.04

# Метаданные
LABEL maintainer="Pavel K"
LABEL description="Ubuntu with PostgreSQL"

# Отключаем интерактивные запросы во время установки пакетов
ENV DEBIAN_FRONTEND=noninteractive

# Устанавливаем зависимости
RUN apt-get update && apt-get install -y \
    nano mc curl jq sudo \
    postgresql-client postgresql postgresql-contrib coreutils \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Инициализируем базу данных PostgreSQL
RUN mkdir -p /var/run/postgresql && chown -R postgres:postgres /var/run/postgresql
RUN mkdir -p /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql/data
USER postgres
RUN /usr/lib/postgresql/*/bin/initdb -D /var/lib/postgresql/data
USER root

# Рабочая директория
WORKDIR /app

# Копируем скрипт
COPY *.sh .
RUN chmod +x *.sh

# Запуск скрипта
CMD ["./script.sh"]

# Commands:
# build: docker build -f Dockerfile -t backup_restore .
# run:   docker run --rm --name=backup_restore_ubuntu --env ACCESS_TOKEN="{TOKEN}" backup_restore
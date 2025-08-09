# Инструкция по запуску backup_restore

## Необходимые зависимости

- Docker (https://www.docker.com/get-started)
- Доступ к интернету для скачивания образов и зависимостей
- Переменная окружения `ACCESS_TOKEN` (получить на https://hackattic.com/challenges/backup_restore/)

## Запуск на Windows или Linux

1. **Склонируйте или скачайте проект**  
   Перейдите в директорию с файлами `Dockerfile` и `script.sh`.

2. **Постройте Docker-образ**  
   Откройте терминал (PowerShell для Windows, bash для Linux) и выполните команду:  
   `docker build -f Dockerfile -t backup_restore .`

3. **Запустите контейнер с передачей ACCESS_TOKEN**
   Замените {TOKEN} на ваш реальный токен:  
   `docker run --rm --name=backup_restore_ubuntu --env ACCESS_TOKEN="{TOKEN}" backup_restore`

## Примечания

Все необходимые зависимости (PostgreSQL, curl, jq и др.) устанавливаются внутри контейнера автоматически.  
Для работы требуется установленный Docker и доступ к интернету.  
Скрипт запускается автоматически при старте контейнера.

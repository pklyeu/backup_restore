#!/bin/bash

# Конфигурация
DB_NAME="temp_restore"  # имя для БД
PG_USER="postgres"      # пользователь БД
# Настраиваем переменные окружения для PostgreSQL
export PGDATA=/var/lib/postgresql/data
export PGHOST=/var/run/postgresql

# Проверяем наличие переменной окружения ACCESS_TOKEN
if [ -z "$ACCESS_TOKEN" ]; then
    echo "Error: Variable ACCESS_TOKEN is not set"
    exit 1
fi

# Получаем дамп с удаленного сервера
echo -e "\n Get dump json from remote server"
DUMP_JSON=$(curl -s "https://hackattic.com/challenges/backup_restore/problem?access_token=$ACCESS_TOKEN")

# Debug
#echo "###### Print DUMP_JSON ################"
#echo $DUMP_JSON

# Декодируем base64 и сохраняем в файл
echo -e "\n Decode base64 and save dump to file"
echo "$DUMP_JSON" | jq -r .dump | base64 -d > backup.dump

# Проверяем формат дампа
echo -e "\n Check dump format"
file backup.dump

# Запускаем PostgreSQL сервер от имени пользователя postgres
echo -e "\n Start PostgreSQL server as postgres user in background"
su postgres -c "/usr/lib/postgresql/*/bin/postgres -D $PGDATA" &

# Даем время серверу на запуск
echo -e "\n Give time to PostgreSQL to start"
sleep 10

# Проверяем, что сервер запущен
echo -e "\n Check if server is running"
if ! pg_isready -U $PG_USER; then
    echo "Error: PostgreSQL server is not ready to connect"
    exit 1
fi
echo "PostgreSQL server is ready to connect"

# Создаем временную БД
echo -e "\n Create temporary database $DB_NAME"
createdb -U $PG_USER $DB_NAME

# Распаковываем gzip и восстанавливаем через psql
echo -e "\n Unpack gzip and restore dump to $DB_NAME via psql"
gunzip -c backup.dump | psql -U $PG_USER -d $DB_NAME

# Определяем как называется наша таблица
echo -e "\n Pull table name from restored database"
table_name=$(psql -U $PG_USER -d $DB_NAME -t -c \
    "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;")
echo " Found table with name $table_name"

# Debug
echo -e "\n ###### For debugging print first 10 strings from table $table_name ###############"
psql -U $PG_USER -d $DB_NAME -c "SELECT * FROM $table_name LIMIT 10;"
# Debug
echo -e "\n ###### For debugging print all SSN with status alive. First 10 strings only ######"
psql -U $PG_USER -d $DB_NAME -c "SELECT ssn FROM $table_name WHERE status = 'alive' LIMIT 10;"

# Извлекаем SSN с статусом alive, формируем JSON
echo -e "\n Get SSN with status alive from table $table_name, prepare JSON"
ALIVE_SSNS=$(psql -U $PG_USER -d $DB_NAME -t -c "SELECT ssn FROM $table_name WHERE status = 'alive';" | \
    jq -R -s -c 'split("\n") | map(select(. != ""))')
SOLUTION_JSON="{\"alive_ssns\": $ALIVE_SSNS}"
echo -e "\n Prepare JSON:"
echo $SOLUTION_JSON

# Формируем и отправляем решение
echo -e "\n Send solution to remote server"
curl -s -X POST \
    "https://hackattic.com/challenges/backup_restore/solve?access_token=$ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$SOLUTION_JSON"
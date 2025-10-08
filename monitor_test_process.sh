#!/bin/bash

PROCESS_NAME="test"
API_URL="https://test.com/monitoring/test/api"
LOG_FILE="/var/log/monitoring.log"
# Файл для хранения последнего известного состояния процесса (UP/DOWN)
STATE_FILE="/var/run/process_test.state"

# Функция для логирования с временной меткой
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Получаем предыдущее состояние. Если файла нет, считаем, что процесс был не запущен.
PREVIOUS_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "DOWN")

# Проверяем, запущен ли процесс 'test'
if pgrep -x "$PROCESS_NAME" > /dev/null; then
    # ПРОЦЕСС ЗАПУЩЕН
    CURRENT_STATE="UP"

    # Если предыдущее состояние было DOWN, значит процесс был перезапущен
    if [ "$PREVIOUS_STATE" == "DOWN" ]; then
        log_message "Процесс '$PROCESS_NAME' запущен (или перезапущен)."
    fi

    # Отправляем запрос на сервер мониторинга
    # -f: завершиться с ошибкой при кодах >=400
    # -s: тихий режим
    # -S: показывать ошибки даже в тихом режиме
    # --connect-timeout: таймаут на соединение
    if ! curl -fsS --connect-timeout 5 "$API_URL" > /dev/null; then
        log_message "Ошибка: Сервер мониторинга '$API_URL' недоступен."
    fi

else
    # ПРОЦЕСС НЕ ЗАПУЩЕН
    CURRENT_STATE="DOWN"
fi

# Сохраняем текущее состояние для следующей проверки
echo "$CURRENT_STATE" > "$STATE_FILE"

exit 0

##############################################################

sudo nano /etc/systemd/system/monitoring.service

Unit]
Description=Запуск скрипта мониторинга для процесса 'test'

[Service]
Type=oneshot
ExecStart=/usr/local/bin/monitor_test_process.sh

##############################################################

sudo nano /etc/systemd/system/monitoring.timer

[Unit]
Description=Запускать monitoring.service каждую минуту

[Timer]
# Запустить через 1 минуту после загрузки системы
OnBootSec=1min
# Запускать каждую минуту
OnUnitActiveSec=1min

[Install]
WantedBy=timers.target

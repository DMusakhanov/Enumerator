#!/bin/bash

check_dependencies() {
    local dependencies=("nmap" "dirsearch" "nikto" "dnsenum" "pandoc")
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "Ошибка: Необходимый инструмент '$dep' не найден."
            exit 1
        fi
    done
}

log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

select_tools() {
    echo "Choose an instrument for enumeration:"
    echo "1. nmap"
    echo "2. dirsearch"
    echo "3. nikto"
    echo "4. dnsenum"
    echo "5. All"

    read -p "Enter the number of instrument (e.g., 1 2): " tools
}

TARGET=$1
LOG_DIR="/home/kali/Desktop/logs"  # Укажите абсолютный путь к директории для логов
mkdir -p "$LOG_DIR"

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <IP or domain>"
    exit 1
fi

check_dependencies
select_tools

run_tools() {
    case $1 in
        1)
            NMAP_OUTPUT="${LOG_DIR}/nmap_${TARGET}.txt"
            log "Starting nmap for $TARGET"
            nmap -sV -sC -A $TARGET -oN "$NMAP_OUTPUT"
            ;;
        2)
            DIRSEARCH_OUTPUT="${LOG_DIR}/dirsearch_${TARGET}.txt"
            log "Starting dirsearch for $TARGET"
            dirsearch -u "http://$TARGET" -t 65 -e php,html,js -o "$DIRSEARCH_OUTPUT"
            ;;
        3)
            NIKTO_OUTPUT="${LOG_DIR}/nikto_${TARGET}.txt"
            log "Starting nikto for $TARGET"
            nikto -h $TARGET -o "$NIKTO_OUTPUT"
            ;;
        4)
            DNSENUM_OUTPUT="${LOG_DIR}/dnsenum_${TARGET}.txt"
            log "Starting dnsenum for $TARGET"
            dnsenum $TARGET > "$DNSENUM_OUTPUT"
            ;;
    esac
}

# Запуск инструментов
if [[ $tools == *"5"* ]]; then
    log "Starting all instruments for $TARGET"
    for i in {1..4}; do
        run_tools $i &
    done
else
    for tool in $tools; do
        run_tools $tool &
    done
fi

wait
log "Enumeration for $TARGET is done. Check folder $LOG_DIR to find results."

generate_pdf_report() {
    local report_name="${LOG_DIR}/report_${TARGET}.pdf"
    local tmp_report="${LOG_DIR}/tmp_report_${TARGET}.md"

    echo "Creating report for $TARGET"

    for file in "${LOG_DIR}"/*_${TARGET}.txt; do
        echo "## Results of $(basename "$file")" >> "$tmp_report"
        
        cat "$file" | tr -d '\033' >> "$tmp_report" 
        
        echo -e "\n\n" >> "$tmp_report"
    done

    pandoc "$tmp_report" -o "$report_name"

    rm "$tmp_report"

    echo "Report generated: $report_name"
}


generate_pdf_report

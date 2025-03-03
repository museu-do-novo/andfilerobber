#!/bin/bash

# Cores ANSI para mensagens de log
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir mensagens de log
log_message() {
    local level=$1
    local message=$2
    case $level in
        "INFO") echo -e "${BLUE}[INFO]${NC} ${message}" ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} ${message}" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} ${message}" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} ${message}" ;;
        *) echo -e "[${level}] ${message}" ;;
    esac
}

# Função para desconectar e corrigir possíveis problemas de conexão
disconnect() {
    log_message "INFO" "Desconectando todos os dispositivos..."
    adb disconnect >/dev/null 2>&1
    adb kill-server >/dev/null 2>&1
    log_message "SUCCESS" "Todos os dispositivos foram desconectados."
}

# Função para exibir ajuda
usage() {
    echo "Uso: $0 [-d] [-p IP PORTA CODIGO] [-h]"
    echo "  -d          Desconectar todos os dispositivos e parar o servidor ADB."
    echo "  -p IP PORTA CODIGO  Parear e conectar automaticamente ao dispositivo."
    echo "  -h          Exibir esta mensagem de ajuda."
    exit 0
}

# Função para parear o dispositivo via ADB
pairing() {
    local ip_add=$1
    local pairing_port=$2
    local code=$3

    log_message "INFO" "Pareando dispositivo no IP $ip_add, porta $pairing_port..."
    adb pair "$ip_add:$pairing_port" "$code"
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Falha ao parear o dispositivo."
        exit 1
    else
        log_message "SUCCESS" "Dispositivo pareado com sucesso."
    fi
    sleep 3
}

# Função para conectar ao dispositivo via ADB
connect() {
    local ip_add=$1
    local port=$2

    log_message "INFO" "Conectando ao dispositivo no IP $ip_add, porta $port..."
    adb connect "$ip_add:$port"
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Falha ao conectar ao dispositivo."
        exit 1
    else
        log_message "SUCCESS" "Conexão estabelecida com sucesso."
    fi
    sleep 2
}

# Função para verificar se o dispositivo com o IP fornecido está conectado
check_connection() {
    local ip_add=$1
    adb devices | grep "$ip_add" | grep "device" >/dev/null
    return $?
}

# Função principal
main() {
    local ip_add=$1
    local pairing_port=$2
    local code=$3

    # Parear e conectar
    pairing "$ip_add" "$pairing_port" "$code"
    connect "$ip_add" "$port"

    # Loop até que o dispositivo com o IP fornecido seja encontrado como "device"
    while true; do
        check_connection "$ip_add"
        if [[ $? -eq 0 ]]; then
            log_message "SUCCESS" "Dispositivo conectado com sucesso no IP: $ip_add"
            adb devices -l  # Lista os dispositivos conectados
            break
        else
            log_message "WARNING" "Falha na conexão. Tentando novamente..."
            sleep 2
            connect "$ip_add" "$port"  # Tenta conectar novamente
        fi
    done

    # Sai do loop principal quando o dispositivo estiver conectado
    adb wait-for-device
    log_message "SUCCESS" "Conexão estabelecida com o dispositivo no IP $ip_add. Pronto para usar."
}

# Verifica se o ADB está instalado
if ! command -v adb &>/dev/null; then
    log_message "ERROR" "ADB não está instalado ou não foi encontrado no PATH."
    exit 1
fi

# Parser de argumentos
while getopts ":dp:h" opt; do
    case $opt in
        d)
            disconnect
            exit 0
            ;;
        p)
            if [[ $# -lt 4 ]]; then
                log_message "ERROR" "A opção -p requer 3 argumentos: IP, PORTA e CÓDIGO."
                usage
            fi
            ip_add=$2
            pairing_port=$3
            code=$4
            port=${5:-5555}  # Porta de conexão padrão: 5555
            main "$ip_add" "$pairing_port" "$code" "$port"
            exit 0
            ;;
        h)
            usage
            ;;
        \?)
            log_message "ERROR" "Opção inválida: -$OPTARG"
            usage
            ;;
        :)
            log_message "ERROR" "A opção -$OPTARG requer um argumento."
            usage
            ;;
    esac
done

# Se nenhum argumento for fornecido, exibir ajuda
if [[ $OPTIND -eq 1 ]]; then
    usage
fi
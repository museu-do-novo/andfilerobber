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

# Função para desconectar todos os dispositivos e matar o servidor ADB
disconnect() {
    log_message "INFO" "Desconectando todos os dispositivos..."
    adb disconnect >/dev/null 2>&1  # Desconecta todos os dispositivos
    adb kill-server >/dev/null 2>&1 # Mata o servidor ADB
    log_message "SUCCESS" "Todos os dispositivos foram desconectados."
}

# Função para exibir ajuda
usage() {
    echo "Uso: $0 [-d] [-p PORTA] [-h]"
    echo "  -d          Desconectar todos os dispositivos e parar o servidor ADB."
    echo "  -p PORTA    Definir a porta TCP/IP para conexão ADB (padrão: 6666)."
    echo "  -h          Exibir esta mensagem de ajuda."
    exit 0
}

# Verifica se o ADB está instalado
check_adb_installed() {
    if ! command -v adb &> /dev/null; then
        log_message "ERROR" "ADB não está instalado ou não foi encontrado no PATH."
        exit 1
    fi
}

# Função principal para conectar via TCP/IP
connect_tcpip() {
    local porta=$1

    # Espera a conexão física do dispositivo Android
    log_message "INFO" "Aguardando conexão USB do dispositivo..."
    adb wait-for-device
    log_message "SUCCESS" "Dispositivo conectado via USB."

    # Mostra os dispositivos conectados via USB
    log_message "INFO" "Dispositivos conectados via USB:"
    adb devices

    # Ativa o modo TCP/IP na porta especificada
    log_message "INFO" "Ativando o modo TCP/IP na porta ${porta}..."
    adb tcpip ${porta}
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Falha ao ativar o modo TCP/IP na porta ${porta}. Verifique a conexão USB."
        exit 1
    else
        log_message "SUCCESS" "Modo TCP/IP ativado na porta ${porta}."
    fi

    # Aguarda brevemente até a ativação do TCP/IP
    sleep 5

    # Armazenando o endereço IP do dispositivo em uma variável
    log_message "INFO" "Obtendo o endereço IP do dispositivo..."
    ip_address=$(adb shell ip addr show wlan0 2>/dev/null | grep -oE 'inet [0-9.]+' | grep -oE '[0-9.]+')
    if [[ -z "$ip_address" ]]; then
        log_message "ERROR" "Não foi possível obter o endereço IP do dispositivo. Verifique se o Wi-Fi está ativado."
        exit 1
    else
        log_message "INFO" "Endereço IP do dispositivo: $ip_address"
    fi

    # Conectando ao dispositivo Android via ADB usando o endereço IP e a porta
    log_message "INFO" "Tentando conectar ao dispositivo via ADB em ${ip_address}:${porta}..."
    adb connect "${ip_address}:${porta}"
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Não foi possível conectar ao dispositivo via ADB."
        exit 1
    else
        log_message "SUCCESS" "Conexão estabelecida com sucesso via TCP/IP em ${ip_address}:${porta}."
    fi

    # Verifica se o dispositivo ainda está conectado via USB
    log_message "INFO" "Verificando se o dispositivo ainda está conectado via USB..."
    usb_device=$(adb devices | grep 'device$' | grep -v "${ip_address}")
    if [[ -n "$usb_device" ]]; then
        log_message "INFO" "Dispositivo ainda conectado via USB."
        log_message "INFO" "Você pode remover o cabo USB a qualquer momento. A conexão via TCP/IP foi estabelecida com sucesso."
    else
        log_message "INFO" "Dispositivo não está mais conectado via USB. Conexão via TCP/IP ativa."
    fi

    log_message "SUCCESS" "Conexão completa e pronta para depuração via Wi-Fi!"
    echo "*************"
}

# Verifica se o ADB está instalado
check_adb_installed

# Parser de argumentos
while getopts ":dp:h" opt; do
    case $opt in
        d)
            disconnect
            exit 0
            ;;
        p)
            porta=$OPTARG
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

# Define a porta padrão se não for fornecida
porta=${porta:-6666}

# Conectar via TCP/IP
connect_tcpip "$porta"
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

# funcao para obter o ip por meio da usb e facilitar oo fluxo do codigo
obtain_ip(){
    # Armazenando o endereço IP do dispositivo em uma variável
    log_message "INFO" "Obtendo o endereço IP do dispositivo..."
    ip_address=$(adb shell ip addr show wlan0 2>/dev/null | grep -oE 'inet [0-9.]+' | grep -oE '[0-9.]+')
    if [[ -z "$ip_address" ]]; then
        log_message "ERROR" "Não foi possível obter o endereço IP do dispositivo. Verifique se o Wi-Fi está ativado."
        exit 1
    else
        log_message "INFO" "Endereço IP do dispositivo: $ip_address"
    fi
}

# Função para exibir ajuda
usage() {
    echo "Uso: $0 [-d] [-p PORTA] [-a IP PORTA CODIGO] [-h]"
    echo "  -d                          Desconectar todos os dispositivos e parar o servidor ADB."
    echo "  -p PORTA                    Definir a porta TCP/IP para conexão ADB (padrão: 6666)."
    echo "  -a <IP> <PORTA> <CODIGO>    Parear e conectar automaticamente ao dispositivo."
    echo "  -h                          Exibir esta mensagem de ajuda."
    exit 0
}

# Função para parear o dispositivo via ADB
wireless_pairing() {
    ip_add=$1
    local pairing_port=$2
    local code=$3

    log_message "INFO" "Pareando dispositivo no IP $ip_add, porta $pairing_port..."
    adb pair "$ip_add:$pairing_port" "$code"
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Falha ao parear o dispositivo por wifi."
        exit 1
    else
        log_message "SUCCESS" "Dispositivo pareado por wifi com sucesso."
    fi
}

# Função para conectar ao dispositivo via ADB
connect() {

    # caso a funcao seja chamada sozinha tentara conectar no meu tcpip padrao
    local ip_add=${1:-$ip_address}
    local port=${2:-6666}

    log_message "INFO" "Conectando ao dispositivo no IP $ip_add, porta $port..."
    adb connect "$ip_add:$port"
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Falha ao conectar ao dispositivo."
        exit 1
    else
        log_message "SUCCESS" "Conexão estabelecida com sucesso."
    fi
}

# Função para verificar se o dispositivo com o IP fornecido está conectado
check_connection() {
    echo "Aguardando dispositivo..."
    adb wait-for-device
    sleep 2
    adb devices
    sleep 2
}

# CONFERIDO ATE AQUI
# Função principal para conectar via TCP/IP
# no rascunho


quiet_mode (){
    # ip, port, code and connection port (nao necessario se estiver diretamente pelo usb)

    echo pareando;
    read -p "entre com o host para emparelhamento" fullwifipairingip;
    adb pair "$fullwifipairingip" &&

    echo conectando emparelhamento;
    read -p "entre com os dados completos de conexao para o emparelhamento wifi" fullwificonnectingcode;
    adb connect "$fullwificonnectingcode" && 

    echo mudando para tcpip sem notificacao;

    adb -e tcpip 6666;
    adb -e connect $1:6666; || \
    echo error && exit 1

}

# Função principal para parear e conectar automaticamente
main() {
    local ip_add=${1:-$ip_address}
    local pairing_port=$2
    local code=$3
    local port=${4:-6666}  # Porta de conexão padrão: 5555
    clear;
    # Parear e conectar
    wireless_pairing "$ip_add" "$pairing_port" "$code"
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

# Parser de argumentos
while getopts ":dp:a:h" opt; do
    case $opt in
        d)
            disconnect
            exit 0
            ;;
        p)
            porta=$OPTARG
            connect
            exit 0
            ;;
        a)
            if [[ $# -lt 4 ]]; then
                log_message "ERROR" "A opção -a requer 3 argumentos: IP, PORTA e CÓDIGO."
                usage
            fi
            ip_add=$2
            pairing_port=$3
            code=$4
            main "$ip_add" "$pairing_port" "$code"
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
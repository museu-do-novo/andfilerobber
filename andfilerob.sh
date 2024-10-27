#!/bin/bash
# Simple android file robber

#================================================================================================
# Declaracoes
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
banner(){
    for i in {1..2}; do
        # Essa funcao faz o banner mudar de cor de acordo com o dispositivo estar conectado ou nao
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
banner

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

log_message info "Data atual: $data"
log_message info "Caminho dos arquivos: $path"
mkdir -p "$path"

log_message warning "INICIANDO..."

# Pausar por 3 segundos
sleep 1

#================================================================================================
# Encontre arquivos no dispositivo com a extensão informada e faça o download
adb shell find /sdcard/ -type f -iname "*.$filename" | while read -r file; do
    adb pull "$file" "./$path"
done
#================================================================================================

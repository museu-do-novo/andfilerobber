#!/bin/bash

# Definindo códigos de cores ANSI  
GREEN='\033[0;32m'  
BLUE='\033[0;34m'     # INFO  
YELLOW='\033[1;33m'   # WARNING  
RED='\033[0;31m'      # ERROR  
NC='\033[0m'          # No Color (reset)  

# Configurações globais
VERSION="1.6"
QUIET_MODE=false
TEMP_FILES=()
REPO_URL="https://github.com/museu-do-novo/andfilerobber.git"

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
    
    if $QUIET_MODE && [[ "$level" != "error" ]]; then
        return
    fi

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
    if check_device_connection; then  
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
${color}|                                                   V $VERSION   |
${color}'-----------------------------------------------------------'${NC}
EOF
}  

# Função para limpeza de arquivos temporários
cleanup() {
    log_message info "Limpando arquivos temporários..."
    for file in "${TEMP_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file" && log_message info "Arquivo temporário removido: $file"
        fi
    done
    exit 0
}

# UNIFICANDO O LUGAR DESSA MERDA de funcao
disconnect() {
    echo "INFO: Desconectando todos os dispositivos..."
    adb disconnect >/dev/null 2>&1  # Desconecta todos os dispositivos
    adb kill-server >/dev/null 2>&1 # Mata o servidor ADB
    echo "SUCCESS: Todos os dispositivos foram desconectados."
}


# Verifica se o dispositivo está conectado
check_device_connection() {
    if ! adb devices | grep -w "device" &> /dev/null; then
        log_message error "Dispositivo não conectado."
        return 1
    fi
    return 0
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
    
    adb shell find /sdcard/ -type f -iname "*.$filename" | while read -r file; do
        local basename=$(basename "$file")
        local local_path="$path/$basename"
        local temp_file="$local_path.tmp"
        
        # Verifica se o arquivo já existe
        if [[ -f "$local_path" ]]; then
            # Verificação de integridade (checksum)
            local remote_md5=$(adb shell md5sum "$file" | awk '{print $1}')
            local local_md5=$(md5sum "$local_path" | awk '{print $1}')
            
            if [[ "$remote_md5" == "$local_md5" ]]; then
                log_message info "Arquivo $basename já existe e está íntegro."
                continue
            else
                log_message warning "Arquivo $basename corrompido. Sobrescrevendo..."
            fi
        fi
        
        # Baixar para um arquivo temporário primeiro
        adb pull "$file" "$temp_file" && {
            mv "$temp_file" "$local_path"
            TEMP_FILES+=("$temp_file")
            log_message info "Arquivo $basename baixado."
        } || {
            log_message error "Falha ao baixar $basename."
            rm -f "$temp_file"
        }
    done
}  

# Função para verificar atualizações
check_for_updates() {
    log_message info "Verificando atualizações..."
    git ls-remote "$REPO_URL" | grep "refs/tags/$VERSION" || {
        log_message warning "Uma nova versão está disponível! Execute 'git pull' para atualizar."
    }
}

# Função para exibir a ajuda  
usage() {  
    echo "Uso: $0 [-p] [-c] [-a] [-f <extensão>] [-q] [-u] [-h]"  
    echo "  -p              Executa o script fastpair.sh"  
    echo "  -c              Executa o script fastconnect.sh"  
    echo "  -a              Executa o script autorat (extração de arquivos)"  
    echo "  -f <extensão>   Executa o script andfilerob para a extensão especificada"  
    echo "  -q              Modo silencioso (suprime mensagens não críticas)"  
    echo "  -u              Verificar atualizações"  
    echo "  -h              Exibe esta ajuda"  
    exit 1  
}  

# Configurar trap para Ctrl+C
trap cleanup SIGINT

# Verificação de dependências  
check_dependencies  

# Parser de argumentos  
while getopts ":pcaf:quh" opt; do  
    case "$opt" in  
        p) run_fastpair ;;  
        c) run_fastconnect ;;  
        a) autorat ;;  
        f) andfilerob "$OPTARG" ;;  
        q) QUIET_MODE=true ;;  
        u) check_for_updates ;;  
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

# Verificar conexão do dispositivo antes de operações críticas
check_device_connection || exit 1

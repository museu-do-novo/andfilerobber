#! /bin/bash
# Lista de dependências:

dependencias=("adb")

banner(){
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
    clear
    echo -e "${BLUE}- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ${NC}"
    echo -e "${BLUE}  ______     __  __     ______   ______     ______     ______     ______  ${NC}"
    echo -e "${BLUE} /\  __ \   /\ \/\ \   /\__  _\ /\  __ \   /\  == \   /\  __ \   /\__  _\ ${NC}"
    echo -e "${BLUE} \ \  __ \  \ \ \_\ \  \/_/\ \/ \ \ \/\ \  \ \  __<   \ \  __ \  \/_/\ \/ ${NC}"
    echo -e "${BLUE}  \ \_\ \_\  \ \_____\    \ \_\  \ \_____\  \ \_\ \_\  \ \_\ \_\    \ \_\ ${NC}"
    echo -e "${BLUE}   \/_/\/_/   \/_____/     \/_/   \/_____/   \/_/ /_/   \/_/\/_/     \/_/ ${NC}"
    echo -e "${BLUE} - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -${NC}"
    echo ""
    sleep 2
}

banner

# Fastpair/Fastconnect

# Função para executar o script fastpair.sh
run_fastpair() {
    if [[ -f fastpair.sh ]]; then
        bash fastpair.sh
        if [ $? -ne 0 ]; then
    	    exit 1
        fi
    else
        echo "Erro: Script 'fastpair.sh' não encontrado."
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
        echo "Erro: Script 'fastconnect.sh' não encontrado."
        exit 1
    fi

}

# Se o argumento 1 não for nulo (for passado), execute o script correspondente
if [[ ! -z "$1" ]]; then
    case "$1" in
        "-p")
            run_fastpair
            ;;
        "-c")
            run_fastconnect
            ;;
        *)
            echo "Argumento 1 inválido: $1"
            echo "Uso: [-p] || [-c]"
            ;;
    esac
fi

autorat(){

  # Definindo os nomes do argumento no array
  filenames=("jpg" "png" "jpeg" "gif" "raw" "webp" "opus" "mp4" "pdf" "zip")

  # Percorrendo todos os elementos para chamar o script varias vezes
  for element in "${filenames[@]}"; do
      while true; do
          bash ./andfilerob.sh "$element"
          exitcode=$?
          if [ $exitcode -eq 0 ]; then
            break
          else
            echo "Erro na pasta de $element"
            adb wait-for-device
          fi
      done
  done

}

autorat

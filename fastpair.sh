#!/bin/bash

# Função para desconectar e corrigir possíveis problemas de conexão
disconnect() {
    echo "INFO: Desconectando todos os dispositivos..."
    adb disconnect >/dev/null 2>&1
    adb kill-server >/dev/null 2>&1
    echo "SUCCESS: Todos os dispositivos foram desconectados."
}

# Função para exibir ajuda
usage() {
    echo "Uso: $0 [-d] [-p ]"
    echo "  -d          Desconectar todos os dispositivos e parar o servidor ADB."
    echo "  -p          Wizzard de pareamento"
    echo "  -h          Exibir esta mensagem de ajuda."
    exit 0
}

# Função para parear o dispositivo via ADB
pairing() {
    read -p "ip do host: " ip_add
    read -p "porta de parelhamento do host: " pairing_port
    echo "INFO: Pareando dispositivo no IP $ip_add, porta $pairing_port..."
    adb pair "$ip_add:$pairing_port"

    if [[ $? -ne 0 ]]; then
        echo "ERROR: Falha ao parear o dispositivo."
        exit 1
    else
        echo "SUCCESS: Dispositivo pareado com sucesso."
    fi
    sleep 3
}

# Função para conectar ao dispositivo via ADB
connect() {
    read -p "porta de conexao do host: " port

    echo "INFO: Conectando ao dispositivo no IP $ip_add, porta $port..."
    adb connect "$ip_add:$port"
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Falha ao conectar ao dispositivo."
        exit 1
    else
        echo "SUCCESS: Conexão estabelecida com sucesso."
    fi
    sleep 2
}

# Função principal
main() {
    # Parear e conectar
    pairing
    connect
    adb tcpip 6666
    adb disconnect 
    adb connect $ip_add:6666
    echo "SUCCESS: Conexão estabelecida com o dispositivo no IP $ip_add. Pronto para usar."
    adb devices
}

# Parser de argumentos
while getopts "dhp" opt; do
    case $opt in
        d)
            disconnect
            ;;
        p)
            main
            exit 0
            ;;
        h)
            usage
            ;;
        \?)
            echo "ERROR: Opção inválida: -$OPTARG"
            usage
            ;;
        :)
            echo "ERROR: A opção -$OPTARG requer um argumento."
            usage
            ;;
    esac
done

# Se nenhum argumento for fornecido, exibir ajuda
if [[ $OPTIND -eq 1 ]]; then
    usage
fi
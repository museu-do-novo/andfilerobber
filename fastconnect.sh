#!/bin/bash

# Função principal para conectar via TCP/IP
connect_tcpip() {
    local porta=${1:-6666}

    # Espera a conexão física do dispositivo Android
    echo "INFO: Aguardando conexão USB do dispositivo..."
    adb wait-for-device
    echo "SUCCESS: Dispositivo conectado via USB."

    # Mostra os dispositivos conectados via USB
    echo "INFO: Dispositivos conectados via USB:"
    adb devices

    # Ativa o modo TCP/IP na porta especificada
    echo "INFO: Ativando o modo TCP/IP na porta ${porta}..."
    adb tcpip ${porta}
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Falha ao ativar o modo TCP/IP na porta ${porta}. Verifique a conexão USB."
        exit 1
    else
        echo "SUCCESS: Modo TCP/IP ativado na porta ${porta}."
    fi

    # Aguarda brevemente até a ativação do TCP/IP
    sleep 5

    # Armazenando o endereço IP do dispositivo em uma variável
    echo "INFO: Obtendo o endereço IP do dispositivo..."
    ip_address=$(adb shell ip addr show wlan0 2>/dev/null | grep -oE 'inet [0-9.]+' | grep -oE '[0-9.]+')
    if [[ -z "$ip_address" ]]; then
        echo "ERROR: Não foi possível obter o endereço IP do dispositivo. Verifique se o Wi-Fi está ativado."
        exit 1
    else
        echo "INFO: Endereço IP do dispositivo: $ip_address"
    fi

    # Conectando ao dispositivo Android via ADB usando o endereço IP e a porta
    echo "INFO: Tentando conectar ao dispositivo via ADB em ${ip_address}:${porta}..."
    adb connect "${ip_address}:${porta}"
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Não foi possível conectar ao dispositivo via ADB."
        exit 1
    else
        echo "SUCCESS: Conexão estabelecida com sucesso via TCP/IP em ${ip_address}:${porta}."
    fi

    # Verifica se o dispositivo ainda está conectado via USB
    echo "INFO: Verificando se o dispositivo ainda está conectado via USB..."
    usb_device=$(adb devices | grep 'device$' | grep -v "${ip_address}")
    if [[ -n "$usb_device" ]]; then
        echo "INFO: Dispositivo ainda conectado via USB."
        echo "INFO: Você pode remover o cabo USB a qualquer momento. A conexão via TCP/IP foi estabelecida com sucesso."
    else
        echo "INFO: Dispositivo não está mais conectado via USB. Conexão via TCP/IP ativa."
    fi

}

# Conectar via TCP/IP
connect_tcpip "$1"
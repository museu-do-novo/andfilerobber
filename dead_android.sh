#!/bin/bash

# Função para desinstalar todos os aplicativos desinstaláveis
desinstalar_apps() {
    echo "Iniciando desinstalação de aplicativos..."
    adb shell pm list packages | awk -F ':' '{print $2}' | while read -r package; do
        echo "Tentando desinstalar $package"
        adb shell pm uninstall --user 0 "$package" || echo "Falha ao desinstalar $package"
    done
    echo "Processo de desinstalação concluído."
}

# Função para desativar todos os aplicativos desativáveis
desativar_apps() {
    echo "Iniciando desativação de aplicativos..."
    adb shell pm list packages | awk -F ':' '{print $2}' | while read -r package; do
        echo "Tentando desativar $package"
        adb shell pm disable-user --user 0 "$package" || echo "Falha ao desativar $package"
    done
    echo "Processo de desativação concluído."
}

# Função para remover permissões críticas de todos os aplicativos
remover_permissoes() {
    echo "Iniciando remoção de permissões..."
    adb shell pm list packages | awk -F ':' '{print $2}' | while read -r package; do
        echo "Removendo permissões do $package"
        adb shell pm revoke "$package" android.permission.INTERNET || echo "Falha ao revogar INTERNET de $package"
        adb shell pm revoke "$package" android.permission.CAMERA || echo "Falha ao revogar CAMERA de $package"
    done
    echo "Processo de remoção de permissões concluído."
}

# Função para corromper o estado dos aplicativos para forçar falhas
corromper_estado() {
    echo "Iniciando corrupção do estado dos aplicativos..."
    adb shell pm list packages | awk -F ':' '{print $2}' | while read -r package; do
        echo "Corrompendo estado do $package"
        adb shell appops set "$package" RUN_IN_BACKGROUND ignore || echo "Falha ao modificar $package"
        adb shell appops set "$package" RUN_ANY_IN_BACKGROUND ignore || echo "Falha ao modificar $package"
    done
    echo "Processo de corrupção de estado concluído."
}

# Função para alternar repetidamente ativação e desativação
alternar_estado() {
    echo "Iniciando alternância de estado dos aplicativos..."
    adb shell pm list packages | awk -F ':' '{print $2}' | while read -r package; do
        echo "Alternando estado do $package"
        adb shell pm disable-user --user 0 "$package" && sleep 2 && adb shell pm enable "$package"
    done
    echo "Processo de alternância concluído."
}

# Função principal para exibir menu e executar ações
main() {
    echo "Selecione a ação desejada:"
    echo "1) Desinstalar todos os aplicativos"
    echo "2) Desativar todos os aplicativos"
    echo "3) Remover permissões críticas"
    echo "4) Corromper estado dos aplicativos"
    echo "5) Alternar estado dos aplicativos"
    echo "6) Sair"
    read -p "Escolha uma opção: " opcao

    case $opcao in
        1) desinstalar_apps ;;
        2) desativar_apps ;;
        3) remover_permissoes ;;
        4) corromper_estado ;;
        5) alternar_estado ;;
        6) echo "Saindo..."; exit 0 ;;
        *) echo "Opção inválida. Tente novamente."; main ;;
    esac
}

# Iniciar script chamando a função principal
main

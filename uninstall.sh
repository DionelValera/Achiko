#!/bin/bash

# ===================================================================
# Script de Desinstalación para Onix Hyprdots
#
# Revierte los cambios de configuración realizados por install.sh,
# restaurando los dotfiles originales del usuario desde la copia
# de seguridad.
# ===================================================================

# Detener la ejecución si un comando falla
set -e

# --- Funciones de Utilidad ---
log() {
    echo -e "\n\e[1;34m=> $1\e[0m"
}

error() {
    echo -e "\n\e[1;31mERROR: $1\e[0m" >&2
    exit 1
}

confirm_action() {
    read -p "$1 [y/N]: " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# --- Verificaciones Iniciales ---
log "Iniciando verificaciones del sistema..."

# 1. Asegurarse de que el script se ejecute como root
if [[ "$EUID" -ne 0 ]]; then
  error "Este script necesita privilegios de root. Por favor, ejecútalo con 'sudo'."
fi

# --- Fases de Desinstalación ---

restore_dotfiles() {
    log "Iniciando la restauración de los dotfiles originales..."

    local SUDO_USER_NAME=${SUDO_USER:?SUDO_USER no está definido.}
    local HOME_DIR="/home/$SUDO_USER_NAME"

    # Encontrar el directorio de backup más reciente
    local LATEST_BACKUP
    LATEST_BACKUP=$(find "$HOME_DIR" -maxdepth 1 -type d -name ".dotfiles-backup-*" | sort -r | head -n 1)

    if [ -z "$LATEST_BACKUP" ]; then
        log "\e[1;33mADVERTENCIA: No se encontró ningún directorio de respaldo '.dotfiles-backup-*'. No se puede restaurar la configuración.\e[0m"
        return
    fi

    log "Se encontró el siguiente directorio de respaldo: $LATEST_BACKUP"
    if ! confirm_action "¿Deseas restaurar los archivos desde este respaldo?"; then
        log "Restauración cancelada por el usuario."
        return
    fi

    # 1. Eliminar los enlaces simbólicos creados por el instalador
    log "Eliminando los enlaces simbólicos de Onix Hyprdots..."
    local DOTFILES_SOURCE_PATH
    DOTFILES_SOURCE_PATH=$(pwd)/dotfiles

    cd "$HOME_DIR"
    find . -maxdepth 1 -type l | while read -r link; do
        if [[ $(readlink -f "$link") == "$DOTFILES_SOURCE_PATH/"* ]]; then
            log "  -> Eliminando enlace: $link"
            rm "$link"
        fi
    done
    cd - > /dev/null

    # 2. Restaurar los archivos desde la copia de seguridad
    log "Restaurando archivos desde '$LATEST_BACKUP'..."
    if sudo -u "$SUDO_USER_NAME" rsync -a "$LATEST_BACKUP/" "$HOME_DIR/"; then
        log "Archivos restaurados con éxito."
        if confirm_action "¿Deseas eliminar el directorio de respaldo '$LATEST_BACKUP' ahora que ha sido restaurado?"; then
            rm -rf "$LATEST_BACKUP"
            log "Directorio de respaldo eliminado."
        fi
    else
        error "Ocurrió un error al restaurar los archivos con rsync."
    fi
}

revert_grub_theme() {
    log "Restaurando la configuración de GRUB..."
    local GRUB_SCRIPT_PATH="scripts/install-grub-theme.sh"

    if [ ! -f "$GRUB_SCRIPT_PATH" ]; then
        log "\e[1;33mADVERTENCIA: No se encontró el script '$GRUB_SCRIPT_PATH'. No se puede revertir el tema de GRUB.\e[0m"
        return
    fi

    if confirm_action "¿Deseas desinstalar el tema de GRUB y restaurar la configuración por defecto?"; then
        ./"$GRUB_SCRIPT_PATH" uninstall
    else
        log "Se omitió la restauración de GRUB."
    fi
}

# --- Lógica Principal de Ejecución ---
main() {
    echo -e "\n\e[1;33m*** ASISTENTE DE DESINSTALACIÓN DE ONIX HYPRDOTS ***\e[0m"
    echo "Este script intentará revertir los cambios de CONFIGURACIÓN realizados en tu sistema."
    echo -e "\e[1;31mNO desinstalará los paquetes de software (pacman, aur, flatpak).\e[0m"

    if ! confirm_action "\n¿Estás seguro de que deseas continuar con la desinstalación?"; then
        log "Desinstalación cancelada."
        exit 0
    fi

    restore_dotfiles
    revert_grub_theme

    log "\e[1;32m¡Desinstalación de la configuración completada!\e[0m"
}

# Ejecutar la función principal
main
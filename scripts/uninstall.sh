#!/bin/bash

# ===================================================================
# Script de Desinstalación para Project Achiko
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
    # Si estamos en modo no interactivo, siempre retorna éxito (sí)
    [[ "$NON_INTERACTIVE" == "true" ]] && return 0
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
    log "Buscando y eliminando enlaces simbólicos de Project Achiko..."
    
    # Este método es más robusto: busca cualquier enlace simbólico en el home
    # que apunte a una ruta que contenga 'Achiko-hyprdots/dotfiles'.
    # Funciona incluso si el repositorio fue movido o eliminado.
    find "$HOME_DIR" -maxdepth 1 -type l | while read -r link; do
        # readlink -f resuelve la ruta completa del objetivo del enlace
        if readlink -f "$link" | grep -q "Achiko-hyprdots/dotfiles"; then
            log "  -> Eliminando enlace: $(basename "$link")"
            rm "$link"
        fi
    done

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

revert_component() {
    local component_name="$1" # e.g., "GRUB" or "SDDM"
    local script_path="$2"    # e.g., "scripts/install-grub-theme.sh"

    log "Restaurando la configuración de $component_name..."

    if [ ! -f "$script_path" ]; then
        log "\e[1;33mADVERTENCIA: No se encontró el script '$script_path'. No se puede revertir la configuración de $component_name.\e[0m"
        return
    fi

    if confirm_action "¿Deseas desinstalar la configuración de $component_name y restaurar los valores por defecto?"; then
        ./"$script_path" uninstall
    else
        log "Se omitió la restauración de $component_name."
    fi
}

# --- Lógica Principal de Ejecución ---
main() {
    # Procesar argumentos de línea de comandos
    NON_INTERACTIVE=false
    if [[ "$1" == "--noconfirm" ]]; then
        NON_INTERACTIVE=true
        log "Ejecutando en modo no interactivo. Se procederá sin confirmación."
    fi

    echo -e "\n\e[1;33m*** ASISTENTE DE DESINSTALACIÓN DE PROJECT ACHIKO ***\e[0m"
    echo "Este script intentará revertir los cambios de CONFIGURACIÓN realizados en tu sistema."
    echo -e "\e[1;31mNO desinstalará los paquetes de software (pacman, aur, flatpak).\e[0m"

    if [[ "$NON_INTERACTIVE" == "false" ]]; then
        if ! confirm_action "\n¿Estás seguro de que deseas continuar con la desinstalación?"; then
            log "Desinstalación cancelada."
            exit 0
        fi
    fi

    restore_dotfiles
    revert_component "SDDM" "scripts/install-sddm-theme.sh"
    revert_component "GRUB" "scripts/install-grub-theme.sh"

    log "\e[1;32m¡Desinstalación de la configuración completada!\e[0m"
}

# Ejecutar la función principal
main "$@"
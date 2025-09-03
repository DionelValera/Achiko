#!/bin/bash

# ===================================================================
# Script de Instalación para Onix Hyprdots
#
# Automatiza la instalación y configuración del entorno Hyprland
# basado en la guía del proyecto.
# ===================================================================

# Detener la ejecución si un comando falla
set -e

# --- Funciones de Utilidad ---
log() {
    # Imprime un mensaje de log con formato
    echo -e "\n\e[1;34m=> $1\e[0m"
}

error() {
    # Imprime un mensaje de error y sale del script
    echo -e "\n\e[1;31mERROR: $1\e[0m" >&2
    exit 1
}

# --- Verificaciones Iniciales ---
log "Iniciando verificaciones del sistema..."

# 1. Asegurarse de que el script se ejecute como root
if [[ "$EUID" -ne 0 ]]; then
  error "Este script necesita privilegios de root. Por favor, ejecútalo con 'sudo'."
fi

# 2. Verificar conexión a internet
if ! ping -c 1 -W 1 archlinux.org &> /dev/null; then
    error "No se detectó conexión a internet. Por favor, conéctate a una red para continuar."
fi

log "Verificaciones completadas. Iniciando instalación..."

# --- Fases de Instalación ---

update_system() {
    log "Actualizando el sistema con Pacman..."
    pacman -Syyu --noconfirm
}

install_pacman_packages() {
    log "Instalando paquetes esenciales desde los repositorios oficiales..."
    pacman -S --noconfirm --needed \
        hyprland sddm \
        ark kate dolphin okular gwenview \
        libreoffice-still libreoffice-still-es \
        git curl python npm \
        chromium vivaldi \
        nautilus gvfs-mtp \
        vlc fastfetch \
        flatpak \
        bluez bluez-utils \
        qt6-multimedia qt6-virtualkeyboard qt6-svg
}

install_aur_helper() {
    # Instala 'yay' si no se encuentra 'yay' o 'paru'
    if command -v yay &> /dev/null || command -v paru &> /dev/null; then
        log "Asistente de AUR (yay/paru) ya está instalado. Omitiendo."
        return
    fi

    log "Instalando 'yay' como asistente de AUR..."
    pacman -S --needed --noconfirm git base-devel
    
    # Es necesario ejecutar makepkg como un usuario normal, no como root.
    local SUDO_USER_NAME=${SUDO_USER:?SUDO_USER no está definido. Ejecuta con sudo.}
    local YAY_DIR="/tmp/yay-build"
    
    sudo -u "$SUDO_USER_NAME" git clone https://aur.archlinux.org/yay.git "$YAY_DIR"
    (cd "$YAY_DIR" && sudo -u "$SUDO_USER_NAME" makepkg -si --noconfirm)
    rm -rf "$YAY_DIR"
    
    log "'yay' instalado correctamente."
}

install_aur_packages() {
    local AUR_HELPER
    if command -v yay &> /dev/null; then AUR_HELPER="yay"; elif command -v paru &> /dev/null; then AUR_HELPER="paru"; else
        error "No se encontró un asistente de AUR. No se pueden instalar paquetes de AUR."
    fi

    log "Instalando paquetes desde AUR con '$AUR_HELPER'..."
    # El asistente de AUR no debe ejecutarse como root.
    local SUDO_USER_NAME=${SUDO_USER:?SUDO_USER no está definido.}
    sudo -u "$SUDO_USER_NAME" $AUR_HELPER -S --noconfirm \
        vscodium-bin vscodium-bin-marketplace \
        speedtest-go \
        waydroid \
        zen-browser-bin
}

install_flatpak_packages() {
    log "Instalando aplicaciones desde Flatpak..."
    flatpak install flathub --noninteractive --assumeyes \
        com.github.phase1geo.cohesion \
        org.gimp.GIMP.Plugin.Fotema \
        info.febvre.Amberol
}

install_grub_theme() {
    log "Configuración del tema de GRUB"
    local GRUB_SCRIPT_PATH="scripts/install-grub-theme.sh"

    if ! command -v grub-mkconfig &> /dev/null; then
        log "\e[1;33mADVERTENCIA: 'grub-mkconfig' no fue encontrado. Omitiendo la instalación del tema de GRUB.\e[0m"
        return
    fi
    
    if [ ! -f "$GRUB_SCRIPT_PATH" ]; then
        error "No se encontró el script '$GRUB_SCRIPT_PATH'."
        return
    fi
    
    chmod +x "$GRUB_SCRIPT_PATH"

    PS3=$'\n\e[1;33m¿Qué deseas hacer con el tema de GRUB? (introduce el número): \e[0m'
    options=(
        "Instalar o gestionar un tema para GRUB"
        "Desinstalar tema y restaurar GRUB a su estado anterior/por defecto"
        "Omitir este paso"
    )
    select opt in "${options[@]}"; do
        case $REPLY in
            1)
                ./"$GRUB_SCRIPT_PATH" install
                break ;;
            2)
                ./"$GRUB_SCRIPT_PATH" uninstall
                break ;;
            3)
                log "Omitiendo la configuración del tema de GRUB."
                break ;;
            *) echo -e "\e[31mOpción inválida. Inténtalo de nuevo.\e[0m";;
        esac
    done
}

copy_dotfiles() {
    log "Iniciando la gestión de dotfiles con el método de repositorio 'bare'..."
    
    local SUDO_USER_NAME=${SUDO_USER:?SUDO_USER no está definido.}
    local HOME_DIR="/home/$SUDO_USER_NAME"
    
    # URL de tu repositorio de dotfiles. ¡Asegúrate de que exista!
    # Por ahora, usaremos una URL de ejemplo. Reemplázala por la tuya.
    local DOTFILES_REPO_URL="https://github.com/DionelValera/Onix-hyprdots.git"
    local DOTFILES_DIR="$HOME_DIR/.dotfiles"
    local BACKUP_DIR="$HOME_DIR/.dotfiles-backup"
    
    # Alias para ejecutar git en nuestro repo bare
    local CONFIG_ALIAS="/usr/bin/git --git-dir=$DOTFILES_DIR --work-tree=$HOME_DIR"

    log "Clonando el repositorio de dotfiles como 'bare' en '$DOTFILES_DIR'..."
    # Clonar como el usuario para que sea el propietario
    sudo -u "$SUDO_USER_NAME" git clone --bare "$DOTFILES_REPO_URL" "$DOTFILES_DIR"

    log "Intentando hacer checkout de los dotfiles..."
    # Intentamos hacer checkout. Es probable que falle si hay archivos existentes.
    if sudo -u "$SUDO_USER_NAME" $CONFIG_ALIAS checkout; then
        log "Checkout de dotfiles completado con éxito en el primer intento."
    else
        log "Conflicto detectado. Realizando copia de seguridad de los archivos existentes..."
        sudo -u "$SUDO_USER_NAME" mkdir -p "$BACKUP_DIR"
        
        # Obtenemos la lista de archivos en conflicto y los movemos al backup
        local CONFLICTING_FILES
        CONFLICTING_FILES=$(sudo -u "$SUDO_USER_NAME" $CONFIG_ALIAS checkout 2>&1 | grep -E "^\s+" | awk '{print $1}')

        if [ -z "$CONFLICTING_FILES" ]; then
            error "El checkout falló por una razón desconocida. Revisa los permisos o la salida de git."
        fi

        log "Archivos en conflicto a respaldar:\n$CONFLICTING_FILES"
        # Usamos `rsync` para mover los archivos preservando su estructura de directorios
        echo "$CONFLICTING_FILES" | while read -r file; do
            # Asegurarse de que el directorio de destino exista en el backup
            sudo -u "$SUDO_USER_NAME" mkdir -p "$BACKUP_DIR/$(dirname "$file")"
            # Mover el archivo/directorio al backup
            sudo -u "$SUDO_USER_NAME" mv "$HOME_DIR/$file" "$BACKUP_DIR/$file"
        done

        log "Copia de seguridad completada. Reintentando checkout..."
        # Ahora el checkout debería funcionar
        sudo -u "$SUDO_USER_NAME" $CONFIG_ALIAS checkout
    fi

    # Establecer la configuración para no mostrar archivos no rastreados
    sudo -u "$SUDO_USER_NAME" $CONFIG_ALIAS config --local status.showUntrackedFiles no
    log "Gestión de dotfiles completada. Los archivos están en su lugar."
}

configure_services() {
    log "Habilitando servicios del sistema (SDDM, Bluetooth)..."
    systemctl enable sddm
    systemctl enable bluetooth
}

# --- Lógica Principal de Ejecución ---
main() {
    update_system
    install_pacman_packages
    install_aur_helper
    install_aur_packages
    install_flatpak_packages

    # Copiar dotfiles antes de configurar servicios que puedan depender de ellos
    copy_dotfiles

    install_grub_theme
    configure_services

    log "\e[1;32m¡Instalación de Onix Hyprdots completada!\e[0m"
    echo -e "Se recomienda reiniciar el sistema para aplicar todos los cambios."
    echo -e "Ejecuta: \e[1;33mreboot\e[0m"
}

# Ejecutar la función principal
main
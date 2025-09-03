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

    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        log "\e[1;33mModo no interactivo: Omitiendo configuración del tema de GRUB.\e[0m"
        return
    fi

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
    log "Iniciando la gestión de dotfiles con enlaces simbólicos..."
    
    local SUDO_USER_NAME=${SUDO_USER:?SUDO_USER no está definido.}
    local HOME_DIR="/home/$SUDO_USER_NAME"
    local SOURCE_DOTFILES_DIR
    SOURCE_DOTFILES_DIR=$(pwd)/dotfiles # Ruta absoluta a la carpeta dotfiles del repo
    local BACKUP_DIR="$HOME_DIR/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

    if [ ! -d "$SOURCE_DOTFILES_DIR" ]; then
        log "\e[1;33mADVERTENCIA: No se encontró el directorio 'dotfiles'. Omitiendo este paso.\e[0m"
        return
    fi

    log "Creando directorio de respaldo en '$BACKUP_DIR'..."
    sudo -u "$SUDO_USER_NAME" mkdir -p "$BACKUP_DIR"

    # Iterar sobre todos los archivos y carpetas en el directorio 'dotfiles'
    # find . -maxdepth 1 -mindepth 1 -> lista elementos en el dir actual sin incluir '.'
    cd "$SOURCE_DOTFILES_DIR"
    find . -maxdepth 1 -mindepth 1 -exec basename {} \; | while read -r item; do
        local source_path="$SOURCE_DOTFILES_DIR/$item"
        local dest_path="$HOME_DIR/$item"

        log "Procesando '$item'..."

        # Si el archivo/directorio de destino ya existe, moverlo al backup
        if [ -e "$dest_path" ] || [ -L "$dest_path" ]; then
            log "  -> Archivo/enlace existente encontrado. Moviendo a la copia de seguridad."
            sudo -u "$SUDO_USER_NAME" mv "$dest_path" "$BACKUP_DIR/"
        fi

        # Crear el enlace simbólico
        log "  -> Creando enlace simbólico: $dest_path -> $source_path"
        sudo -u "$SUDO_USER_NAME" ln -s "$source_path" "$dest_path"
    done
    cd - > /dev/null # Volver al directorio anterior silenciosamente
    
    log "Gestión de dotfiles completada. Los archivos están en su lugar."
}

configure_services() {
    log "Habilitando servicios del sistema (SDDM, Bluetooth)..."
    systemctl enable sddm
    systemctl enable bluetooth
}

# --- Lógica Principal de Ejecución ---
main() {
    # Procesar argumentos de línea de comandos
    NON_INTERACTIVE=false
    if [[ "$1" == "--noconfirm" ]]; then
        NON_INTERACTIVE=true
        log "Ejecutando en modo no interactivo. Se instalará todo sin confirmación."
    fi

    if confirm_action "Paso 1: ¿Actualizar el sistema y los repositorios? (Recomendado)"; then
        update_system
    fi
    if confirm_action "Paso 2: ¿Instalar paquetes esenciales de Pacman?"; then
        install_pacman_packages
    fi
    if confirm_action "Paso 3: ¿Instalar asistente de AUR (yay) y paquetes de AUR?"; then
        install_aur_helper
        install_aur_packages
    fi
    if confirm_action "Paso 4: ¿Instalar aplicaciones de Flatpak?"; then
        install_flatpak_packages
    fi
    if confirm_action "Paso 5: ¿Instalar la configuración de Onix (dotfiles)?"; then
        copy_dotfiles
    fi

    install_grub_theme # Esta función ya es interactiva y tiene su propia lógica
    configure_services # Esto no necesita confirmación, es una acción final

    log "\e[1;32m¡Instalación de Onix Hyprdots completada!\e[0m"
    echo -e "Se recomienda reiniciar el sistema para aplicar todos los cambios."
    echo -e "Ejecuta: \e[1;33mreboot\e[0m"
}

# Ejecutar la función principal
main "$@"
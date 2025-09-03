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
    local packages=(
        hyprland sddm ark kate dolphin okular gwenview
        libreoffice-still libreoffice-still-es git curl python npm
        chromium vivaldi nautilus gvfs-mtp vlc fastfetch flatpak
        bluez bluez-utils qt6-multimedia qt6-virtualkeyboard qt6-svg
    )
    
    # Filtrar paquetes que ya están instalados
    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! pacman -Q "$pkg" &> /dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -eq 0 ]; then
        log "Todos los paquetes de Pacman ya están instalados. Omitiendo."
        return
    fi

    log "Instalando: ${to_install[*]}"
    pacman -S --noconfirm --needed "${to_install[@]}"
}

install_aur_helper() {
    local SUDO_USER_NAME=${SUDO_USER:?SUDO_USER no está definido. Ejecuta con sudo.}

    # Instala 'yay' si no se encuentra 'yay' o 'paru'
    if sudo -u "$SUDO_USER_NAME" command -v yay &> /dev/null || sudo -u "$SUDO_USER_NAME" command -v paru &> /dev/null; then
        log "Asistente de AUR (yay/paru) ya está instalado. Omitiendo."
        return
    fi

    log "Instalando 'yay' como asistente de AUR..."
    pacman -S --needed --noconfirm git base-devel
    
    # Es necesario ejecutar makepkg como un usuario normal, no como root.
    local YAY_DIR="/tmp/yay-build"
    
    sudo -u "$SUDO_USER_NAME" git clone https://aur.archlinux.org/yay.git "$YAY_DIR"
    (cd "$YAY_DIR" && sudo -u "$SUDO_USER_NAME" makepkg -si --noconfirm)
    rm -rf "$YAY_DIR"
    
    log "'yay' instalado correctamente."
}

install_aur_packages() {
    local AUR_HELPER
    local SUDO_USER_NAME=${SUDO_USER:?SUDO_USER no está definido.}

    if sudo -u "$SUDO_USER_NAME" command -v yay &> /dev/null; then AUR_HELPER="yay"; elif sudo -u "$SUDO_USER_NAME" command -v paru &> /dev/null; then AUR_HELPER="paru"; else
        error "No se encontró un asistente de AUR. No se pueden instalar paquetes de AUR."
    fi

    log "Instalando paquetes desde AUR con '$AUR_HELPER'..."
    local packages=(
        vscodium-bin vscodium-bin-marketplace speedtest-go
        waydroid zen-browser-bin
    )

    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! sudo -u "$SUDO_USER_NAME" $AUR_HELPER -Q "$pkg" &> /dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -eq 0 ]; then
        log "Todos los paquetes de AUR ya están instalados. Omitiendo."
        return
    fi

    # El asistente de AUR no debe ejecutarse como root.
    log "Instalando: ${to_install[*]}"
    sudo -u "$SUDO_USER_NAME" $AUR_HELPER -S --noconfirm "${to_install[@]}"
}

install_flatpak_packages() {
    log "Instalando aplicaciones desde Flatpak..."
    local packages=(
        com.github.phase1geo.cohesion
        org.gimp.GIMP.Plugin.Fotema
        info.febvre.Amberol
    )

    # Obtener una lista de las aplicaciones de Flatpak ya instaladas
    local installed_flatpaks
    installed_flatpaks=$(flatpak list --app --columns=application)

    local to_install=()
    for pkg in "${packages[@]}"; do
        # Verificar si el paquete no está en la lista de instalados
        if ! echo "$installed_flatpaks" | grep -q "^$pkg$"; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -eq 0 ]; then
        log "Todas las aplicaciones de Flatpak ya están instaladas. Omitiendo."
        return
    fi

    log "Instalando: ${to_install[*]}"
    flatpak install flathub --noninteractive --assumeyes "${to_install[@]}"
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
    fi
    
    chmod +x "$GRUB_SCRIPT_PATH"

    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        log "Modo no interactivo: Instalando tema de GRUB predeterminado (Catppuccin Latte)..."
        # Llama al script del tema con el nombre del tema predeterminado y el flag noconfirm
        ./"$GRUB_SCRIPT_PATH" install "catppuccin-latte" --noconfirm
        return
    fi

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
    # Usamos -print0 y read -d '' para manejar de forma segura nombres con espacios o caracteres especiales.
    while IFS= read -r -d '' item_path; do
        local item
        item=$(basename "$item_path")
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
    done < <(find "$SOURCE_DOTFILES_DIR" -maxdepth 1 -mindepth 1 -print0)
    
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
#!/bin/bash

# =============================================================================
# Script de Instalación para Project Achiko
#
# Automatiza la instalación y configuración de un entorno Hyprland.
# Refactorizado para mayor legibilidad, mantenibilidad y corrección de errores.
# =============================================================================

# --- Configuración Inicial ---
# Detener la ejecución si un comando falla
set -e
# Ruta base del script para localizar otros archivos del proyecto
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# --- Cargar Dependencias ---
# Cargar las funciones de animación de carga
source "$SCRIPT_DIR/scripts/bash_loading_animations.sh"

# --- Variables Globales ---
AUR_HELPER=""
NON_INTERACTIVE=false
# Rutas a los archivos de paquetes
PACMAN_PKGS_FILE="$SCRIPT_DIR/etc/packages-txt/pacman_packages_definitivo.txt"
AUR_PKGS_FILE="$SCRIPT_DIR/etc/packages-txt/aur_packages_definitivo.txt"
FLATPAK_PKGS_FILE="$SCRIPT_DIR/etc/packages-txt/flatpak_packages_definitivo.txt"

# --- Funciones de Utilidad ---
log() {
    echo -e "\n\e[1;34m=> $1\e[0m"
}

error() {
    echo -e "\n\e[1;31mERROR: $1\e[0m" >&2
    exit 1
}

warning() {
    echo -e "\e[1;33mADVERTENCIA: $1\e[0m"
}

confirm_action() {
    # Si estamos en modo no interactivo, siempre retorna éxito (sí)
    [[ "$NON_INTERACTIVE" == "true" ]] && return 0
    # Enter significa 'sí'
    read -p "$1 [Y/n]: " -r
    [[ -z "$REPLY" || ! "$REPLY" =~ ^[Nn]$ ]]
}

# --- Fases de Instalación ---

read_packages_from_file() {
    local file_path=$1
    if [[ ! -f "$file_path" ]]; then
        warning "No se encontró el archivo de paquetes '$file_path'. Omitiendo."
        echo ""
        return
    fi
    # Lee el archivo, ignora líneas vacías y comentarios
    grep -v -e '^\s*#' -e '^\s*$' "$file_path" | tr '\n' ' '
}

update_system() {
    log "Actualizando el sistema con Pacman..."
    BLA::start_loading_animation "BLA_braille_whitespace"
    pacman -Syyu --noconfirm
    BLA::stop_loading_animation
}

install_pacman_packages() {
    log "Instalando paquetes de Pacman desde '$PACMAN_PKGS_FILE'..."
    local packages_to_install=($(read_packages_from_file "$PACMAN_PKGS_FILE"))

    if [ ${#packages_to_install[@]} -eq 0 ]; then
        log "No hay paquetes de Pacman para instalar. Omitiendo."
        return
    fi

    log "Paquetes a instalar: ${packages_to_install[*]}"
    BLA::start_loading_animation "BLA_braille_whitespace"
    pacman -S --noconfirm --needed "${packages_to_install[@]}"
    BLA::stop_loading_animation
    log "Instalación de paquetes de Pacman completada."
}

install_aur_helper() {
    local SUDO_USER_NAME=${SUDO_USER:?SUDO_USER no está definido. Ejecuta con sudo.}
 
    if pacman -Q paru &> /dev/null; then
        log "Asistente de AUR 'paru' ya está instalado."
        AUR_HELPER="paru"
        return
    elif pacman -Q yay &> /dev/null; then
        log "Asistente de AUR 'yay' ya está instalado."
        AUR_HELPER="yay"
        return
    fi
 
    log "No se encontró un asistente de AUR."
    local choice=""
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        log "Modo no interactivo: Instalando 'paru' por defecto."
        choice="paru"
    else
        PS3=$'\n\e[1;33m¿Qué asistente de AUR deseas instalar? (introduce el número): \e[0m'
        options=("paru (Rust)" "yay (Go)" "Omitir")
        select opt in "${options[@]}"; do
            case $REPLY in
                1) choice="paru"; break ;;
                2) choice="yay"; break ;;
                3) log "Se omitió la instalación del asistente de AUR."; return ;;
                *) echo -e "\e[31mOpción inválida.";;
            esac
        done
    fi
 
    log "Instalando dependencias de compilación (git, base-devel)..."
    pacman -S --needed --noconfirm git base-devel

    local BUILD_DIR="/tmp/$choice-build"
    rm -rf "$BUILD_DIR"
    log "Clonando 'aur.archlinux.org/$choice.git' en '$BUILD_DIR' கிலோ"
    sudo -u "$SUDO_USER_NAME" git clone "https://aur.archlinux.org/$choice.git" --depth=1 "$BUILD_DIR"

    log "Compilando e instalando '$choice' கிலோ"
    pushd "$BUILD_DIR" > /dev/null
    if [[ "$choice" == "paru" ]]; then
        pacman -S --needed --noconfirm rustup
        sudo -u "$SUDO_USER_NAME" rustup override set stable
        sudo -u "$SUDO_USER_NAME" rustup update stable
    elif [[ "$choice" == "yay" ]]; then
        pacman -S --needed --noconfirm go
    fi
    
    sudo -u "$SUDO_USER_NAME" makepkg -si --noconfirm
    popd > /dev/null
    rm -rf "$BUILD_DIR"
    
    AUR_HELPER="$choice"
    log "'$choice' instalado correctamente."
}

install_aur_packages() {
    if [ -z "$AUR_HELPER" ]; then
        log "No hay un asistente de AUR configurado. Omitiendo paquetes de AUR."
        return
    fi

    log "Instalando paquetes de AUR desde '$AUR_PKGS_FILE' con '$AUR_HELPER'..."
    local SUDO_USER_NAME=${SUDO_USER:?SUDO_USER no está definido.}
    local packages_to_install=($(read_packages_from_file "$AUR_PKGS_FILE"))

    if [ ${#packages_to_install[@]} -eq 0 ]; then
        log "No hay paquetes de AUR para instalar. Omitiendo."
        return
    fi

    log "Paquetes a instalar: ${packages_to_install[*]}"
    BLA::start_loading_animation "BLA_braille_whitespace"
    sudo -u "$SUDO_USER_NAME" "$AUR_HELPER" -S --noconfirm --needed "${packages_to_install[@]}"
    BLA::stop_loading_animation
    log "Instalación de paquetes de AUR completada."
}

install_flatpak_packages() {
    log "Instalando aplicaciones de Flatpak desde '$FLATPAK_PKGS_FILE'..."
    if ! command -v flatpak &> /dev/null; then
        warning "'flatpak' no está instalado. Omitiendo."
        return
    fi

    local packages_to_install=($(read_packages_from_file "$FLATPAK_PKGS_FILE"))

    if [ ${#packages_to_install[@]} -eq 0 ]; then
        log "No hay paquetes de Flatpak para instalar. Omitiendo."
        return
    fi

    log "Paquetes a instalar: ${packages_to_install[*]}"
    BLA::start_loading_animation "BLA_braille_whitespace"
    flatpak install flathub --noninteractive --assumeyes "${packages_to_install[@]}"
    BLA::stop_loading_animation
    log "Instalación de paquetes de Flatpak completada."
}

install_grub_theme() {
    log "Configuración del tema de GRUB"
    local GRUB_SCRIPT_PATH="$SCRIPT_DIR/scripts/install-grub-theme.sh"

    if ! command -v grub-mkconfig &> /dev/null; then
        warning "'grub-mkconfig' no fue encontrado. Omitiendo la instalación del tema de GRUB."
        return
    fi
    
    if [ ! -f "$GRUB_SCRIPT_PATH" ]; then
        error "No se encontró el script '$GRUB_SCRIPT_PATH'."
    fi
    
    chmod +x "$GRUB_SCRIPT_PATH"
    # El script install-grub-theme.sh es interactivo por sí mismo
    "$GRUB_SCRIPT_PATH"
}

install_sddm_theme() {
    log "Configuración del tema de SDDM"
    local SDDM_SCRIPT_PATH="$SCRIPT_DIR/scripts/install-sddm-theme.sh"

    if [ ! -f "$SDDM_SCRIPT_PATH" ]; then
        error "No se encontró el script '$SDDM_SCRIPT_PATH'."
    fi
    
    chmod +x "$SDDM_SCRIPT_PATH"
    # El script install-sddm-theme.sh es interactivo por sí mismo
    "$SDDM_SCRIPT_PATH"
}

copy_dotfiles() {
    log "Instalando dotfiles con enlaces simbólicos கிலோ"
    local SUDO_USER_NAME=${SUDO_USER:?SUDO_USER no está definido.}
    local HOME_DIR="/home/$SUDO_USER_NAME"
    # La carpeta 'config' del repositorio contiene las configuraciones a enlazar
    local SOURCE_CONFIG_DIR="$SCRIPT_DIR/config" 
    local TARGET_CONFIG_DIR="$HOME_DIR/.config"
    local BACKUP_DIR="$HOME_DIR/.config-backup-$(date +%Y%m%d-%H%M%S)"

    if [ ! -d "$SOURCE_CONFIG_DIR" ]; then
        warning "No se encontró el directorio de origen '$SOURCE_CONFIG_DIR'. Omitiendo."
        return
    fi

    log "Creando directorio de respaldo para configuraciones existentes en '$BACKUP_DIR'..."
    sudo -u "$SUDO_USER_NAME" mkdir -p "$BACKUP_DIR"
    sudo -u "$SUDO_USER_NAME" mkdir -p "$TARGET_CONFIG_DIR"

    # Iterar sobre los items en la carpeta 'config' del repo
    for item in "$SOURCE_CONFIG_DIR"/*; do
        local item_name=$(basename "$item")
        local source_path="$item"
        local dest_path="$TARGET_CONFIG_DIR/$item_name"

        log "Procesando '$item_name'..."

        # Si el archivo/directorio de destino ya existe en ~/.config, moverlo al backup
        if [ -e "$dest_path" ] || [ -L "$dest_path" ]; then
            log "  -> Configuración existente encontrada. Moviendo a la copia de seguridad."
            sudo -u "$SUDO_USER_NAME" mv "$dest_path" "$BACKUP_DIR/"
        fi

        log "  -> Creando enlace simbólico: $dest_path -> $source_path"
        # Usamos -T para tratar el destino como un archivo normal y no como un directorio
        sudo -u "$SUDO_USER_NAME" ln -s "$source_path" "$dest_path"
    done
    
    log "Gestión de dotfiles completada."
}

configure_services() {
    log "Habilitando servicios del sistema கிலோ"
    
    local services_to_enable=("sddm" "bluetooth" "NetworkManager")
    for service in "${services_to_enable[@]}"; do
        log "  -> Habilitando '$service'..."
        systemctl enable "$service"
    done

    log "Servicios habilitados."
}

# --- Verificaciones Iniciales ---
run_pre_checks() {
    log "Iniciando verificaciones del sistema..."
    if [[ "$EUID" -ne 0 ]]; then
      error "Este script necesita privilegios de root. Por favor, ejecútalo con 'sudo'."
    fi

    if ! ping -c 1 -W 1 8.8.8.8 &> /dev/null; then
        error "No se detectó conexión a internet. Conéctate a una red para continuar."
    fi
    log "Verificaciones completadas."
}

# --- Lógica Principal de Ejecución ---
main() {
    run_pre_checks

    if [[ "$1" == "--noconfirm" ]]; then
        NON_INTERACTIVE=true
        log "Ejecutando en modo no interactivo."
    fi

    log "Bienvenido al instalador de Project Achiko."

    if confirm_action "Paso 1: ¿Actualizar el sistema?"; then
        update_system
    fi

    if confirm_action "Paso 2: ¿Instalar paquetes de Pacman?"; then
        install_pacman_packages
    fi

    if confirm_action "Paso 3: ¿Instalar un asistente de AUR (paru/yay)?"; then
        install_aur_helper
    fi

    if confirm_action "Paso 4: ¿Instalar paquetes desde AUR?"; then
        install_aur_packages
    fi

    if confirm_action "Paso 5: ¿Instalar aplicaciones de Flatpak?"; then
        install_flatpak_packages
    fi
    
    if confirm_action "Paso 6: ¿Instalar las configuraciones (dotfiles) de la carpeta 'config'?"; then
        copy_dotfiles
    fi

    if confirm_action "Paso 7: ¿Configurar tema de GRUB?"; then
        install_grub_theme
    fi

    if confirm_action "Paso 8: ¿Configurar tema de SDDM?"; then
        install_sddm_theme
    fi

    if confirm_action "Paso 9: ¿Habilitar servicios (SDDM, Bluetooth, NetworkManager)?"; then
        configure_services
    fi

    log "\e[1;32m¡Instalación de Project Achiko completada!\e[0m"
    echo -e "Se recomienda reiniciar el sistema para aplicar todos los cambios."
    echo -e "Ejecuta: \e[1;33mreboot\e[0m"
}

# Ejecutar la función principal
main "$@"
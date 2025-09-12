#!/bin/bash

# ===================================================================
# Script de Instalación para Project Achiko
#
# Automatiza la instalación y configuración del entorno Hyprland
# basado en la guía del proyecto.
# ===================================================================

# Detener la ejecución si un comando falla
set -e

# --- Variables Globales ---
AUR_HELPER=""
# ----------------------------------------------------------------------------
# --- Lógica de Animaciones de Carga (Integrada) ---
# Las funciones y definiciones de animación están incluidas directamente en este script.

# Definiciones de las animaciones
# El primer valor es el intervalo en segundos entre cada fotograma.
BLA_filling_bar=( 0.25 '█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '███▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '█████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '██████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '███████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '█████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '██████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '███████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '█████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '██████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '███████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '█████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '██████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '███████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒' '████████████████████▒▒▒▒▒▒▒▒▒▒▒▒' '█████████████████████▒▒▒▒▒▒▒▒▒▒▒' '██████████████████████▒▒▒▒▒▒▒▒▒▒' '███████████████████████▒▒▒▒▒▒▒▒▒' '████████████████████████▒▒▒▒▒▒▒▒' '█████████████████████████▒▒▒▒▒▒▒' '██████████████████████████▒▒▒▒▒▒' '███████████████████████████▒▒▒▒▒' '████████████████████████████▒▒▒▒' '█████████████████████████████▒▒▒' '██████████████████████████████▒▒' '███████████████████████████████▒' '████████████████████████████████')
BLA_quarter=( 0.25 ▖ ▘ ▝ ▗ )
BLA_semi_circle=( 0.1 ◐ ◓ ◑ ◒ )
BLA_braille=( 0.2 ⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈ )
BLA_braille_whitespace=( 0.2 ⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷ )
BLA_modern_metro=( 0.1 '▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▱▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▱▱▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▱▱▱▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▱▱▱▱▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱' '▱▱▱▱▱▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱' '▱▱▱▱▱▱▰▰▰▱▱▱▱▱▱▱▱▱▱▱' '▱▱▱▱▱▱▱▰▰▰▱▱▱▱▱▱▱▱▱▱' '▱▱▱▱▱▱▱▱▰▰▰▱▱▱▱▱▱▱▱▱' '▱▱▱▱▱▱▱▱▱▰▰▰▱▱▱▱▱▱▱▱' '▱▱▱▱▱▱▱▱▱▱▰▰▰▱▱▱▱▱▱▱' '▱▱▱▱▱▱▱▱▱▱▱▰▰▰▱▱▱▱▱▱' '▱▱▱▱▱▱▱▱▱▱▱▱▰▰▰▱▱▱▱▱' '▱▱▱▱▱▱▱▱▱▱▱▱▱▰▰▰▱▱▱▱' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▰▰▰▱▱▱' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▰▰▰▱▱' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▰▰▰▱' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▰▰▰' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▰▰' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▰' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' )
BLA_circle_quadrants=( 0.15 '◜' '◝' '◞' '◟' )
BLA_arc=( 0.15 '◜' '◠' '◝' '◞' '◡' '◟' )
BLA_vertical_blocks=( 0.1 ' ' '▂' '▃' '▄' '▅' '▆' '▇' '█' '▇' '▆' '▅' '▄' '▃' ' ' )
BLA_horizontal_blocks=( 0.1 '▏' '▎' '▍' '▌' '▋' '▊' '▉' '▊' '▋' '▌' '▍' '▎' )

declare -a BLA_active_loading_animation

BLA::play_loading_animation_loop() {
  while true ; do
    for frame in "${BLA_active_loading_animation[@]}" ; do
      printf "\r%s" "${frame}"
      sleep "${BLA_loading_animation_frame_interval}"
    done
  done
}
BLA::start_loading_animation() {
  BLA_active_loading_animation=( "${@}" )
  BLA_loading_animation_frame_interval="${BLA_active_loading_animation[0]}"
  unset "BLA_active_loading_animation[0]"
  tput civis # Hide the terminal cursor
  BLA::play_loading_animation_loop &
  BLA_loading_animation_pid="${!}"
}
BLA::stop_loading_animation() {
  # Verificar si el PID existe antes de intentar matarlo
  if [ -n "$BLA_loading_animation_pid" ] && ps -p "$BLA_loading_animation_pid" > /dev/null; then
      kill "${BLA_loading_animation_pid}" &> /dev/null
  fi
  printf "\n"
  tput cnorm # Restore the terminal cursor
}
# Asegurarse de que la animación se detenga si el script es interrumpido
trap 'BLA::stop_loading_animation; exit 1' SIGINT
# -------------------------------------------------------------------------------

# --- Funciones de Utilidad ---
log() { # Imprime un mensaje de log con formato
    echo -e "\n\e[1;34m=> $1\e[0m"
}

error() { # Imprime un mensaje de error y sale del script
    echo -e "\n\e[1;31mERROR: $1\e[0m" >&2
    exit 1
}

confirm_action() { # Si estamos en modo no interactivo, siempre retorna éxito (sí)
    [[ "$NON_INTERACTIVE" == "true" ]] && return 0
    # Cambiado para que Enter signifique 'sí'
    read -p "$1 [Y/n]: " -r
    [[ -z "$REPLY" || ! "$REPLY" =~ ^[Nn]$ ]]
}

# --- Fases de Instalación ---

update_system() {
    log "Actualizando el sistema con Pacman... (esto puede tardar unos minutos)"
    pacman -Syyuu --noconfirm
}

install_pacman_packages() {
    log "Instalando paquetes esenciales desde los repositorios oficiales..."
    local packages=(
    hyprland sddm ark kate dolphin okular gwenview libreoffice-still libreoffice-still-es git curl python 
    npm chromium vivaldi nautilus gvfs-mtp vlc fastfetch flatpak bluez bluez-utils qt6-multimedia 
    qt6-virtualkeyboard qt6-svg baobab base base-devel btrfs-progs decibels epiphany evince fish
	gdm git github-cli gnome-backgrounds gnome-calculator gnome-calendar gnome-characters gnome-clocks
	gnome-color-manager gnome-connections gnome-console gnome-contacts gnome-control-center 
	gnome-disk-utility gnome-font-viewer gnome-keyring gnome-logs gnome-maps gnome-menus gnome-music 
	gnome-remote-desktop gnome-session gnome-settings-daemon gnome-shell gnome-software gnome-system-monitor
	gnome-text-editor gnome-tour gnome-tweaks gnome-user-docs gnome-user-share gnome-weather grilo-plugins 
	grub gst-plugin-pipewire gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs
	gvfs-onedrive gvfs-smb gvfs-wsdd htop intel-media-driver intel-ucode iwd libpulse libva-intel-driver
	linux linux-firmware loupe malcontent nano nautilus neovim network-manager-applet networkmanager orca
	pipewire pipewire-alsa pipewire-jack pipewire-pulse rygel simple-scan smartmontools snapshot sushi tecla
	totem vulkan-intel vulkan-nouveau vulkan-radeon wget wireless_tools wireplumber xdg-desktop-portal-gnome
	xdg-user-dirs-gtk xdg-utils xf86-video-amdgpu xf86-video-ati xf86-video-nouveau xorg-server xorg-xinit
	yelp zram-generator
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
    # La variable global AUR_HELPER es establecida por esta función
    local SUDO_USER_NAME=${SUDO_USER:?SUDO_USER no está definido. Ejecuta con sudo.}
 
    # 1. Detectar si ya hay un asistente instalado
    if pacman -Q paru &> /dev/null; then
        log "Asistente de AUR 'paru' ya está instalado."
        AUR_HELPER="paru"
        return
    elif pacman -Q yay &> /dev/null; then
        log "Asistente de AUR 'yay' ya está instalado."
        AUR_HELPER="yay"
        return
    fi
 
    # 2. Si no hay asistente, preguntar al usuario
    log "No se encontró un asistente de AUR. Por favor, elige uno para instalar."
    
    local choice=""
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        log "Modo no interactivo detectado. Instalando 'paru' por defecto."
        choice="paru"
    else
        PS3=$'\n\e[1;33m¿Qué asistente de AUR deseas instalar? (introduce el número): \e[0m'
        options=("paru (popular, escrito en Rust)" "yay (popular, escrito en Go)" "Omitir")
        select opt in "${options[@]}"; do
            case $REPLY in
                1) choice="paru"; break ;;
                2) choice="yay"; break ;;
                3) log "Se omitió la instalación del asistente de AUR."; return ;;
                *) echo -e "\e[31mOpción inválida. Inténtalo de nuevo.\e[0m";;
            esac
        done
    fi
 
    # 3. Instalar el asistente seleccionado
    if [[ "$choice" == "paru" ]]; then
        log "Instalando 'paru' desde AUR..."

        # Dependencias para construir paru (rustup es necesario)
        log "Instalando dependencias de compilación (rust)..."
        # Manejar el posible conflicto entre 'rust' y 'rustup'
        if pacman -Qq rust &> /dev/null; then
            log "  -> Paquete 'rust' en conflicto detectado. Eliminándolo para instalar 'rustup'."
            pacman -Rns --noconfirm rust
        fi
        pacman -S --needed --noconfirm git base-devel rustup
             
        local PARU_DIR="/tmp/paru-build"
        rm -rf "$PARU_DIR"

        log "Clonando el repositorio de 'paru'..."
        sudo -u "$SUDO_USER_NAME" git clone https://aur.archlinux.org/paru.git --depth=1 "$PARU_DIR"

        log "Compilando e instalando 'paru' (puede solicitar contraseña sudo)..."
        # Se usa --overwrite '*' para forzar la instalación y evitar errores de archivos en conflicto.
        (
            cd "$PARU_DIR" && \
            sudo -u "$SUDO_USER_NAME" rustup override set stable && \
            sudo -u "$SUDO_USER_NAME" rustup update stable && \
            sudo -u "$SUDO_USER_NAME" makepkg -si --noconfirm && \
            sudo pacman -U --noconfirm --overwrite '*' paru-*.pkg.tar.zst
        )
        rm -rf "$PARU_DIR"
        
        AUR_HELPER="paru"
        log "'paru' instalado correctamente."
    elif [[ "$choice" == "yay" ]]; then
        log "Instalando 'yay' desde AUR..."
 
        # Dependencias para construir yay (go es necesario)
        log "Instalando dependencias de compilación (go)..."
        pacman -S --needed --noconfirm git base-devel go
        
        nuke_yay_traces
 
        local YAY_DIR="/tmp/yay-build"
        rm -rf "$YAY_DIR"
 
        log "Clonando el repositorio de 'yay'..."
        sudo -u "$SUDO_USER_NAME" git clone https://aur.archlinux.org/yay.git --depth=1 "$YAY_DIR"

        log "Compilando e instalando 'yay' (puede solicitar contraseña sudo)..."
        # Se usa --overwrite '*' para forzar la instalación y evitar errores de archivos en conflicto.
        (
            cd "$YAY_DIR" && \
            sudo -u "$SUDO_USER_NAME" makepkg -si --noconfirm && \
            sudo pacman -U --noconfirm --overwrite '*' yay-*.pkg.tar.zst
        )
        rm -rf "$YAY_DIR"
        
        AUR_HELPER="yay"
        log "'yay' instalado correctamente."
    fi
}

install_aur_packages() {
    # La variable global AUR_HELPER es establecida por install_aur_helper
    if [ -z "$AUR_HELPER" ]; then
        log "No hay un asistente de AUR configurado. Omitiendo la instalación de paquetes de AUR."
        return
    fi

    local SUDO_USER_NAME=${SUDO_USER:?SUDO_USER no está definido.}

    log "Instalando paquetes desde AUR con '$AUR_HELPER'..."
    local packages=(
        visual-studio-code-bin github-desktop speedtest-go
        viu # Visor de imágenes para la terminal, para previsualizaciones
    )

    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! sudo -u "$SUDO_USER_NAME" "$AUR_HELPER" -Q "$pkg" &> /dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -eq 0 ]; then
        log "Todos los paquetes de AUR ya están instalados. Omitiendo."
        return
    fi
    # El asistente de AUR no debe ejecutarse como root.
    log "Instalando: ${to_install[*]} (puede solicitar contraseña o revisión del PKGBUILD)"
    # El flag --needed evita reinstalaciones innecesarias.
    sudo -u "$SUDO_USER_NAME" "$AUR_HELPER" -S --noconfirm --needed "${to_install[@]}"
    log "Instalación de paquetes de AUR completada."
}

install_flatpak_packages() {
    log "Instalando aplicaciones desde Flatpak..."
    local packages=(
        io.github.brunofin.Cohesion
        app.fotema.Fotema
        com.github.neithern.g4music
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

    log "Intentando instalar las siguientes aplicaciones de Flatpak: ${to_install[*]}"
    
    for pkg in "${to_install[@]}"; do
        log "  -> Instalando '$pkg'..."
        # Se intenta instalar cada paquete individualmente.
        # Si un paquete falla (p. ej., no se encuentra), muestra una advertencia y continúa con el siguiente.
        if ! flatpak install flathub --noninteractive --assumeyes "$pkg"; then
            log "\e[1;33mADVERTENCIA: No se pudo instalar la aplicación Flatpak '$pkg'. Es posible que ya no esté disponible en Flathub.\e[0m"
        fi
    done
    log "Instalación de paquetes de Flatpak completada."
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

install_sddm_theme() {
    log "Configuración del tema de SDDM"

    local SDDM_SCRIPT_PATH="scripts/install-sddm-theme.sh"

    if [ ! -f "$SDDM_SCRIPT_PATH" ]; then
        error "No se encontró el script '$SDDM_SCRIPT_PATH'."
    fi
    
    chmod +x "$SDDM_SCRIPT_PATH"

    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        log "Modo no interactivo: Instalando tema de SDDM predeterminado..."
        # Llama al script del tema con el flag noconfirm.
        # El script seleccionará el primer tema que encuentre.
        ./"$SDDM_SCRIPT_PATH" install "" --noconfirm
        return
    fi

    # La confirmación ya se hizo en la función main.
    # Se procede directamente a la instalación llamando al sub-script.
    ./"$SDDM_SCRIPT_PATH" install
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

# --- Verificaciones Iniciales ---
log "Iniciando verificaciones del sistema..."

# 1. Asegurarse de que el script se ejecute como root
if [[ "$EUID" -ne 0 ]]; then
  error "Este script necesita privilegios de root. Por favor, ejecútalo con 'sudo'."
fi

# 2. Verificar conexión a internet
if ! ping -c 1 -W 1 8.8.8.8 &> /dev/null; then
    error "No se detectó conexión a internet. Por favor, conéctate a una red para continuar."
fi

log "Verificaciones completadas. Iniciando instalación..."

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

    # --- Instalación de AUR ---
    # Primero, verificar si ya existe un asistente de AUR.
    if ! pacman -Q paru &> /dev/null && ! pacman -Q yay &> /dev/null; then
        # Si no existe, preguntar si se desea instalar uno.
        if confirm_action "Paso 3: No se encontró un asistente de AUR. ¿Deseas instalar uno (paru/yay)?"; then
            install_aur_helper
        fi
    else
        # Si ya existe, simplemente se llama a la función para que detecte cuál es y lo registre.
        install_aur_helper
    fi

    # Segundo, preguntar por separado si se desean instalar los paquetes de AUR.
    if confirm_action "Paso 4: ¿Instalar paquetes desde AUR?"; then
        install_aur_packages
    fi

    if confirm_action "Paso 5: ¿Instalar aplicaciones de Flatpak?"; then
        install_flatpak_packages
    fi
    if confirm_action "Paso 6: ¿Instalar la configuración de Project Achiko (dotfiles)?"; then
        copy_dotfiles
    fi

    if confirm_action "Paso 7: ¿Configurar un tema para el gestor de inicio de sesión (SDDM)?"; then
        install_sddm_theme
    fi

    install_grub_theme # Esta función ya es interactiva y tiene su propia lógica
    configure_services # Esto no necesita confirmación, es una acción final

    log "\e[1;32m¡Instalación de Project Achiko completada!\e[0m"
    echo -e "Se recomienda reiniciar el sistema para aplicar todos los cambios."
    echo -e "Ejecuta: \e[1;33mreboot\e[0m"
}

# Ejecutar la función principal
main "$@"

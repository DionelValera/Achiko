#!/bin/bash

# Script para instalar y configurar el tema Catppuccin para GRUB
# Repositorio del tema: https://github.com/catppuccin/grub

# Detener la ejecución si un comando falla
set -e

# --- Constantes y Variables ---
readonly REPO_URL="https://github.com/catppuccin/grub.git"
readonly TMP_DIR="/tmp/catppuccin-grub-theme"
readonly THEMES_DIR="/boot/grub/themes"
readonly LOCAL_THEMES_PATH="../themes/grub" # Ruta a los temas locales
readonly GRUB_CONFIG_FILE="/etc/default/grub"
THEME_NAME=""

# --- Funciones de Utilidad ---

# Imprime un mensaje de log con formato
log() {
    echo -e "\n\e[1;34m=> $1\e[0m"
}

# Imprime un mensaje de error y sale del script
error() {
    echo -e "\n\e[1;31mERROR: $1\e[0m" >&2
    exit 1
}

# Limpia los archivos temporales
cleanup() {
    if [ -d "$TMP_DIR" ]; then
        log "Limpiando archivos temporales..."
        rm -rf "$TMP_DIR"
    fi
}

configure_grub() {
    local theme_name="$1"
    log "Configurando GRUB en '$GRUB_CONFIG_FILE'..."
    local theme_path="$THEMES_DIR/$theme_name/theme.txt"
    local grub_resolution="1920x1080"

    if [ ! -f "$theme_path" ]; then
        error "No se encontró el archivo 'theme.txt' para el tema '$theme_name' en '$theme_path'."
    fi

    # Solo crear backup si no existe uno
    [ ! -f "$GRUB_CONFIG_FILE.bak" ] && cp "$GRUB_CONFIG_FILE" "$GRUB_CONFIG_FILE.bak" && log "Copia de seguridad de la configuración creada en '$GRUB_CONFIG_FILE.bak'"

    sed -i -E "s|^#*(GRUB_THEME=).*|\1\"$theme_path\"|" "$GRUB_CONFIG_FILE"
    sed -i -E "s|^#*(GRUB_GFXMODE=).*|\1$grub_resolution|" "$GRUB_CONFIG_FILE"

    log "Generando el nuevo archivo de configuración de GRUB..."
    grub-mkconfig -o /boot/grub/grub.cfg

    log "\e[1;32m¡Instalación completada con éxito!\e[0m"
    echo -e "El tema '$theme_name' ha sido instalado y configurado."
    echo -e "Reinicia tu sistema para ver los cambios en el menú de GRUB."
}

install_local_theme() {
    local theme_name="$1"
    log "Instalando el tema local '$theme_name'..."

    local source_dir="$LOCAL_THEMES_PATH/$theme_name"
    if [ ! -d "$source_dir" ]; then
        error "No se encontró el directorio del tema local: $source_dir"
    fi

    mkdir -p "$THEMES_DIR"
    rm -rf "$THEMES_DIR/$theme_name"
    cp -a "$source_dir" "$THEMES_DIR/"

    configure_grub "$theme_name"
}

install_catppuccin_theme() {
    log "Iniciando la instalación del tema Catppuccin desde Internet."

    log "Clonando el repositorio del tema..."
    git clone "$REPO_URL" "$TMP_DIR" --depth 1

    PS3=$'\n\e[1;33mPor favor, elige un sabor de Catppuccin (introduce el número): \e[0m'
    options=("latte" "frappe" "macchiato" "mocha" "Cancelar")
    local selected_flavor_name=""
    select opt in "${options[@]}"; do
        case $opt in
            "latte"|"frappe"|"macchiato"|"mocha")
                selected_flavor_name="catppuccin-$opt-grub-theme"
                log "Has seleccionado el sabor: $selected_flavor_name"
                break
                ;;
            "Cancelar")
                log "Instalación cancelada por el usuario."
                return
                ;;
            *) echo -e "\e[31mOpción inválida. Inténtalo de nuevo.\e[0m";;
        esac
    done

    if [ -z "$selected_flavor_name" ]; then
        return # El usuario canceló
    fi

    log "Instalando el tema en '$THEMES_DIR'..."
    mkdir -p "$THEMES_DIR"
    rm -rf "$THEMES_DIR/catppuccin-"*
    cp -a "$TMP_DIR/src/$selected_flavor_name" "$THEMES_DIR/"

    configure_grub "$selected_flavor_name"
}

install_theme() {
    log "Selección de tema de GRUB para instalar."

    local options=()
    # Buscar temas locales
    if [ -d "$LOCAL_THEMES_PATH" ] && [ -n "$(ls -A "$LOCAL_THEMES_PATH")" ]; then
        log "Detectando temas locales..."
        for theme_dir in "$LOCAL_THEMES_PATH"/*; do
            # Solo añadir a las opciones si es un directorio y contiene theme.txt
            if [ -d "$theme_dir" ] && [ -f "$theme_dir/theme.txt" ]; then
                options+=("$(basename "$theme_dir") (Local)")
            fi
        done
    fi

    options+=("Instalar tema Catppuccin (Desde Internet)")
    options+=("Cancelar")

    PS3=$'\n\e[1;33m¿Qué tema de GRUB deseas instalar? (introduce el número): \e[0m'
    select opt in "${options[@]}"; do
        case "$opt" in
            "")
                echo -e "\e[31mOpción inválida. Inténtalo de nuevo.\e[0m"
                ;;
            "Cancelar")
                log "Instalación cancelada por el usuario."
                exit 0
                ;;
            "Instalar tema Catppuccin (Desde Internet)")
                install_catppuccin_theme
                break
                ;;
            *) # Tema local
                local theme_name
                theme_name=$(echo "$opt" | sed 's/ (Local)$//')
                install_local_theme "$theme_name"
                break
                ;;
        esac
    done
}

uninstall_theme() {
    log "Iniciando la desinstalación del tema de GRUB..."

    # 1. Restaurar la configuración de GRUB
    if [ -f "$GRUB_CONFIG_FILE.bak" ]; then
        log "Restaurando la configuración de GRUB desde la copia de seguridad..."
        mv "$GRUB_CONFIG_FILE.bak" "$GRUB_CONFIG_FILE"
    else
        log "\e[1;33mADVERTENCIA: No se encontró copia de seguridad. Revirtiendo a valores por defecto...\e[0m"
        # Comenta la línea del tema y establece una resolución genérica
        sed -i -E 's/^(GRUB_THEME=)/#\1/' "$GRUB_CONFIG_FILE"
        sed -i -E 's/^(GRUB_GFXMODE=).*/\1auto/' "$GRUB_CONFIG_FILE"
    fi

    # 2. Eliminar los directorios del tema
    log "Eliminando los archivos de temas instalados por este script..."
    # Eliminar temas de Catppuccin
    rm -rf "$THEMES_DIR/catppuccin-"*
    # Eliminar temas locales que se hayan instalado
    if [ -d "$LOCAL_THEMES_PATH" ]; then
        for theme_dir in "$LOCAL_THEMES_PATH"/*; do
            if [ -d "$theme_dir" ]; then
                local theme_name_to_remove=$(basename "$theme_dir")
                if [ -d "$THEMES_DIR/$theme_name_to_remove" ]; then
                    log "Eliminando tema local instalado: $theme_name_to_remove"
                    rm -rf "$THEMES_DIR/$theme_name_to_remove"
                fi
            fi
        done
    fi

    # 3. Regenerar la configuración de GRUB
    log "Generando el nuevo archivo de configuración de GRUB..."
    grub-mkconfig -o /boot/grub/grub.cfg

    log "\e[1;32m¡Desinstalación completada con éxito!\e[0m"
    echo "Los temas han sido eliminados y la configuración de GRUB restaurada."
}

# --- Verificaciones Iniciales ---

# Asegurarse de que el script se ejecute como root
if [[ "$EUID" -ne 0 ]]; then
  error "Este script necesita privilegios de root. Por favor, ejecútalo con 'sudo'."
fi

# Verificar si 'git' está instalado
if ! command -v git &> /dev/null; then
    error "'git' no está instalado. Por favor, instálalo para continuar (ej: sudo pacman -S git)."
fi

# Registrar la función de limpieza para que se ejecute al salir
trap cleanup EXIT

# --- Lógica de Ejecución ---

case "$1" in
    install)
        install_theme
        ;;
    uninstall)
        uninstall_theme
        ;;
    *)
        echo "Uso: $0 [install|uninstall]"
        echo "  install    - Instala el tema Catppuccin para GRUB."
        echo "  uninstall  - Desinstala el tema y restaura la configuración de GRUB."
        exit 1
        ;;
esac

exit 0
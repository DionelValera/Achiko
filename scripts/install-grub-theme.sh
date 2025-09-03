#!/bin/bash

# Script para instalar y configurar el tema Catppuccin para GRUB
# Repositorio del tema: https://github.com/catppuccin/grub

# Detener la ejecución si un comando falla
set -e

# --- Constantes y Variables ---
readonly REPO_URL="https://github.com/catppuccin/grub.git"
readonly TMP_DIR="/tmp/catppuccin-grub-theme"
readonly THEMES_DIR="/boot/grub/themes"
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

install_theme() {
    log "Iniciando la instalación del tema Catppuccin para GRUB."

    # 1. Clonar el repositorio del tema en un directorio temporal
    log "Clonando el repositorio del tema..."
    git clone "$REPO_URL" "$TMP_DIR" --depth 1

    # 2. Permitir al usuario elegir un sabor del tema
    PS3=$'\n\e[1;33mPor favor, elige un sabor de Catppuccin (introduce el número): \e[0m'
    options=("latte" "frappe" "macchiato" "mocha" "Cancelar")
    select opt in "${options[@]}"; do
        case $opt in
            "latte"|"frappe"|"macchiato"|"mocha")
                THEME_NAME="catppuccin-$opt"
                log "Has seleccionado el sabor: $THEME_NAME"
                break
                ;;
            "Cancelar")
                log "Instalación cancelada por el usuario."
                exit 0
                ;;
            *) echo -e "\e[31mOpción inválida. Inténtalo de nuevo.\e[0m";;
        esac
    done

    # 3. Instalar el tema en el directorio de GRUB
    log "Instalando el tema en '$THEMES_DIR'..."
    mkdir -p "$THEMES_DIR"
    # Eliminar cualquier versión anterior del tema para una instalación limpia
    rm -rf "$THEMES_DIR/catppuccin-"*
    cp -r "$TMP_DIR/src/$THEME_NAME" "$THEMES_DIR/"

    # 4. Configurar el archivo de GRUB
    log "Configurando GRUB en '$GRUB_CONFIG_FILE'..."
    THEME_PATH="$THEMES_DIR/$THEME_NAME/theme.txt"
    GRUB_RESOLUTION="1920x1080" # Resolución recomendada para el tema

    # Solo crear backup si no existe uno
    [ ! -f "$GRUB_CONFIG_FILE.bak" ] && cp "$GRUB_CONFIG_FILE" "$GRUB_CONFIG_FILE.bak" && log "Copia de seguridad de la configuración creada en '$GRUB_CONFIG_FILE.bak'"

    sed -i -E "s/^#*(GRUB_THEME=).*/\1\"$THEME_PATH\"/" "$GRUB_CONFIG_FILE"
    sed -i -E "s/^#*(GRUB_GFXMODE=).*/\1$GRUB_RESOLUTION/" "$GRUB_CONFIG_FILE"

    # 5. Regenerar la configuración de GRUB
    log "Generando el nuevo archivo de configuración de GRUB..."
    grub-mkconfig -o /boot/grub/grub.cfg

    log "\e[1;32m¡Instalación completada con éxito!\e[0m"
    echo -e "El tema '$THEME_NAME' ha sido instalado y configurado."
    echo -e "Reinicia tu sistema para ver los cambios en el menú de GRUB."
}

uninstall_theme() {
    log "Iniciando la desinstalación del tema de GRUB..."

    # 1. Restaurar la configuración de GRUB
    if [ -f "$GRUB_CONFIG_FILE.bak" ]; then
        log "Restaurando la configuración de GRUB desde la copia de seguridad..."
        mv "$GRUB_CONFIG_FILE.bak" "$GRUB_CONFIG_FILE"
    else
        log "No se encontró copia de seguridad. Revirtiendo a valores por defecto..."
        # Comenta la línea del tema y establece una resolución genérica
        sed -i -E 's/^(GRUB_THEME=)/#\1/' "$GRUB_CONFIG_FILE"
        sed -i -E 's/^(GRUB_GFXMODE=).*/\1auto/' "$GRUB_CONFIG_FILE"
    fi

    # 2. Eliminar los directorios del tema
    log "Eliminando los archivos del tema de '$THEMES_DIR'..."
    rm -rf "$THEMES_DIR/catppuccin-"*

    # 3. Regenerar la configuración de GRUB
    log "Generando el nuevo archivo de configuración de GRUB..."
    grub-mkconfig -o /boot/grub/grub.cfg

    log "\e[1;32m¡Desinstalación completada con éxito!\e[0m"
    echo "El tema ha sido eliminado y la configuración de GRUB restaurada."
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
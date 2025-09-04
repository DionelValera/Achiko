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

# Detecta la resolución de la pantalla principal
detect_resolution() {
    local resolution
    if command -v hyprctl &> /dev/null && hyprctl monitors &> /dev/null; then
        # Para Hyprland, obtiene la resolución del primer monitor
        resolution=$(hyprctl monitors | grep -oP '^\s*\K[0-9]+x[0-9]+(?=@)' | head -n 1)
    elif command -v xrandr &> /dev/null; then
        # Para X11, obtiene la resolución marcada con '*'
        resolution=$(xrandr | grep '*' | awk '{print $1}' | head -n 1)
    fi

    if [ -z "$resolution" ]; then
        log "\e[1;33mADVERTENCIA: No se pudo detectar la resolución. Se usará 1920x1080 como valor por defecto.\e[0m"
        echo "1920x1080"
    else
        echo "$resolution"
    fi
}

# Permite al usuario seleccionar la resolución de GRUB
select_grub_resolution() {
    PS3=$'\n\e[1;33mPor favor, selecciona la resolución para GRUB (introduce el número): \e[0m'
    
    local detected_res
    detected_res=$(detect_resolution)

    options=(
        "Auto-detectar (Recomendado: $detected_res)"
        "1920x1080 (Full HD)"
        "2560x1080 (Ultrawide HD)"
        "2560x1440 (2K)"
        "3440x1440 (Ultrawide 2K)"
        "3840x2160 (4K)"
    )

    select opt in "${options[@]}"; do
        case $opt in
            "Auto-detectar (Recomendado: $detected_res)")
                echo "$detected_res"; break ;;
            "1920x1080 (Full HD)")
                echo "1920x1080"; break ;;
            "2560x1080 (Ultrawide HD)")
                echo "2560x1080"; break ;;
            "2560x1440 (2K)")
                echo "2560x1440"; break ;;
            "3440x1440 (Ultrawide 2K)")
                echo "3440x1440"; break ;;
            "3840x2160 (4K)")
                echo "3840x2160"; break ;;
            *) echo -e "\e[31mOpción inválida. Inténtalo de nuevo.\e[0m";;
        esac
    done
}

configure_grub() {
    local theme_name="$1"
    local non_interactive="$2"
    log "Configurando GRUB en '$GRUB_CONFIG_FILE'..."
    local theme_path="$THEMES_DIR/$theme_name/theme.txt"
    local grub_resolution

    if [ ! -f "$theme_path" ]; then
        error "No se encontró el archivo 'theme.txt' para el tema '$theme_name' en '$theme_path'."
    fi

    # Solo crear backup si no existe uno
    [ ! -f "$GRUB_CONFIG_FILE.bak" ] && cp "$GRUB_CONFIG_FILE" "$GRUB_CONFIG_FILE.bak" && log "Copia de seguridad de la configuración creada en '$GRUB_CONFIG_FILE.bak'"

    if [[ "$non_interactive" == "true" ]]; then
        grub_resolution=$(detect_resolution)
    else
        grub_resolution=$(select_grub_resolution)
    fi
    log "Estableciendo la resolución de GRUB a: $grub_resolution"

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
    local non_interactive="$2"
    log "Instalando el tema local '$theme_name'..."

    local source_dir="$LOCAL_THEMES_PATH/$theme_name"
    if [ ! -d "$source_dir" ]; then
        error "No se encontró el directorio del tema local: $source_dir"
    fi

    local dest_dir="$THEMES_DIR/$theme_name"
    rm -rf "$dest_dir"
    mkdir -p "$dest_dir"
    # Copiamos el contenido para ser más robustos y evitar problemas con symlinks.
    # --no-preserve=ownership evita los warnings de "Operación no permitida".
    cp -a --no-preserve=ownership "$source_dir"/* "$dest_dir/"

    configure_grub "$theme_name" "$non_interactive"
}

install_catppuccin_theme() {
    log "Iniciando la instalación del tema Catppuccin desde Internet."

    # Clonar solo si el directorio no existe
    if [ ! -d "$TMP_DIR" ]; then
        log "Clonando el repositorio del tema..."
        git clone "$REPO_URL" "$TMP_DIR" --depth 1
    fi

    PS3=$'\n\e[1;33mPor favor, elige un sabor de Catppuccin (introduce el número): \e[0m'
    options=("latte" "frappe" "macchiato" "mocha" "Cancelar")
    local selected_flavor_name=""
    select opt in "${options[@]}"; do
        case $opt in
            "latte"|"frappe"|"macchiato"|"mocha")
                selected_flavor_name="catppuccin-$opt-grub-theme"
                log "Has seleccionado el sabor: $opt"
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
    local dest_dir="$THEMES_DIR/$selected_flavor_name"
    rm -rf "$THEMES_DIR/catppuccin-"*
    mkdir -p "$dest_dir"
    # Copiamos el contenido para ser consistentes y robustos.
    cp -a --no-preserve=ownership "$TMP_DIR/src/$selected_flavor_name"/* "$dest_dir/"

    configure_grub "$selected_flavor_name" "false"
}

install_catppuccin_direct() {
    local flavor="$1" # e.g., "latte"
    local non_interactive="$2"
    local selected_flavor_name="catppuccin-$flavor-grub-theme"

    log "Instalando el tema Catppuccin ($flavor) desde Internet en modo no interactivo."

    # Check if repo is already cloned
    if [ ! -d "$TMP_DIR" ]; then
        log "Clonando el repositorio del tema..."
        git clone "$REPO_URL" "$TMP_DIR" --depth 1
    fi

    if [ ! -d "$TMP_DIR/src/$selected_flavor_name" ]; then
        error "El sabor '$flavor' no se encontró en el repositorio clonado."
    fi

    log "Instalando el tema en '$THEMES_DIR'..."
    local dest_dir="$THEMES_DIR/$selected_flavor_name"
    rm -rf "$THEMES_DIR/catppuccin-"*
    mkdir -p "$dest_dir"
    cp -a --no-preserve=ownership "$TMP_DIR/src/$selected_flavor_name"/* "$dest_dir/"

    configure_grub "$selected_flavor_name" "$non_interactive"
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
        # Si se proporciona un segundo argumento, asumimos que es un nombre de tema para una instalación directa.
        if [ -n "$2" ]; then
            local theme_name="$2"
            local non_interactive=false
            # El tercer argumento puede ser --noconfirm
            if [[ "$3" == "--noconfirm" ]]; then
                non_interactive=true
            fi

            if [[ "$theme_name" == "catppuccin-"* ]]; then
                local flavor=${theme_name#catppuccin-} # Extracts "latte" from "catppuccin-latte"
                install_catppuccin_direct "$flavor" "$non_interactive"
            elif [ -d "$LOCAL_THEMES_PATH/$theme_name" ]; then
                install_local_theme "$theme_name" "$non_interactive"
            else
                error "Tema '$theme_name' no encontrado localmente ni reconocido como tema Catppuccin."
            fi
        else # Si no, mostrar el menú interactivo.
            install_theme
        fi
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
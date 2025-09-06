#!/bin/bash

# Script para instalar y configurar temas para SDDM

set -e

# --- Constantes y Variables ---
readonly THEMES_DIR="/usr/share/sddm/themes"
readonly LOCAL_THEMES_PATH="../themes/sddm" # Ruta a los temas locales en el repo
readonly SDDM_CONFIG_DIR="/etc/sddm.conf.d"
readonly CONFIG_FILE="$SDDM_CONFIG_DIR/achiko-theme.conf"
readonly SILENT_SDDM_REPO_URL="https://github.com/uiriansan/SilentSDDM.git"
readonly SILENT_SDDM_TMP_DIR="/tmp/silent-sddm-theme"

# --- Funciones de Utilidad ---
log() {
    echo -e "\n\e[1;34m=> $1\e[0m"
}

error() {
    echo -e "\n\e[1;31mERROR: $1\e[0m" >&2
    exit 1
}

cleanup() {
    if [ -d "$SILENT_SDDM_TMP_DIR" ]; then
        log "Limpiando archivos temporales..."
        rm -rf "$SILENT_SDDM_TMP_DIR"
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

select_sddm_scaling_profile() {
    PS3=$'\n\e[1;33mPor favor, selecciona un perfil de escalado para SDDM (introduce el número): \e[0m'
    
    local detected_res
    detected_res=$(detect_resolution)

    # El DPI es el mecanismo de escalado para la UI de SDDM
    options=(
        "Estándar (96 DPI) - Para 1080p y similar"
        "Intermedio (144 DPI) - Para 1440p (2K) o escalado al 150%"
        "Alto (192 DPI) - Para 2160p (4K) o escalado al 200%"
        "Introducir DPI manualmente"
    )

    select opt in "${options[@]}"; do
        case $opt in
            "Estándar (96 DPI)"*)
                echo "96"; break ;;
            "Intermedio (144 DPI)"*)
                echo "144"; break ;;
            "Alto (192 DPI)"*)
                echo "192"; break ;;
            "Introducir DPI manualmente")
                read -p "Introduce el valor de DPI deseado (ej: 120): " custom_dpi
                echo "$custom_dpi"; break ;;
            *) echo -e "\e[31mOpción inválida. Inténtalo de nuevo.\e[0m";;
        esac
    done
}

configure_sddm_resolution() {
    local non_interactive="$1"
    local dpi=96 # DPI estándar por defecto

    if [[ "$non_interactive" == "--noconfirm" ]]; then
        log "Omitiendo configuración de resolución de SDDM en modo no interactivo."
        return
    fi

    read -p $'\n\e[1;33m¿Deseas configurar la resolución/escalado para SDDM (útil para pantallas HiDPI/4K)? [y/N]: \e[0m' -n 1 -r; echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Omitiendo configuración de resolución."
        return
    fi

    dpi=$(select_sddm_scaling_profile)
    log "Configurando SDDM con un DPI de $dpi..."
    # Añadimos la configuración al final del archivo.
    echo -e "\n[X11]\nServerArguments=-nolisten tcp -dpi $dpi" >> "$CONFIG_FILE"
}

apply_sddm_theme_config() {
    local theme_name="$1"
    local non_interactive="$2"

    log "Configurando SDDM para usar el nuevo tema..."
    mkdir -p "$SDDM_CONFIG_DIR"
    echo -e "[Theme]\nCurrent=$theme_name" > "$CONFIG_FILE"

    log "\e[1;32m¡Tema de SDDM '$theme_name' instalado con éxito!\e[0m"

    # Llamada a la nueva función para configurar la resolución
    configure_sddm_resolution "$non_interactive"
}

install_local_theme() {
    local theme_name="$1"
    local non_interactive="$2"

    local source_dir="$LOCAL_THEMES_PATH/$theme_name"
    local dest_dir="$THEMES_DIR/$theme_name"

    if [ ! -d "$source_dir" ]; then
        error "El directorio del tema '$source_dir' no existe."
    fi

    log "Instalando el tema local '$theme_name' en '$dest_dir'..."
    rm -rf "$dest_dir"
    mkdir -p "$(dirname "$dest_dir")"
    cp -a --no-preserve=ownership "$source_dir" "$dest_dir"

    apply_sddm_theme_config "$theme_name" "$non_interactive"
}

install_silent_sddm_theme() {
    local non_interactive="$1"
    log "Iniciando la instalación del tema Silent-SDDM desde Internet."

    if ! command -v git &> /dev/null; then
        error "'git' no está instalado. Por favor, instálalo para continuar (ej: sudo pacman -S git)."
    fi

    if [ ! -d "$SILENT_SDDM_TMP_DIR" ]; then
        log "Clonando el repositorio del tema..."
        git clone "$SILENT_SDDM_REPO_URL" "$SILENT_SDDM_TMP_DIR" --depth=1
    fi

    local theme_name="Silent-SDDM"
    log "Instalando el tema en '$THEMES_DIR'..."
    local dest_dir="$THEMES_DIR/$theme_name"
    rm -rf "$dest_dir"
    mkdir -p "$dest_dir"
    
    # Copiamos todo el contenido del directorio clonado al destino.
    # Esto es más robusto a cambios en el repositorio de origen.
    log "Copiando el contenido del tema..."
    cp -a --no-preserve=ownership "$SILENT_SDDM_TMP_DIR"/* "$dest_dir/"

    # El tema original no incluye un theme.conf, así que lo creamos.
    log "Creando el archivo de manifiesto 'theme.conf'..."
    cat > "$dest_dir/theme.conf" <<EOF
[General]
name=Silent-SDDM
author=uiriansan
version=1.0
description=A silent and minimal theme for SDDM.
preview=preview.gif
EOF

    apply_sddm_theme_config "$theme_name" "$non_interactive"
}

# --- Lógica de Instalación ---

install_theme() {
    local theme_to_install="$1"
    local non_interactive="$2"

    if [[ "$non_interactive" == "--noconfirm" ]]; then
        # Modo no interactivo: instalar el primer tema local encontrado
        if [ ! -d "$LOCAL_THEMES_PATH" ] || [ -z "$(ls -A "$LOCAL_THEMES_PATH")" ]; then
            log "\e[1;33mADVERTENCIA: No se encontraron temas locales. Omitiendo instalación de tema SDDM en modo no interactivo.\e[0m"
            return
        fi
        local theme_name
        theme_name=$(basename "$(find "$LOCAL_THEMES_PATH" -mindepth 1 -maxdepth 1 -type d | head -n 1)")
        log "Modo no interactivo: Instalando el primer tema local encontrado: '$theme_name'"
        install_local_theme "$theme_name" "$non_interactive"
        return
    fi

    # Modo interactivo
    log "Selección de tema de SDDM para instalar."

    local options=()
    # Buscar temas locales
    if [ -d "$LOCAL_THEMES_PATH" ] && [ -n "$(ls -A "$LOCAL_THEMES_PATH")" ]; then
        log "Detectando temas locales..."
        while IFS= read -r -d '' theme_dir; do
            options+=("$(basename "$theme_dir") (Local)")
        done < <(find "$LOCAL_THEMES_PATH" -mindepth 1 -maxdepth 1 -type d -print0)
    fi

    options+=("Instalar Silent-SDDM (Desde Internet)")
    options+=("Cancelar")

    PS3=$'\n\e[1;33m¿Qué tema de SDDM deseas instalar? (introduce el número): \e[0m'
    select opt in "${options[@]}"; do
        case "$opt" in
            "")
                echo -e "\e[31mOpción inválida. Inténtalo de nuevo.\e[0m"
                ;;
            "Cancelar")
                log "Instalación cancelada."
                return
                ;;
            "Instalar Silent-SDDM (Desde Internet)")
                install_silent_sddm_theme "false"
                break
                ;;
            *) # Tema local
                local theme_name
                theme_name=$(echo "$opt" | sed 's/ (Local)$//')
                
                # --- Lógica de Previsualización ---
                if command -v viu &> /dev/null; then
                    local preview_file="$LOCAL_THEMES_PATH/$theme_name/preview.png"
                    if [ -f "$preview_file" ]; then
                        echo -e "\n\e[1;33mMostrando previsualización para '$theme_name'. Presiona Ctrl+C para continuar con la instalación...\e[0m"
                        (trap 'exit 0' SIGINT; viu -b "$preview_file"; sleep 60) || true
                        clear # Limpia la pantalla después de la previsualización
                    fi
                fi
                
                install_local_theme "$theme_name" "false"
                break
                ;;
        esac
    done
}

uninstall_theme() {
    log "Iniciando la desinstalación de los temas de SDDM de Project Achiko..."

    # 1. Eliminar el archivo de configuración
    if [ -f "$CONFIG_FILE" ]; then
        log "Eliminando archivo de configuración: $CONFIG_FILE"
        rm -f "$CONFIG_FILE"
    else
        log "No se encontró el archivo de configuración '$CONFIG_FILE'. Omitiendo."
    fi

    # 2. Eliminar los directorios de temas que existen en local
    if [ -d "$LOCAL_THEMES_PATH" ]; then
        log "Buscando temas para eliminar..."
        while IFS= read -r -d '' theme_dir; do
            local theme_name=$(basename "$theme_dir")
            local installed_theme_path="$THEMES_DIR/$theme_name"
            if [ -d "$installed_theme_path" ]; then
                log "  -> Eliminando tema instalado: '$theme_name'"
                rm -rf "$installed_theme_path"
            fi
        done < <(find "$LOCAL_THEMES_PATH" -mindepth 1 -maxdepth 1 -type d -print0)
    fi

    # 3. Eliminar el tema de internet (Silent-SDDM)
    local silent_sddm_path="$THEMES_DIR/Silent-SDDM"
    if [ -d "$silent_sddm_path" ]; then
        log "  -> Eliminando tema de internet instalado: 'Silent-SDDM'"
        rm -rf "$silent_sddm_path"
    fi

    log "\e[1;32m¡Desinstalación de temas de SDDM completada!\e[0m"
    echo "SDDM usará su tema por defecto. Puede que necesites reiniciar para ver los cambios."
}

# --- Verificaciones Iniciales ---
if [[ "$EUID" -ne 0 ]]; then
  error "Este script necesita privilegios de root. Por favor, ejecútalo con 'sudo'."
fi

# Registrar la función de limpieza para que se ejecute al salir
trap cleanup EXIT

# --- Lógica de Ejecución ---
case "$1" in
    install)
        install_theme "$2" "$3" # $2=theme_name, $3=--noconfirm
        ;;
    uninstall)
        uninstall_theme
        ;;
    *)
        echo "Uso: $0 [install|uninstall]"
        echo "  install [theme_name] [--noconfirm] - Instala un tema para SDDM."
        echo "  uninstall                         - Desinstala los temas y la configuración."
        exit 1
        ;;
esac

exit 0
#!/bin/bash

# Script para instalar y configurar temas para SDDM

set -e

# --- Constantes y Variables ---
readonly THEMES_DIR="/usr/share/sddm/themes"
readonly LOCAL_THEMES_PATH="../themes/sddm" # Ruta a los temas locales en el repo
readonly SDDM_CONFIG_DIR="/etc/sddm.conf.d"
readonly CONFIG_FILE="$SDDM_CONFIG_DIR/achiko-theme.conf"

# --- Funciones de Utilidad ---
log() {
    echo -e "\n\e[1;34m=> $1\e[0m"
}

error() {
    echo -e "\n\e[1;31mERROR: $1\e[0m" >&2
    exit 1
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

# --- Lógica de Instalación ---

install_theme() {
    local theme_to_install="$1"
    local non_interactive="$2"

    if [ ! -d "$LOCAL_THEMES_PATH" ] || [ -z "$(ls -A "$LOCAL_THEMES_PATH")" ]; then
        log "\e[1;33mADVERTENCIA: No se encontró el directorio de temas locales '$LOCAL_THEMES_PATH' o está vacío. Omitiendo.\e[0m"
        return
    fi

    local selected_theme_name
    if [[ "$non_interactive" == "--noconfirm" ]]; then
        if [ -z "$theme_to_install" ]; then
            # Si es no interactivo y no se especifica un tema, usar el primero que encuentre
            selected_theme_name=$(basename "$(find "$LOCAL_THEMES_PATH" -mindepth 1 -maxdepth 1 -type d | head -n 1)")
            log "Modo no interactivo: Instalando el primer tema encontrado: '$selected_theme_name'"
        else
            selected_theme_name="$theme_to_install"
            log "Modo no interactivo: Instalando tema especificado: '$selected_theme_name'"
        fi
    else
        # Modo interactivo
        local options=()
        while IFS= read -r -d '' theme_dir; do
            options+=("$(basename "$theme_dir")")
        done < <(find "$LOCAL_THEMES_PATH" -mindepth 1 -maxdepth 1 -type d -print0)
        options+=("Cancelar")

        PS3=$'\n\e[1;33m¿Qué tema de SDDM deseas instalar? (introduce el número): \e[0m'
        select opt in "${options[@]}"; do
            if [[ "$opt" == "Cancelar" ]]; then
                log "Instalación cancelada."
                return
            elif [ -n "$opt" ]; then
                selected_theme_name="$opt"

                # --- INICIO: Lógica de Previsualización ---
                if command -v viu &> /dev/null; then
                    local preview_file="$LOCAL_THEMES_PATH/$selected_theme_name/preview.png"
                    if [ -f "$preview_file" ]; then
                        echo -e "\n\e[1;33mMostrando previsualización para '$selected_theme_name'. Presiona Ctrl+C para continuar con la instalación...\e[0m"
                        # Usamos un subshell y trap para que Ctrl+C solo salga de la previsualización
                        (trap 'exit 0' SIGINT; viu -b "$preview_file"; sleep 60) || true
                        clear # Limpia la pantalla después de la previsualización
                    fi
                fi
                # --- FIN: Lógica de Previsualización ---

                break
            else
                echo -e "\e[31mOpción inválida. Inténtalo de nuevo.\e[0m"
            fi
        done
    fi

    if [ -z "$selected_theme_name" ]; then
        error "No se seleccionó ningún tema."
    fi

    local source_dir="$LOCAL_THEMES_PATH/$selected_theme_name"
    local dest_dir="$THEMES_DIR/$selected_theme_name"

    if [ ! -d "$source_dir" ]; then
        error "El directorio del tema '$source_dir' no existe."
    fi

    log "Instalando el tema '$selected_theme_name' en '$dest_dir'..."
    rm -rf "$dest_dir"
    mkdir -p "$(dirname "$dest_dir")"
    cp -a --no-preserve=ownership "$source_dir" "$dest_dir"

    log "Configurando SDDM para usar el nuevo tema..."
    mkdir -p "$SDDM_CONFIG_DIR"
    echo -e "[Theme]\nCurrent=$selected_theme_name" > "$CONFIG_FILE"

    log "\e[1;32m¡Tema de SDDM '$selected_theme_name' instalado con éxito!\e[0m"

    # Llamada a la nueva función para configurar la resolución
    configure_sddm_resolution "$non_interactive"
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

    log "\e[1;32m¡Desinstalación de temas de SDDM completada!\e[0m"
    echo "SDDM usará su tema por defecto. Puede que necesites reiniciar para ver los cambios."
}

# --- Verificaciones Iniciales ---
if [[ "$EUID" -ne 0 ]]; then
  error "Este script necesita privilegios de root. Por favor, ejecútalo con 'sudo'."
fi

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
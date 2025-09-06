#!/bin/bash

# ===================================================================
# Script de Pruebas Unitarias para la función detect_resolution
# ===================================================================

set -e

# --- Entorno de Pruebas ---

# 1. Importar la función que queremos probar.
# La ruta es relativa a la ubicación de este script de prueba.
# Obtenemos la ruta absoluta del directorio donde se encuentra este script.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source "$SCRIPT_DIR/install-sddm-theme.sh"

# 2. Contadores para el resumen de pruebas
declare -i tests_run=0
declare -i tests_passed=0

# 3. Función de ayuda para ejecutar pruebas
# Imprime PASS o FAIL de forma colorida.
run_test() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    
    tests_run+=1
    
    echo -n "TEST: $description ... "
    if [[ "$actual" == "$expected" ]]; then
        echo -e "\e[32mPASS\e[0m"
        tests_passed+=1
    else
        echo -e "\e[31mFAIL\e[0m"
        echo "  - Esperado: '$expected'"
        echo "  - Obtenido: '$actual'"
    fi
}

# --- Pruebas ---

echo -e "\n\e[1;34m=> Iniciando pruebas para detect_resolution()\e[0m"

# --- Test 1: Simular entorno Hyprland ---
# Creamos una función "mock" (falsa) llamada hyprctl
hyprctl() {
    echo "Monitor eDP-1 (ID 0):
        1920x1080@60.000000 at 0x0
        description: Chimei Innolux Corporation 0x1521 (eDP-1)
        make: Chimei Innolux Corporation
        model: 0x1521
        serial: 
        active: yes
        disabled: no
        dpms: on
        scale: 1.00
        transform: 0"
}
export -f hyprctl # Exportamos la función para que sea visible por el script fuente

run_test "Debería detectar la resolución con hyprctl" "1920x1080" "$(detect_resolution)"

unset -f hyprctl # Limpiamos la función mock

# --- Test 2: Simular entorno X11 (xrandr) ---
xrandr() {
    echo "Screen 0: minimum 320 x 200, current 3840 x 2160, maximum 16384 x 16384
DP-1 connected primary 3840x2160+0+0 (normal left inverted right x axis y axis) 600mm x 340mm"
}
export -f xrandr

run_test "Debería detectar la resolución con xrandr" "3840x2160" "$(detect_resolution)"

unset -f xrandr

# --- Resumen Final ---
echo -e "\n\e[1;34m=> Resumen de Pruebas\e[0m"
echo "Total de pruebas ejecutadas: $tests_run"
echo "Pruebas superadas: $tests_passed"

if (( tests_passed == tests_run )); then
    echo -e "\e[1;32m¡Todas las pruebas pasaron con éxito!\e[0m"
    exit 0
else
    echo -e "\e[1;31mAlgunas pruebas fallaron.\e[0m"
    exit 1
fi
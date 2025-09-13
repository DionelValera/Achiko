#!/bin/bash
##gracias guapo, todo esta belloooooo
# =============================================================================
# Bash Loading Animations
#
# Proporciona funciones para mostrar animaciones de carga en scripts de bash.
# Para usarlo, haz 'source' de este script y luego llama a:
#   BLA::start_loading_animation "BLA_nombre_animacion"
#   ... comando_largo ...
#   BLA::stop_loading_animation
#
# Basado en el trabajo de Bash-Snippets/bash-snippets.
# =============================================================================

# --- Definiciones de Animaciones ---
# Formato: ( intervalo_en_segundos 'frame1' 'frame2' ... )
BLA_filling_bar=( 0.25 '█▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '███▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '█████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '██████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '███████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '█████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '██████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '███████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '█████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '██████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '███████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '█████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '██████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒' '███████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒' '████████████████████▒▒▒▒▒▒▒▒▒▒▒▒' '█████████████████████▒▒▒▒▒▒▒▒▒▒▒' '██████████████████████▒▒▒▒▒▒▒▒▒▒' '███████████████████████▒▒▒▒▒▒▒▒▒' '████████████████████████▒▒▒▒▒▒▒▒' '█████████████████████████▒▒▒▒▒▒▒' '██████████████████████████▒▒▒▒▒▒' '███████████████████████████▒▒▒▒▒' '████████████████████████████▒▒▒▒' '█████████████████████████████▒▒▒' '██████████████████████████████▒▒' '███████████████████████████████▒' '████████████████████████████████')
BLA_quarter=( 0.25 ▖ ▘ ▝ ▗ )
BLA_semi_circle=( 0.1 ◐ ◓ ◑ ◒ )
BLA_braille=( 0.2 ⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈ )
BLA_braille_whitespace=( 0.2 ⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷ )
BLA_modern_metro=( 0.1 '▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▱▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▱▱▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▱▱▱▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▱▱▱▱▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱' '▱▱▱▱▱▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱' '▱▱▱▱▱▱▰▰▰▱▱▱▱▱▱▱▱▱▱▱' '▱▱▱▱▱▱▱▰▰▰▱▱▱▱▱▱▱▱▱▱' '▱▱▱▱▱▱▱▱▰▰▰▱▱▱▱▱▱▱▱▱' '▱▱▱▱▱▱▱▱▱▰▰▰▱▱▱▱▱▱▱▱' '▱▱▱▱▱▱▱▱▱▱▰▰▰▱▱▱▱▱▱▱' '▱▱▱▱▱▱▱▱▱▱▱▰▰▰▱▱▱▱▱▱' '▱▱▱▱▱▱▱▱▱▱▱▱▰▰▰▱▱▱▱▱' '▱▱▱▱▱▱▱▱▱▱▱▱▱▰▰▰▱▱▱▱' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▰▰▰▱▱▱' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▰▰▰▱▱' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▰▰▰▱' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▰▰▰' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▰▰' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▰' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' '▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱' )
BLA_circle_quadrants=( 0.15 '◜' '◝' '◞' '◟' )
BLA_arc=( 0.15 '◜' '◠' '◝' '◞' '◡' '◟' )
BLA_vertical_blocks=( 0.1 ' ' '▂' '▃' '▄' '▅' '▆' '▇' '█' '▇' '▆' '▅' '▄' '▃' ' ' )
BLA_horizontal_blocks=( 0.1 '▏' '▎' '▍' '▌' '▋' '▊' '▉' '▊' '▋' '▌' '▍' '▎' )

# --- Lógica de la Animación ---

declare -a BLA_active_loading_animation
declare BLA_loading_animation_pid

# Loop principal que dibuja la animación
BLA::play_loading_animation_loop() {
  while true ; do
    for frame in "${BLA_active_loading_animation[@]}" ; do
      printf "\r%s" "${frame}"
      sleep "${BLA_loading_animation_frame_interval}"
    done
  done
}

# Inicia una animación en segundo plano
# Uso: BLA::start_loading_animation "BLA_nombre_animacion"
BLA::start_loading_animation() {
  local -n animation_array=$1 # Referencia indirecta al array de animación

  BLA_active_loading_animation=( "${animation_array[@]}" )
  BLA_loading_animation_frame_interval="${BLA_active_loading_animation[0]}"
  unset "BLA_active_loading_animation[0]"
  
  tput civis # Ocultar el cursor
  BLA::play_loading_animation_loop &
  BLA_loading_animation_pid="${!}"
}

# Detiene la animación en segundo plano
BLA::stop_loading_animation() {
  if [ -n "$BLA_loading_animation_pid" ] && ps -p "$BLA_loading_animation_pid" > /dev/null; then
      kill "${BLA_loading_animation_pid}" &> /dev/null
  fi
  printf "\r\033[K" # Limpiar la línea
  tput cnorm # Restaurar el cursor
}

# Asegurarse de que la animación se detenga si el script es interrumpido
trap 'BLA::stop_loading_animation; exit 1' SIGINT

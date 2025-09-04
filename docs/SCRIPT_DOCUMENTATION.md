# Documentación Técnica Exhaustiva del Script `install.sh`

Este documento proporciona un análisis exhaustivo y detallado del script `install.sh`, sirviendo como una referencia técnica completa. Se desglosa cada función, comando y decisión de diseño para ofrecer una comprensión total del flujo de trabajo y la lógica interna del instalador de Onix Hyprdots.

---

## 1. Filosofía y Objetivos de Diseño

El script `install.sh` no es solo una secuencia de comandos, sino una herramienta construida con los siguientes principios en mente:

-   **Robustez:** El script debe ser capaz de manejar errores comunes (paquetes no encontrados, conflictos de archivos, instalaciones previas) sin detenerse abruptamente.
-   **Idempotencia:** Ejecutar el script múltiples veces en el mismo sistema no debería causar problemas. El script verifica lo que ya está instalado y actúa en consecuencia.
-   **Interactividad Opcional:** Debe funcionar tanto en un modo guiado (haciendo preguntas al usuario) como en un modo completamente desatendido (`--noconfirm`) para automatización.
-   **Modularidad:** Las responsabilidades están claramente separadas en funciones concisas, facilitando el mantenimiento y la comprensión del código.
-   **Seguridad:** Se siguen las mejores prácticas de Arch Linux, como no ejecutar asistentes de AUR como root y crear copias de seguridad antes de modificar archivos de configuración críticos.

---

## 2. Guía de Ejecución

### Requisitos
- Una instalación base de **Arch Linux**.
- Un usuario con privilegios de **`sudo`**.
- Una **conexión a internet** activa.

### Pasos para la Ejecución

1.  **Clonar el Repositorio:**
    ```bash
    git clone https://github.com/DionelValera/Onix-hyprdots.git
    ```
2.  **Navegar al Directorio:**
    ```bash
    cd Onix-hyprdots
    ```
3.  **Otorgar Permisos de Ejecución:**
    ```bash
    chmod +x install.sh
    ```
    Este comando (`change mode`) modifica los permisos del archivo `install.sh`, añadiéndole (`+`) el permiso de ejecución (`x`). Esto es necesario para que el sistema operativo permita que el archivo sea tratado como un programa.

4.  **Ejecutar con `sudo`:**
    -   **Modo Interactivo (Recomendado):**
        ```bash
        sudo ./install.sh
        ``` 
        El script te guiará paso a paso, solicitando confirmación para cada acción importante.
    -   **Modo No Interactivo (Desatendido):**
        ```bash
        sudo ./install.sh --noconfirm
        ```
        Ideal para automatización. El script asumirá "Sí" a todas las preguntas y procederá sin intervención del usuario.

---

## 3. Anatomía del Script: Desglose Funcional

### 3.1. Funciones de Utilidad y Entorno

Estas funciones forman la base del script, manejando la salida, la interacción y la seguridad.

-   **`log()`**: Imprime mensajes con un formato estandarizado (`=> Mensaje`) y en color azul, facilitando la lectura y el seguimiento del progreso.
-   **`error()`**: Imprime un mensaje de error en rojo y, crucialmente, termina el script con un código de salida no cero (`exit 1`). Esto detiene la ejecución inmediatamente si algo crítico falla.
-   **`confirm_action()`**: Esta función es fundamental para la interactividad del script.
    -   Muestra una pregunta al usuario esperando una respuesta `Y` (Sí) o `n` (No). Presionar `Enter` se interpreta como "Sí".
    -   Si el script se ejecuta con `--noconfirm`, esta función siempre devuelve éxito (`return 0`) sin preguntar, permitiendo el flujo automático.
-   **Animaciones `BLA::*`**: Proporcionan feedback visual durante operaciones largas. `BLA::start_loading_animation` inicia un proceso en segundo plano que muestra la animación, y `BLA::stop_loading_animation` lo detiene.
-   **`trap '...' SIGINT`**: Este es un mecanismo de seguridad crucial. `trap` "atrapa" una señal del sistema, y `SIGINT` es la señal enviada cuando el usuario presiona `Ctrl+C`. Esta línea asegura que, si el script es cancelado, la función `BLA::stop_loading_animation` se ejecute para limpiar la animación y restaurar el cursor de la terminal, evitando dejar la terminal en un estado inconsistente.

### 3.2. Funciones de Limpieza (`nuke_*_traces`)

Estas funciones son vitales para la robustez del script, especialmente en sistemas donde se han realizado intentos previos de instalación de `yay` o `paru`.

-   **Propósito:** Prevenir el error `error: failed to commit transaction (conflicting files)`. Este error ocurre cuando `pacman` intenta instalar un archivo que ya existe en el sistema de archivos y no pertenece a ningún otro paquete conocido.
-   **Acciones:**
    1.  **`pacman -Rns --noconfirm <paquete>`**: Desinstala de forma agresiva el asistente de AUR y sus variantes (`-bin`, `-debug`).
        -   `R`: Remove (eliminar).
        -   `n`: No guardar archivos de configuración.
        -   `s`: "Recursive" (recursivo), elimina también las dependencias que no son necesarias para otros paquetes.
    2.  **`rm -rf ~/.config/<helper>` y `rm -rf ~/.cache/<helper>`**: Elimina los directorios de configuración y caché del usuario. A veces, los archivos de compilación o configuración antiguos pueden causar problemas.
    - El `|| true` al final del comando `pacman` asegura que si el paquete no existe, el comando no falle y el script no se detenga.

### 3.3. Fases Principales de la Instalación

#### `update_system()`
-   **Comando:** `pacman -Syyu --noconfirm`
-   **Desglose:**
    -   `S`: Sync (sincronizar paquetes). 
    -   `yy`: Fuerza la descarga de una nueva copia de la base de datos de paquetes, incluso si se considera actualizada. Es útil para evitar problemas con mirrors desactualizados.
    -   `u`: Upgrade (actualizar) todos los paquetes instalados a sus últimas versiones.
-   **Propósito:** Asegurar que el sistema base esté completamente actualizado antes de instalar nuevo software, previniendo problemas de dependencias. 

#### `install_pacman_packages()`
-   **Lógica:** Define una lista de paquetes esenciales. Antes de instalar, itera sobre la lista y usa `pacman -Q <pkg>` para verificar si cada paquete ya está instalado. Solo los paquetes que no están presentes se añaden a la lista `to_install`.
-   **Beneficio:** Esto hace que el script sea idempotente. Si se vuelve a ejecutar, no intentará reinstalar paquetes innecesariamente.
-   **Comando:** `pacman -S --noconfirm --needed "${to_install[@]}"`
    -   `--needed`: `pacman` no reinstalará un paquete si ya está actualizado a la última versión.

#### `install_aur_helper()`
Esta es una de las funciones más complejas y robustas.
1.  **Detección:** Utiliza `pacman -Q paru` y `pacman -Q yay` para consultar la base de datos de paquetes. Este método es infalible para determinar si un paquete está realmente instalado, a diferencia de `command -v` que solo verifica la existencia de un ejecutable en el `$PATH`.
2.  **Elección del Usuario:** Si no se detecta ningún asistente, se presenta un menú interactivo (`select`) para que el usuario elija. En modo no interactivo, `paru` se selecciona por defecto.
3.  **Proceso de Instalación (Ejemplo con `paru`):** 
    -   **Manejo de Conflictos:** `paru` necesita `rustup`, que entra en conflicto con el paquete `rust` de los repositorios oficiales. El script verifica si `rust` está instalado y, de ser así, lo desinstala (`pacman -Rns rust`) para evitar el conflicto.
    -   **Dependencias:** Instala `git`, `base-devel` (un grupo de paquetes esenciales para la compilación) y `rustup`.
    -   **Limpieza:** Llama a `nuke_paru_traces()` para una limpieza preventiva.
    -   **Compilación:**
        -   Clona el repositorio de `paru` desde el AUR.
        -   Usa `makepkg -s --noconfirm` para compilar el paquete. `-s` instala automáticamente las dependencias de compilación listadas en el `PKGBUILD`.
    -   **Instalación Forzada:**
        -   **Comando:** `sudo pacman -U --noconfirm --overwrite '*' paru-*.pkg.tar.zst`
        -   `U`: Upgrade/Install (instala un paquete desde un archivo local).
        -   `--overwrite '*'`: Esta es una "solución nuclear" que instruye a `pacman` a sobrescribir cualquier archivo que cause un conflicto, independientemente de su origen. Esto resuelve de forma definitiva los problemas de "archivos en conflicto" que la limpieza podría no haber solucionado.

#### `install_aur_packages()`
-   **Ejecución Segura:** Los asistentes de AUR **no deben** ejecutarse como root. El script usa `sudo -u "$SUDO_USER_NAME" "$AUR_HELPER" ...` para ejecutar el comando como el usuario original que llamó a `sudo`, que es la práctica correcta y segura.
-   **Lógica:** Al igual que con `pacman`, verifica qué paquetes de la lista ya están instalados usando `$AUR_HELPER -Q` y solo instala los que faltan.

#### `install_flatpak_packages()`
-   **Tolerancia a Fallos:** La principal característica aquí es la robustez. En lugar de `flatpak install <app1> <app2> ...` (que fallaría si una sola app no se encuentra), el script usa un bucle `for` para instalar cada aplicación **individualmente**.
-   **Manejo de Errores:** Si `flatpak install` falla para una aplicación, el `if ! ...` captura el error, imprime una advertencia en amarillo y el bucle continúa con la siguiente aplicación. Esto evita que una aplicación eliminada de Flathub detenga toda la instalación.
 
#### `copy_dotfiles()`
-   **Filosofía:** Usa enlaces simbólicos (`symlinks`) para gestionar la configuración. Los archivos de configuración reales residen en el directorio del repositorio (`Onix-hyprdots/dotfiles`), y en el `HOME` del usuario solo hay "accesos directos" a ellos. Esto permite actualizar la configuración simplemente haciendo un `git pull` en el repositorio.
-   **Proceso Detallado:**
    1.  **Copia de Seguridad:** Crea un directorio de respaldo único (`~/.dotfiles-backup-FECHA-HORA`).
    2.  **Bucle Seguro:** Usa `find ... -print0 | while IFS= read -r -d '' ...` para iterar sobre los archivos en `dotfiles/`. Este método es el más seguro para manejar nombres de archivo que contienen espacios o caracteres especiales.
    3.  **Respaldo:** Por cada archivo de configuración en el repositorio, comprueba si ya existe uno con el mismo nombre en el `HOME` del usuario. Si existe, lo mueve (`mv`) al directorio de respaldo.
    4.  **Enlace Simbólico:** Crea el enlace con `ln -s "$source_path" "$dest_path"`.
        -   `ln`: Link (crear enlace).
        -   `-s`: Symbolic (crear un enlace simbólico).

#### `install_grub_theme()` 
-   **Delegación:** Esta función actúa como un controlador que llama a un script más especializado: `scripts/install-grub-theme.sh`. Esto mantiene el script principal más limpio y organizado.
-   **Lógica:** Presenta un menú para instalar, desinstalar o saltar. En modo no interactivo, instala un tema por defecto.

#### `configure_services()`
-   **Comando:** `systemctl enable <servicio>`
-   **Propósito:** Le dice a `systemd` (el sistema de inicio de Linux) que inicie estos servicios automáticamente cada vez que el sistema arranque. `sddm` es el gestor de inicio de sesión gráfico y `bluetooth` es necesario para los dispositivos Bluetooth.

### 3.4. Lógica Principal (`main`)

La sección `main` actúa como el director de orquesta del script.
1.  Verifica si se pasó el argumento `--noconfirm` para establecer el modo de ejecución.
2.  Llama a cada función de instalación en un orden lógico y secuencial.
3.  Envuelve las llamadas en bloques `if confirm_action ...; then ... fi` para permitir la interacción del usuario.
4.  Implementa la lógica separada para instalar primero el asistente de AUR y luego, en una pregunta aparte, los paquetes de AUR.
5.  Finaliza con un mensaje de éxito y la recomendación de reiniciar.

---

## 4. Listas de Paquetes y Justificación

### Paquetes de Pacman
-   **`hyprland`, `sddm`**: El compositor de Wayland y el gestor de inicio de sesión, el corazón del entorno.
-   **`ark`, `kate`, `dolphin`, `okular`, `gwenview`**: Un conjunto de aplicaciones de KDE coherentes y potentes, incluyendo un archivador, editor de texto, gestor de archivos, visor de documentos y visor de imágenes.
-   **`git`, `curl`, `python`, `npm`**: Herramientas de desarrollo y línea de comandos esenciales.
-   **`flatpak`**: Habilita la instalación de aplicaciones empaquetadas de forma universal.
-   **`bluez`, `bluez-utils`**: La pila de software completa para el soporte de Bluetooth.

### Paquetes de AUR
-   **`vscodium-bin`**: Visual Studio Code sin la telemetría de Microsoft. La versión `-bin` usa los binarios precompilados, lo que acelera enormemente la instalación.
-   **`speedtest-go`**: Una herramienta de línea de comandos para pruebas de velocidad de internet.

### Aplicaciones de Flatpak
-   Son aplicaciones de escritorio adicionales que se benefician del aislamiento y las actualizaciones independientes que ofrece Flatpak. La selección puede variar según las necesidades del usuario.

---

## 5. Verificación Post-Instalación: Exportación de Listas de Paquetes

Después de que el script finalice, es útil poder generar una lista exacta de todo el software que se ha instalado. Esto es útil para la depuración, la migración o simplemente para tener un registro.

Puedes generar estas listas con los siguientes comandos:

### Paquetes de Repositorios Oficiales (Pacman)
Este comando lista solo los paquetes que fueron instalados explícitamente, ignorando las dependencias.
 
```bash
pacman -Qeq > pacman_packages.txt
```
- `-Q`: Consultar la base de datos de paquetes.
- `-e`: Mostrar solo los paquetes instalados explícitamente.
- `-q`: Modo silencioso, muestra solo los nombres.

### Paquetes del AUR
Este comando lista todos los paquetes que no provienen de los repositorios oficiales de Arch.

```bash
pacman -Qemq > aur_packages.txt
```
- `-m`: Mostrar paquetes "extranjeros" (foreign), es decir, los del AUR.

### Aplicaciones de Flatpak
Este comando lista los IDs de todas las aplicaciones instaladas a través de Flatpak.

```bash
flatpak list --app --columns=application > flatpak_packages.txt
```
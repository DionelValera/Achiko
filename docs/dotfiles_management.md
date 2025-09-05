# Guía de Gestión de Dotfiles (Método de Repositorio Único)

Este documento es una guía de referencia personal para entender y gestionar la configuración del entorno (dotfiles) de Project Achiko.

---

## 1. La Arquitectura: Repositorio Único y Centralizado

Para mantener el proyecto simple, unificado y fácil de navegar para los visitantes de GitHub, utilizamos una arquitectura de repositorio único:

1.  **`Achiko-hyprdots` (El Instalador):**
    -   **Contenido:** Todo está aquí. Scripts de instalación, documentación, temas y una carpeta especial llamada `dotfiles/`.
    -   **La carpeta `dotfiles/`:** Esta carpeta es la "fuente de la verdad". Contiene todos los archivos de configuración (`.config/`, `.bashrc`, etc.) que conforman el entorno de Project Achiko.

---

## 2. El Método: Enlaces Simbólicos (Symlinks)

En lugar de copiar archivos (lo que crea duplicados), el script de instalación utiliza **enlaces simbólicos**.

### ¿Cómo Funciona?

1.  **Copia de Seguridad:** El script `install.sh` primero respalda cualquier configuración existente del usuario en una carpeta `~/.dotfiles-backup-FECHA`.
2.  **Creación de Enlaces:** Luego, crea enlaces simbólicos desde el directorio `/home` del usuario hacia los archivos correspondientes dentro de la carpeta `Achiko-hyprdots/dotfiles/`.

    **Ejemplo:** Se crea un enlace `~/.config/hypr` que en realidad apunta a `.../Achiko-hyprdots/dotfiles/.config/hypr`.

### Ventajas

-   **Repositorio Único:** Todo el proyecto está en un solo lugar.
-   **Fuente Única de Verdad:** Los archivos de configuración solo existen físicamente dentro de la carpeta `dotfiles/`. No hay duplicados.
-   **Mantenimiento Sencillo:** Cualquier cambio que hagas en un archivo dentro de la carpeta `dotfiles/` se refleja inmediatamente en tu sistema.

---

## 3. Flujo de Trabajo del Desarrollador (¡Tú!)

Para añadir o modificar tu configuración, el flujo es muy directo:

1.  **Crea o Modifica un Archivo DENTRO de la carpeta `dotfiles/`:**
    `nvim /ruta/a/Achiko-hyprdots/dotfiles/.config/kitty/kitty.conf`

2.  **Añade, Comprueba y Sube los Cambios con Git (como siempre):**
    ```bash
    git add .
    git commit -m "Actualizar configuración de Kitty"
    git push
    ```

La próxima vez que un usuario ejecute `install.sh`, el script encontrará el nuevo archivo/carpeta que añadiste y creará el enlace simbólico correspondiente de forma automática.

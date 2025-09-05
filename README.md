# Project Achiko

<p align="center">
  <a href="https://hyprland.org/" target="_blank">
    <img src="https://raw.githubusercontent.com/hyprwm/Hyprland/main/assets/header.svg" width="250" alt="Hyprland Logo">
  </a>
  <a href="https://archlinux.org/" target="_blank">
    <img src="https://archlinux.org/static/logos/archlinux-logo-dark-scalable.svg" width="250" alt="Arch Linux Logo">
  </a>
</p>

<p align="center">
  <i>Una configuración de Hyprland elegante y funcional, optimizada para Arch Linux pero adaptable a tu universo Unix.</i>
</p>

<p align="center">
    <img src="https://img.shields.io/badge/Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white" alt="Arch Linux">
    <img src="https://img.shields.io/badge/Hyprland-00ADD8?style=for-the-badge&logo=hyprland&logoColor=white" alt="Hyprland">
    <img src="https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=for-the-badge" alt="Contributions Welcome">
</p>

**Project Achiko** es mi visión personal de un entorno de escritorio perfecto con Hyprland. Nacido de la pasión por la personalización y la eficiencia, este proyecto busca ofrecer una experiencia de usuario cohesiva, moderna y altamente adaptable. Aunque está optimizado para Arch Linux, los principios y scripts son portables a otros sistemas Unix-like.

---

## ✨ Galería

¡Una imagen vale más que mil palabras! Aquí puedes ver Project Achiko en acción.

<p align="center">
  <i>(Aquí irán las capturas de pantalla del escritorio, terminal, aplicaciones, etc.)</i>
  <br>
  <b>[¡Próximamente capturas de pantalla!]</b>
  <!-- <img src="https://raw.githubusercontent.com/gist/DionelValera/f9499638b73f9352c64f73c5a4aad7a1/raw/achiko_placeholder.png" alt="Project Achiko Placeholder" width="600"> -->

</p>

## 🚀 Características Principales

Project Achiko no es solo un conjunto de archivos de configuración; es un ecosistema pensado para mejorar tu flujo de trabajo y tu interacción diaria con el sistema.

-   🎨 **Shell Renovada:** Una experiencia de terminal mejorada con una configuración moderna, autocompletado inteligente y alias útiles para una productividad máxima.
-   🛠️ **Herramientas de Desarrollo Flexibles:** Scripts de instalación que te permiten elegir solo las herramientas de desarrollo que necesitas, manteniendo tu sistema limpio y ágil.
-   💻 **Compatibilidad Universal:** Diseñado para funcionar a la perfección en una amplia gama de dispositivos:
    -   **PCs de Escritorio:** Aprovecha al máximo la potencia de tu equipo.
    -   **Portátiles:** Optimizado para un buen manejo de la batería y teclas de función.
    -   **Pantallas Táctiles:** Soporte completo para gestos y navegación táctil, ideal para portátiles 2-en-1 y tablets como la Microsoft Surface.
-   📦 **Gestión de Paquetes Simplificada:** Utiliza `pacman`, un asistente de AUR (`yay`/`paru`) y `flatpak` para un acceso completo al software que necesitas, desde los repositorios oficiales hasta el AUR y Flathub.

## 🔧 Instalación

Empezar con Project Achiko es sencillo. (¡Se recomienda una instalación limpia de Arch Linux!).

### Instalación Rápida (Recomendada)

Para una instalación completa y automatizada, simplemente copia y pega el siguiente comando en tu terminal:

```bash
git clone https://github.com/DionelValera/Achiko-hyprdots.git && cd Achiko-hyprdots && chmod +x install.sh && sudo ./install.sh
```
> **Nota:** El script te pedirá tu contraseña para ejecutar los comandos que requieren privilegios de administrador (`sudo`). Se recomienda leer el script `install.sh` para entender los cambios que se realizarán en tu sistema.

### Instalación Desatendida
Para una instalación totalmente automatizada, puedes usar el flag `--noconfirm`. Esto aceptará automáticamente todos los pasos. En este modo, el script instalará el tema de GRUB predeterminado (`Catppuccin Latte`) sin mostrar el menú interactivo.
```bash
sudo ./install.sh --noconfirm
```

### Instalación Manual

Si prefieres tener un control total sobre cada paso, puedes seguir la guía de instalación manual:
➡️ **[Guía de Instalación y Configuración](indispensables.md)**

##  Uso Avanzado

### Desinstalación de la Configuración
Se proporciona un script para revertir los cambios de configuración (dotfiles y tema de GRUB). Este script **no** desinstala los paquetes de software.
```bash
sudo ./uninstall.sh
sudo ./uninstall.sh --noconfirm # Para desinstalación desatendida
```

### Ejecución de Scripts Individuales
Algunos scripts, como el del tema de GRUB, pueden ejecutarse de forma independiente.
```bash
sudo ./scripts/install-grub-theme.sh [install|uninstall]
```

### Exportar Listas de Paquetes
Después de la instalación, puedes generar un registro de todo el software instalado con estos comandos:

*   **Paquetes de Repositorios Oficiales (Pacman):**
    ```bash
    pacman -Qeq > pacman_packages.txt
    ```
*   **Paquetes del AUR (yay/paru):**
    ```bash
    pacman -Qemq > aur_packages.txt
    ```
*   **Aplicaciones de Flatpak:**
    ```bash
    flatpak list --app --columns=application > flatpak_packages.txt
    ```

## 🌱 Sobre el Proyecto y Contribuciones

Este proyecto es mantenido por un recién graduado en ingeniería de software como una forma de aplicar y compartir conocimientos. El desarrollo es continuo, aunque a un ritmo sostenible y motivado por la pasión.

**¡Tu ayuda es bienvenida!** Si tienes ideas, mejoras o encuentras un error, no dudes en:

-   Abrir un **Issue** para reportar problemas o sugerir características.
-   Enviar un **Pull Request** con tus mejoras.

Juntos podemos hacer de Project Achiko una experiencia aún mejor.

## ❤️ Agradecimientos

Un agradecimiento especial a la comunidad de **Hyprland**, **Arch Linux** y a todos los desarrolladores de las herramientas de código abierto que hacen posible este proyecto.

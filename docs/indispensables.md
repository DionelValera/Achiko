# Guía de Instalación y Configuración: Onix Hyprdots

Guía personal para instalar y configurar un entorno de escritorio con Hyprland en Arch Linux, organizada por gestor de paquetes y pasos de configuración.

---

## 1. Actualización del Sistema

Antes de instalar cualquier paquete, es crucial asegurarse de que el sistema esté completamente actualizado.

```bash
sudo pacman -Syyu --noconfirm
```

## 2. Instalación de Paquetes (Pacman)

Instala el entorno de escritorio base, utilidades y aplicaciones esenciales desde los repositorios oficiales de Arch.

```bash
sudo pacman -S --noconfirm \
    hyprland sddm \
    ark kate dolphin okular discover gwenview \
    libreoffice-still libreoffice-still-es \
    git curl python npm \
    chromium vivaldi \
    nautilus gvfs-mtp \
    vlc fastfetch \
    flatpak \
    bluez bluez-utils \
    qt6-multimedia qt6-virtualkeyboard qt6-svg
```

**Nota:** `nautilus` (de GNOME) y `dolphin` (de KDE) son ambos gestores de archivos. Puedes elegir uno o instalar ambos.

## 3. Instalación de un Asistente de AUR (yay o paru)

Para instalar paquetes desde el Arch User Repository (AUR), necesitas un asistente como `yay` o `paru`. Si aún no tienes uno, puedes instalar `yay` así:

```bash
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay
```

## 4. Instalación de Paquetes (AUR)

Ahora, usa `yay` (o `paru`) para instalar aplicaciones desde el AUR.

```bash
yay -S --noconfirm \
    vscodium-bin vscodium-bin-marketplace \
    speedtest-go \
    waydroid \
    zen-browser-bin
```

## 5. Instalación de Aplicaciones (Flatpak)

Instala aplicaciones adicionales usando Flatpak.

```bash
flatpak install flathub --noninteractive \
    com.github.phase1geo.cohesion \
    org.gimp.GIMP.Plugin.Fotema \
    info.febvre.Amberol
```

**Nota:** No encontré paquetes Flatpak oficiales para `whatsapp` o `gemini`. Generalmente se usan como aplicaciones web. Tampoco encontré un paquete llamado `gapples`.

## 6. Configuración Post-Instalación

Habilita los servicios necesarios para que se inicien con el sistema.

### SDDM (Gestor de Inicio de Sesión)
```bash
sudo systemctl enable sddm
```

### Bluetooth
```bash
sudo systemctl enable bluetooth
```

## 7. Reiniciar

Una vez que todo esté instalado y configurado, reinicia tu sistema para aplicar los cambios.

```bash
reboot
```

 python: man page
    completion parser /
    web config tool
    [instalado]
    pkgfile:
    command-not-found hook
    groff: --help for
    built-in commmands
    [instalado]
    mandoc: --help for
    built-in commmands
    (alternative)
    xsel: X11 clipboard
    integration
    xclip: X11 clipboard
    integration
    (alternative)
    wl-clipboard: Wayland
    clipboard integration
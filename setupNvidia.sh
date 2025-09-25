#!/bin/bash

# NVIDIA + GNOME + Wayland setup (dla Arch/EndeavourOS)
# ⚠️ NIE instaluje przeglądarek – tylko konfiguruje środowisko uruchomieniowe

set -e  # zatrzymaj skrypt przy błędzie

echo "=== 🔄 Instalacja sterowników NVIDIA i zależności VAAPI ==="

sudo pacman -Syu --needed \
  nvidia \
  nvidia-utils \
  nvidia-settings \
  libva \
  libva-nvidia-driver \
  egl-wayland

echo "✅ Sterowniki i biblioteki zainstalowane"
echo ""

# Edycja pliku GDM – upewnij się, że Wayland jest włączony
CUSTOM_CONF="/etc/gdm/custom.conf"

if [ -f "$CUSTOM_CONF" ]; then
    echo "=== 🛠️ Sprawdzanie ustawień GDM (Wayland) ==="
    sudo sed -i 's/^WaylandEnable=false/#WaylandEnable=false/' "$CUSTOM_CONF"
    echo "✅ Plik $CUSTOM_CONF zmodyfikowany (jeśli potrzeba)"
else
    echo "⚠️ Plik $CUSTOM_CONF nie istnieje – pomijam"
fi

# Utwórz katalog, jeśli nie istnieje
mkdir -p ~/.local/share/applications

echo ""
echo "=== 🦊 Tworzenie skrótu: Firefox z VAAPI + Wayland ==="

cat <<EOF > ~/.local/share/applications/firefox-vaapi.desktop
[Desktop Entry]
Name=Firefox (VAAPI)
Exec=env MOZ_ENABLE_WAYLAND=1 LIBVA_DRIVER_NAME=nvidia firefox %u
Terminal=false
Type=Application
Icon=firefox
Categories=Network;WebBrowser;
StartupNotify=true
EOF

echo "✅ Utworzono: ~/.local/share/applications/firefox-vaapi.desktop"
echo ""

echo "=== 🌐 Tworzenie skrótu: Google Chrome z VAAPI + Wayland ==="

cat <<EOF > ~/.local/share/applications/google-chrome-vaapi.desktop
[Desktop Entry]
Name=Google Chrome (VAAPI + Wayland)
Exec=env \
  XDG_SESSION_TYPE=wayland \
  LIBVA_DRIVER_NAME=nvidia \
  google-chrome-stable \
  --enable-features=VaapiVideoDecoder,UseOzonePlatform \
  --ozone-platform=wayland %U
Terminal=false
Type=Application
Icon=google-chrome
Categories=Network;WebBrowser;
StartupNotify=true
EOF

echo "✅ Utworzono: ~/.local/share/applications/google-chrome-vaapi.desktop"
echo ""

echo "=== 🔁 Restart systemu zalecany ==="
read -p "Czy chcesz zrestartować teraz komputer? [T/n]: " odp

if [[ "$odp" =~ ^[TtYy]?$ ]]; then
    echo "🔄 Trwa restart systemu..."
    sleep 2
    systemctl reboot
else
    echo "🕑 Możesz zrestartować komputer później, by zastosować zmiany."
fi

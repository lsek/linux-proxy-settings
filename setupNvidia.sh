#!/bin/bash

# NVIDIA Wayland Setup Script for Arch/EndeavourOS (GNOME + NVIDIA Quadro P620)
# Wersja: z integracją Firefox + Chromium + VAAPI

set -e  # zatrzymaj skrypt przy błędzie

echo "=== 🔄 Aktualizacja systemu i instalacja sterowników NVIDIA ==="

sudo pacman -Syu --needed \
  nvidia \
  nvidia-utils \
  nvidia-settings \
  libva \
  libva-nvidia-driver \
  egl-wayland \
  firefox \
  chromium \
  xdg-utils \
  nano

echo "=== ✅ Instalacja pakietów zakończona ==="
echo ""

# Edytuj plik konfiguracyjny GDM, jeśli istnieje
CUSTOM_CONF="/etc/gdm/custom.conf"

if [ -f "$CUSTOM_CONF" ]; then
    echo "=== 🛠️ Sprawdzanie ustawień GDM (Wayland) ==="
    sudo sed -i 's/^WaylandEnable=false/#WaylandEnable=false/' "$CUSTOM_CONF"
    echo "✅ Plik $CUSTOM_CONF został sprawdzony i zmodyfikowany (jeśli potrzeba)."
else
    echo "⚠️ Plik $CUSTOM_CONF nie istnieje – pomijam modyfikację GDM."
fi

echo ""
echo "=== 🦊 Tworzenie skrótu: Firefox z VAAPI + Wayland ==="

mkdir -p ~/.local/share/applications

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

echo "=== 🌐 Tworzenie skrótu: Chromium z VAAPI + Wayland ==="

cat <<EOF > ~/.local/share/applications/chromium-vaapi.desktop
[Desktop Entry]
Name=Chromium (VAAPI + Wayland)
Exec=env \
  XDG_SESSION_TYPE=wayland \
  LIBVA_DRIVER_NAME=nvidia \
  chromium --enable-features=VaapiVideoDecoder,UseOzonePlatform \
           --ozone-platform=wayland %U
Terminal=false
Type=Application
Icon=chromium
Categories=Network;WebBrowser;
StartupNotify=true
EOF

echo "✅ Utworzono: ~/.local/share/applications/chromium-vaapi.desktop"
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

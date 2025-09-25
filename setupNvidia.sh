#!/bin/bash

# NVIDIA Wayland Setup Script for Arch-based distros (e.g. EndeavourOS, Arch, etc.)
# GPU: NVIDIA Quadro P620 (Pascal) – tested on GNOME + Wayland

set -e  # przerwij skrypt, jeśli jakiś krok się nie powiedzie

echo "=== 🔄 Aktualizacja systemu i instalacja sterowników NVIDIA ==="

sudo pacman -Syu --needed \
  nvidia \
  nvidia-utils \
  nvidia-dkms \
  nvidia-settings \
  libva \
  libva-nvidia-driver \
  egl-wayland

echo "=== ✅ Instalacja zakończona ==="
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
echo "=== 🔁 Restart systemu zalecany ==="
read -p "Czy chcesz zrestartować teraz komputer? [T/n]: " odp

if [[ "$odp" =~ ^[TtYy]?$ ]]; then
    echo "🔄 Trwa restart systemu..."
    sleep 2
    systemctl reboot
else
    echo "🕑 Możesz zrestartować komputer później, by zastosować zmiany."
fi


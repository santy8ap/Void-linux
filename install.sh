#!/bin/bash
# ================================================================
#  Void Linux BSPWM Rice — Auto Installer
#  github.com/santy8ap/Void-linux
# ================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

DOTFILES_REPO="https://github.com/santy8ap/Void-linux.git"
DOTFILES_DIR="$HOME/.dotfiles"

banner() {
  echo -e "${PURPLE}"
  echo "  ██╗   ██╗ ██████╗ ██╗██████╗      ██████╗ ███████╗"
  echo "  ██║   ██║██╔═══██╗██║██╔══██╗     ██╔══██╗██╔════╝"
  echo "  ██║   ██║██║   ██║██║██║  ██║     ██████╔╝███████╗"
  echo "  ╚██╗ ██╔╝██║   ██║██║██║  ██║     ██╔══██╗╚════██║"
  echo "   ╚████╔╝ ╚██████╔╝██║██████╔╝     ██████╔╝███████║"
  echo "    ╚═══╝   ╚═════╝ ╚═╝╚═════╝      ╚═════╝ ╚══════╝"
  echo -e "${CYAN}         BSPWM · Catppuccin Mocha · by santy8ap${NC}"
  echo ""
}

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC}   $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERR]${NC}  $1"; exit 1; }
step()    { echo -e "\n${PURPLE}━━━ $1 ━━━${NC}"; }

# Verificar que es Void Linux
check_void() {
  step "Verificando sistema"
  [ -f /etc/void-release ] || error "Este script es solo para Void Linux"
  command -v xbps-install > /dev/null || error "xbps-install no encontrado"
  success "Void Linux detectado"
}

# Instalar paquetes base
install_packages() {
  step "Instalando paquetes"
  PKGS=(
    bspwm sxhkd polybar picom dunst rofi kitty
    feh nitrogen lxappearance
    NetworkManager network-manager-applet
    udiskie gvfs gvfs-mtp
    thunar thunar-volman ranger
    qt5ct kvantum
    pulseaudio pavucontrol
    brightnessctl playerctl
    flameshot maim xclip
    xdotool xdg-user-dirs xdg-user-dirs-gtk
    papirus-icon-theme
    libnotify dunst
    i3lock-color betterlockscreen xss-lock
    gamemode
    zsh starship
    git wget curl
    cpupower earlyoom zramen
    fontconfig
  )
  sudo xbps-install -Sy "${PKGS[@]}"
  success "Paquetes instalados"
}

# Instalar fuentes
install_fonts() {
  step "Instalando fuentes"
  mkdir -p ~/.local/share/fonts/FontAwesome6
  mkdir -p ~/.local/share/fonts/JetBrainsMono

  # JetBrains Nerd Font
  if ! fc-list | grep -q "JetBrains"; then
    info "Descargando JetBrains Nerd Font..."
    JB_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    wget -q "$JB_URL" -O /tmp/JetBrainsMono.tar.xz
    tar -xf /tmp/JetBrainsMono.tar.xz -C ~/.local/share/fonts/JetBrainsMono/ 2>/dev/null || true
  fi

  # Font Awesome 6
  if ! fc-list | grep -q "Font Awesome 6"; then
    info "Descargando Font Awesome 6..."
    FA_URL="https://github.com/FortAwesome/Font-Awesome/releases/download/6.7.2/fontawesome-free-6.7.2-desktop.zip"
    wget -q "$FA_URL" -O /tmp/fa6.zip
    unzip -jo /tmp/fa6.zip "*/otfs/*.otf" -d ~/.local/share/fonts/FontAwesome6/
  fi

  fc-cache -fv > /dev/null 2>&1
  success "Fuentes instaladas"
}

# Clonar dotfiles
install_dotfiles() {
  step "Instalando dotfiles"

  if [ -d "$DOTFILES_DIR" ]; then
    warn "~/.dotfiles ya existe, haciendo backup..."
    mv "$DOTFILES_DIR" "${DOTFILES_DIR}.bak.$(date +%s)"
  fi

  git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"
  git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" config status.showUntrackedFiles no

  # Backup de configs existentes
  CONFLICTS=$(git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" checkout 2>&1 | grep "error:" | awk '{print $2}')
  if [ -n "$CONFLICTS" ]; then
    warn "Haciendo backup de configs existentes..."
    mkdir -p ~/.dotfiles-backup
    for f in $CONFLICTS; do
      cp -r "$HOME/$f" ~/.dotfiles-backup/ 2>/dev/null || true
    done
  fi

  git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" checkout -f
  success "Dotfiles instalados"
}

# Servicios runit
enable_services() {
  step "Activando servicios"
  SERVICES=(dbus elogind NetworkManager bluetoothd acpid earlyoom zramen)
  for svc in "${SERVICES[@]}"; do
    [ -d "/etc/sv/$svc" ] && sudo ln -sf "/etc/sv/$svc" /var/service/ 2>/dev/null
  done
  success "Servicios activados"
}

# Configurar shell
setup_shell() {
  step "Configurando Zsh"
  if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    success "Shell cambiado a Zsh (requiere re-login)"
  else
    success "Zsh ya es el shell por defecto"
  fi
}

# Optimizaciones
setup_optimizations() {
  step "Aplicando optimizaciones"
  sudo mkdir -p /etc/sysctl.d
  sudo tee /etc/sysctl.d/99-performance.conf > /dev/null << 'EOF'
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 50
vm.max_map_count = 2147483642
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_fastopen = 3
EOF
  sudo sysctl --system > /dev/null 2>&1
  success "Optimizaciones aplicadas"
}

# Wallpaper
setup_wallpaper() {
  step "Configurando wallpaper"
  mkdir -p ~/Imágenes
  if [ ! -f ~/Imágenes/void-anime.webp ]; then
    info "Descargando wallpaper..."
    wget -q "https://raw.githubusercontent.com/santy8ap/Void-linux/main/assets/wallpaper.webp" \
      -O ~/Imágenes/void-anime.webp 2>/dev/null || warn "Wallpaper no encontrado en assets/"
  fi
  command -v feh > /dev/null && feh --bg-fill ~/Imágenes/void-anime.webp 2>/dev/null || true
  success "Wallpaper configurado"
}

# Alias dotfiles
setup_alias() {
  grep -q "alias dotfiles" ~/.zshrc 2>/dev/null || \
    echo "alias dotfiles='git --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME'" >> ~/.zshrc
  grep -q "alias dotfiles" ~/.bashrc 2>/dev/null || \
    echo "alias dotfiles='git --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME'" >> ~/.bashrc
}

# Resumen final
final_message() {
  echo ""
  echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║     ✅ Instalación completada!         ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${CYAN}Próximos pasos:${NC}"
  echo -e "  ${YELLOW}1.${NC} Reinicia sesión o ejecuta: ${CYAN}exec zsh${NC}"
  echo -e "  ${YELLOW}2.${NC} Abre ${CYAN}lxappearance${NC} → selecciona tema Qogir Dark"
  echo -e "  ${YELLOW}3.${NC} Abre ${CYAN}qt5ct${NC} → Style: kvantum-dark"
  echo -e "  ${YELLOW}4.${NC} Para gaming: instala ${CYAN}Proton-GE${NC} desde Steam"
  echo ""
  echo -e "  ${PURPLE}Repo:${NC} https://github.com/santy8ap/Void-linux"
  echo ""
}

# ── Main ────────────────────────────────────────────────────────
banner
check_void
install_packages
install_fonts
install_dotfiles
enable_services
setup_shell
setup_optimizations
setup_wallpaper
setup_alias
final_message

#!/bin/bash

# Script configuration
LOG_FILE="/tmp/installpacks.log"
ERROR_LOG="/tmp/installpacks_error.log"
TEMP_DIR="/tmp/installpacks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ASCII Art
print_header() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                            ║"
    echo "║        ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗                   ║"
    echo "║        ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║                   ║"
    echo "║        ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║                   ║"
    echo "║        ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║                   ║"
    echo "║        ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗              ║"
    echo "║        ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝              ║"
    echo "║                                                                            ║"
    echo "║                      Package Installation Script                           ║"
    echo "║                            Arch Linux                                      ║"
    echo "║                                                                            ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to log messages with a fancy format
log() {
    echo -e "${GREEN}[${BOLD}✓${NC}] ${GREEN}$1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to log errors with a fancy format
error_log() {
    echo -e "${RED}[${BOLD}✗${NC}] ${RED}ERROR: $1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$ERROR_LOG"
}

# Function to show progress with a fancy format
progress() {
    echo -e "${YELLOW}[${BOLD}⟳${NC}] ${YELLOW}$1${NC}"
}

# Function to show section headers
section_header() {
    echo -e "\n${MAGENTA}${BOLD}════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}${BOLD}  $1${NC}"
    echo -e "${MAGENTA}${BOLD}════════════════════════════════════════════════════════════════════════════${NC}\n"
}

# Function to handle errors
error_exit() {
    error_log "$1"
    echo -e "\n${RED}${BOLD}Installation failed! Check the error log for details.${NC}"
    exit 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to create temporary directory
setup_temp_dir() {
    mkdir -p "$TEMP_DIR"
    trap 'rm -rf "$TEMP_DIR"' EXIT
}

# Function to prompt user for AUR helper choice
select_aur_helper() {
    echo -e "\n\033[1;36mWhich AUR helper would you like to install?\033[0m"
    echo -e "\033[1;33m1) paru\033[0m"
    echo -e "\033[1;33m2) yay\033[0m"
    echo -e "\033[1;32m--------------------------------\033[0m"
    read -p "$'\033[1;34mEnter your choice (1 or 2): \033[0m'" choice

    case $choice in
        1)
            install_paru
            ;;
        2)
            install_yay
            ;;
        *)
            error_exit "Invalid choice. Please select 1 for paru or 2 for yay."
            ;;
    esac
}

# Function to install paru
install_paru() {
    if command_exists paru; then
        log "paru is already installed"
        return 0
    fi

    log "Installing paru (AUR helper)..."

    # Install required dependencies
    log "Installing dependencies..."
    if ! sudo pacman -S --needed --noconfirm base-devel git; then
        error_exit "Failed to install dependencies for paru"
    fi

    # Clone and install paru
    log "Cloning paru repository..."
    if ! git clone https://aur.archlinux.org/paru.git "$TEMP_DIR/paru"; then
        error_exit "Failed to clone paru repository"
    fi

    cd "$TEMP_DIR/paru" || error_exit "Failed to change to paru directory"

    log "Building and installing paru..."
    if ! makepkg -si --noconfirm; then
        error_exit "Failed to build and install paru"
    fi

    # Verify installation
    if ! command_exists paru; then
        error_exit "paru installation failed verification"
    fi

    log "paru has been installed successfully!"
}

# Function to install yay
install_yay() {
    if command_exists yay; then
        log "yay is already installed"
        return 0
    fi

    log "Installing yay (AUR helper)..."

    # Install required dependencies
    log "Installing dependencies..."
    if ! sudo pacman -S --needed --noconfirm base-devel git; then
        error_exit "Failed to install dependencies for yay"
    fi

    # Create temp dir and ensure cleanup
    TEMP_DIR="$(mktemp -d)"
    trap "rm -rf '$TEMP_DIR'" EXIT

    # Clone yay
    log "Cloning yay repository..."
    if ! git clone https://aur.archlinux.org/yay.git "$TEMP_DIR/yay"; then
        error_exit "Failed to clone yay repository"
    fi

    # Build and install
    (
        cd "$TEMP_DIR/yay" || error_exit "Failed to change to yay directory"
        log "Building and installing yay..."
        if ! makepkg -si --noconfirm; then
            error_exit "Failed to build and install yay"
        fi
    )

    # Verify installation
    if ! command_exists yay; then
        error_exit "yay installation failed verification"
    fi

    log "yay has been installed successfully!"
}

# Function to check system requirements
check_system_requirements() {
    log "Checking system requirements..."
    
    if ! command_exists pacman; then
        error_exit "This script requires Arch Linux or an Arch-based distribution"
    fi

    if ! command_exists sudo; then
        error_exit "sudo is required but not installed"
    fi

    # Check for sufficient disk space (at least 10GB free)
    local free_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$free_space" -lt 10 ]; then
        error_exit "Insufficient disk space. At least 10GB free space is required."
    fi
}

# Function to set up mirrors
setup_mirrors() {
    section_header "Setting up Package Mirrors"
    
    # Check if reflector is installed
    if ! command_exists reflector; then
        log "Installing reflector..."
        if ! sudo pacman -S --noconfirm reflector; then
            error_exit "Failed to install reflector"
        fi
    fi

    # Backup current mirrorlist
    log "Backing up current mirrorlist..."
    if ! sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup; then
        error_exit "Failed to backup mirrorlist"
    fi

    # Get country code
    log "Detecting country..."
    COUNTRY=$(curl -s https://ipapi.co/country_code/)
    if [ -z "$COUNTRY" ]; then
        COUNTRY="US"  # Default to US if detection fails
    fi

    log "Detected country: $COUNTRY"

    # Update mirrors using reflector
    log "Updating mirrors..."
    if ! sudo reflector \
        --country "$COUNTRY" \
        --age 12 \
        --sort rate \
        --protocol https \
        --latest 20 \
        --save /etc/pacman.d/mirrorlist; then
        error_exit "Failed to update mirrors"
    fi

    # Verify the new mirrorlist
    if [ -s /etc/pacman.d/mirrorlist ]; then
        log "Mirrorlist updated successfully!"
        log "New mirrorlist location: /etc/pacman.d/mirrorlist"
        log "Backup location: /etc/pacman.d/mirrorlist.backup"
        
        # Show the first few mirrors
        echo -e "\n${BLUE}Top mirrors:${NC}"
        head -n 15 /etc/pacman.d/mirrorlist
    else
        error_exit "Failed to update mirrorlist"
    fi
}

# Function to set up Chaotic-AUR repository
setup_chaotic_aur() {
    section_header "Setting up Chaotic-AUR Repository"
    
    if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        progress "Adding The Chaotic-AUR Repository..."
        
        # Receive and locally sign the key
        progress "Receiving repository key..."
        if ! sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com; then
            error_exit "Failed to receive Chaotic-AUR repository key"
        fi
        log "Repository key received successfully"
        
        progress "Signing repository key locally..."
        if ! sudo pacman-key --lsign-key 3056513887B78AEB; then
            error_exit "Failed to locally sign Chaotic-AUR repository key"
        fi
        log "Repository key signed successfully"
        
        # Install the keyring and mirrorlist
        progress "Installing Chaotic-AUR keyring package..."
        if ! sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'; then
            error_exit "Failed to install Chaotic-AUR keyring package"
        fi
        log "Keyring package installed successfully"
        
        progress "Installing Chaotic-AUR mirrorlist package..."
        if ! sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'; then
            error_exit "Failed to install Chaotic-AUR mirrorlist package"
        fi
        log "Mirrorlist package installed successfully"
        
        # Add repository to pacman.conf
        progress "Adding repository to pacman configuration..."
        if ! echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf; then
            error_exit "Failed to add Chaotic-AUR repository to pacman.conf"
        fi
        
        # Verify the repository was added correctly
        if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
            error_exit "Failed to verify Chaotic-AUR repository addition"
        fi

        # Update package database with new mirrors
        log "Updating package database..."
        if ! sudo pacman -Syy; then
            error_exit "Failed to update package database"
        fi
        
        echo -e "\n${GREEN}${BOLD}✓ Chaotic-AUR Repository Setup Complete!${NC}"
        echo -e "${BLUE}Repository details:${NC}"
        echo -e "  ${CYAN}•${NC} Repository: ${YELLOW}chaotic-aur${NC}"
        echo -e "  ${CYAN}•${NC} Mirrorlist: ${YELLOW}/etc/pacman.d/chaotic-mirrorlist${NC}"
        echo -e "  ${CYAN}•${NC} Configuration: ${YELLOW}/etc/pacman.conf${NC}\n"
    else
        echo -e "${GREEN}${BOLD}✓ Chaotic-AUR Repository already configured${NC}"
        echo -e "${BLUE}Current configuration:${NC}"
        echo -e "  ${CYAN}•${NC} Repository: ${YELLOW}chaotic-aur${NC}"
        echo -e "  ${CYAN}•${NC} Mirrorlist: ${YELLOW}/etc/pacman.d/chaotic-mirrorlist${NC}\n"
    fi
}

# Pacman packages to install
PACMAN_PACKAGES=(
    "7zip" "awesome-terminal-fonts" "firefox" "firefox-ublock-origin" "gparted" "btop" "cava"
    "cronie" "fastfetch" "flatpak" "flatseal" "geany"
    "ghostty" "htop" "vlc" "neofetch" "nmap" "nvtop" "octopi"
    "oh-my-posh-bin" "terminus-font" "timeshift" "tree" "ttf-fira-code" "fzf"
    "ttf-hack-nerd" "ttf-jetbrains-mono-nerd" "ttf-liberation" 
    "ttf-ubuntu-font-family" "unrar" "windsurf" "unzip" "update-grub"
    "yt-dlp" "tar" "rsync"
)

# Flatpak packages to install
FLATPAK_PACKAGES=(
    "com.spotify.Client" "com.usebottles.bottles"
    "dev.bragefuglseth.Keypunch" "dev.vencord.Vesktop"
    "io.github.flattool.Warehouse" "io.github.giantpinkrobots.flatsweep"
    "io.gitlab.theevilskeleton.Upscaler" "io.missioncenter.MissionCenter"
    "md.obsidian.Obsidian" "org.localsend.localsend_app"
)

# Gaming packages to install
GAMING_PACKAGES=(
    "arch-gaming-meta" "faugus-launcher"
)

# Flatpak gaming packages to install
FLATPAK_GAMING_PACKAGES=(
    "com.github.Rosalie241.RMG" "com.heroicgameslauncher.hgl"
    "org.DolphinEmu.dolphin-emu" "org.ppsspp.PPSSPP" "org.duckstation.DuckStation" "net.davidotek.pupgui2" "app.xemu.xemu"
    "net.pcsx2.PCSX2" "com.vysp3r.ProtonPlus" "io.github.ryubing.Ryujinx" "net.rpcs3.RPCS3" "io.mgba.mGBA" "net.shadps4.shadPS4"
)

# Function to detect available AUR helper
get_aur_helper() {
    if command_exists paru; then
        echo "paru"
    elif command_exists yay; then
        echo "yay"
    else
        error_exit "No AUR helper (paru or yay) is installed. Please install one first."
    fi
}

# Function to install Pacman/AUR packages
install_pacman_packages() {
    progress "Updating package database..."
    if ! sudo pacman -Syu --noconfirm; then
        error_exit "Failed to update package database"
    fi

    progress "Installing Pacman/AUR packages..."
    for package in "${PACMAN_PACKAGES[@]}"; do
        log "Installing $package..."
        if ! sudo pacman -S --needed --noconfirm "$package"; then
            log "Trying to install $package from AUR..."
            if ! "$AUR_HELPER" -S --noconfirm "$package"; then
                error_log "Failed to install $package"
            fi
        fi
    done
}

# Function to install Flatpak packages
install_flatpaks() {
    if ! command_exists flatpak; then
        error_exit "Flatpak is not installed"
    fi

    progress "Setting up Flatpak..."
    if ! flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
        error_exit "Failed to add Flatpak remote"
    fi

    progress "Installing Flatpak packages..."
    for package in "${FLATPAK_PACKAGES[@]}"; do
        log "Installing $package..."
        if ! flatpak install -y flathub "$package"; then
            error_log "Failed to install $package"
        fi
    done
}

# Function to handle gaming package selection
select_gaming_packages() {
    echo -e "\n${CYAN}${BOLD}Gaming Package Selection${NC}"
    echo -e "${YELLOW}Would you like to install gaming packages? (y/n)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        section_header "Installing Gaming Packages"
        
        # Install regular gaming packages
        progress "Installing system gaming packages..."
        for package in "${GAMING_PACKAGES[@]}"; do
            log "Installing $package..."
            if ! sudo pacman -S --needed --noconfirm "$package"; then
                log "Trying to install $package from AUR..."
                if ! "$AUR_HELPER" -S --noconfirm "$package"; then
                    error_log "Failed to install $package"
                fi
            fi
        done

        # Install Flatpak gaming packages
        progress "Installing Flatpak gaming applications..."
        for package in "${FLATPAK_GAMING_PACKAGES[@]}"; do
            log "Installing $package..."
            if ! flatpak install -y flathub "$package"; then
                error_log "Failed to install $package"
            fi
        done
    fi
}

# Function to show summary
show_summary() {
    log "Installation Summary:"
    log "Log file: $LOG_FILE"
    log "Error log: $ERROR_LOG"
    
    if [ -f "$ERROR_LOG" ]; then
        local error_count=$(wc -l < "$ERROR_LOG")
        if [ "$error_count" -gt 0 ]; then
            log "There were $error_count errors during installation. Check $ERROR_LOG for details."
        else
            log "Installation completed successfully with no errors!"
        fi
    fi
}

# Main execution
clear
print_header

# Initialize logging
touch "$LOG_FILE" "$ERROR_LOG"
chmod 644 "$LOG_FILE" "$ERROR_LOG"

# Setup temporary directory
setup_temp_dir

# Check system requirements
section_header "Checking System Requirements"
check_system_requirements

# Set up mirrors
setup_mirrors

# Install AUR helper
section_header "Installing AUR Helper"
select_aur_helper

# Install Chaotic-AUR repository
section_header "Installing Chaotic-AUR Repository"
setup_chaotic_aur

# Detect AUR helper
AUR_HELPER=$(get_aur_helper)

# Then install other packages
section_header "Installing System Packages"
install_pacman_packages

# Install non-gaming Flatpak applications
section_header "Installing Flatpak Applications"
install_flatpaks

# Ask for gaming package installation
section_header "Gaming Package Selection"
select_gaming_packages

# Remove GNOME packages
section_header "Removing GNOME Packages"
remove_gnome_packages

# Install GNOME extensions
section_header "Installing GNOME Extensions"
install_gnome_extensions

# Install themes
section_header "Installing Themes"
install_themes

# Show summary
section_header "Installation Summary"
show_summary

echo -e "\n${GREEN}${BOLD}✨ Installation process completed successfully! ✨${NC}\n"

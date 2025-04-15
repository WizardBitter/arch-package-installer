# Arch Linux Package Installer Script

A robust Bash script to automate package installations on Arch Linux. Customize package selections by modifying the arrays within the script.

## Features

- Installs packages from official Arch Linux repositories, AUR (via `paru` or `yay`), and Flatpak
- Optional installation of gaming-related packages
- Colorful terminal output with detailed logging
- Verifies system requirements before execution
- Optimizes mirror selection for faster downloads

## Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/WizardBitter/arch-package-installer.git
   ```
2. Navigate to the script directory:
   ```bash
   cd arch-package-installer
   ```
3. Make the script executable:
   ```bash
   chmod +x installpacks.sh
   ```
4. Customize package lists (optional):
   - Open `installpacks.sh` in a text editor.
   - Edit package arrays at lines **314–320** (core packages) and **325-330** (Flatpak packages) to include or exclude desired packages.
5. Run the script:
   ```bash
   ./installpacks.sh
   ```
6. Follow the interactive prompts to select installation options.

### Supported Installations

- **System Packages**: Utilities like `7zip`, `firefox`, and more
- **Development Tools**: Compilers, IDEs, and version control systems
- **Multimedia Apps**: Media players, editors, and codecs
- **System Utilities**: Disk management, monitoring tools, and tweaks
- **Flatpak Applications**: Cross-platform apps via Flatpak
- **Gaming Packages** (optional): Steam, Wine, and gaming dependencies

### Logging

Installation details are logged to:
- `/tmp/installpacks.log` (general output)
- `/tmp/installpacks_error.log` (error messages)

## Notes

- Ensure `yay` or `paru` is installed for AUR package support
- An active internet connection is required.
- Review the script before running to confirm package selections align with your needs.

# My SwayWM Configuration

This is my personal repository for my configuration files (dotfiles) for [Sway](https://swaywm.org/), an i3-compatible tiling Wayland compositor.

This configuration is designed to be lightweight, functional, and aesthetic, with tight integration between key components for a cohesive desktop experience.


---

## Key Features

* **Dynamic Theming**: Uses **[wallust](https://github.com/wallust/wallust)** to automatically generate a color palette from your wallpaper. This theme is then applied to Waybar and other components.
* **Modern Status Bar**: A custom configuration for **[Waybar](https://github.com/Alexays/Waybar)** that displays system information, workspaces, time, and more in a clean style.
* **Fast App Launcher**: Uses **[fuzzel](https://codeberg.org/dnkl/fuzzel)** as the primary application launcher, a modern dmenu/rofi replacement for Wayland.
* **Notification Center**: Uses **[swaync](https://github.com/ErikReider/swaync)** for advanced notification management, complete with a "Do Not Disturb" mode and history panel.

---

## Dependencies

Here are the main components required for this configuration to work properly.

* **Window Manager**: `sway`
* **Wallpaper**: `swaybg` (or `swww`)
* **Status Bar**: `waybar`
* **App Launcher**: `fuzzel`
* **Notification Daemon**: `swaync`
* **Theming Engine**: `wallust`
* **Terminal**: (e.g., `kitty`, `alacritty`, or `foot`)
* **Font**: A **Nerd Font** (e.g., [JetBrainsMono Nerd Font](https://www.nerdfonts.com/)) is highly recommended to display icons correctly on Waybar.

---

## 🚀 Installation

1.  **Clone this repository:**
    ```bash
    # It's best to clone into your .config directory
    git clone [https://github.com/YOUR_USERNAME/YOUR_REPO_NAME](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME) ~/.config/sway-dotfiles
    ```

2.  **Install all dependencies** listed above using your package manager.

    *Example for Arch Linux:*
    ```bash
    sudo pacman -S sway waybar fuzzel swaync wallust swaybg ttf-jetbrains-mono-nerd
    ```

    *Example for Debian/Ubuntu (some packages may need a PPA or manual build):*
    ```bash
    sudo apt install sway waybar swaybg fonts-jetbrains-mono
    # Note: fuzzel, swaync, and wallust may need to be built from source
    # or installed from third-party repositories on Debian/Ubuntu.
    ```
    
    *(After installation, you will need to manually move or symlink the configuration folders from `~/.config/sway-dotfiles` to their respective locations in `~/.config/`)*

---

## ⌨️ Main Keybindings (Example)



* `$mod + Return`: Opens a terminal
* `$mod + d`: Opens **fuzzel** (app launcher)



<img width="1917" height="1079" alt="screenshot-20251005-223818" src="https://github.com/user-attachments/assets/d95be6d0-76ac-4ddd-aca4-a35b7358b684" />

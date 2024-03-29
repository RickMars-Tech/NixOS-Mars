# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ 
    config,
    pkgs,
    lib,
    inputs,
    ... 
}: let

  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz";

  unstable = import (builtins.fetchTarball https://github.com/nixos/nixpkgs/tarball/nixos-unstable) { config = config.nixpkgs.config; };

in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      (import "${home-manager}/nixos")
    ];

#=> Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.consoleMode = "auto";
  boot.plymouth.enable = true;

#=> Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest; # Latest Kernel
  boot.kernelParams = [
    "amdgpu.noretry=0"
    "amdgpu.dc=1"
    "amdgpu.dpm=1"
    "amd_iommu=on"
    "amdgpu.ppfeaturemask=1"
    "amdgpu.exp_hw_support=1"
    "rcu_nocbs=0-15"
    "amdgpu.sg_display=0"
    "amdgpu.vm_fragment_size=9"
    "radeon.si_support=0"
    "amdgpu.si_support=1"
    "radeon.cik_support=0"
    "amdgpu.cik_support=1"
    "nvme_core.default_ps_max_latency_us=2000"
    "nvme_core.io_timeout=500"
    "nvme_core.use_host_mem=1"
    "transparent_hugepage=always"
    "mitigations=auto"
    "quiet"
    "splash"
    "fbcon=nodefer"
    "acpi_rev_override=5"
    "tsc=reliable"
    "clocksource=tsc"
    "kcfi"
    "fbcon=nodefer"
    "vt.global_cursor_default=0"
    "usbcore.autosuspend=-1"
    "video4linux"
    "acpi_rev_override=5"
  ];
  
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;  # A simple change Valve made on the Steam Deck...
    "vm.swappiness" = 10;  # Reduce swappiness since RAM's faster.
    "vm.compaction_proactiveness" = 0;
    "vm.watermark_boost_factor" = 1;
    "vm.zone_reclaim_mode" = 0;
    "vm.page_lock_unfairness" = 1;
    "kernel.sysrq" = 1;
  };

  boot.tmp.cleanOnBoot = true;
  boot.extraModprobeConfig = "options kvm_amd nested=1"; # AMD
  boot.supportedFilesystems = [ "ntfs" ];
  boot.initrd.kernelModules = [ "amdgpu" "radeon" "zenpower" "vmd" "xhci_pci" "ahci" "usbhid" "sd_mod" "mq-deadline" ]; # 
  boot.blacklistedKernelModules = [ "k10temp" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ 
      zenpower
  ];

#==> SystemD <==#

  systemd.extraConfig = ''
      [Process]
      Name=bit.trip.runner
      Priority=10
      Interactive=true
      ...
      [Process]
      Name=wineserver
      Priority=20
      Fixed=true
      NegativePriority=19
      ...
      [Process]
      Name=steam.exe
      Priority=10
      Interactive=true
      NegativePriority=5
      ...
      DefaultTimeoutStopSec=10s
      ...
      DefaultLimitNOFILE=524288
    '';

  systemd.user.extraConfig = ''
      DefaultLimitNOFILE=524288
    '';

#==> User and Home Manager <==#
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = {  };
  home-manager.users.rick = {
    home.stateVersion = "23.11";
  # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;
    home.username = "rick";
    home.homeDirectory = "/home/rick";

#= Gnome Config
  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    settings."org/gnome/desktop/interface".font-name = "Montserrat";
    settings."org/gnome/desktop/wm/preferences".button-layout = ":minimize,maximize,close";
    settings."org/gnome/desktop/interface".clock-format = "12h";
    settings."org/gnome/desktop/interface".clock-show-date = false;
    settings."org/gnome/mutter".center-new-windows = true;
    settings."org/gnome/desktop/interface".enable-hot-corners = false;
    settings."org/gnome/mutter".edge-tiling = true;
    settings."org/gnome/desktop/session".idle-delay = false;
    settings."org/gnome/desktop/peripherals/touchpad".disable-while-typing = false;
    settings."org/gnome/desktop/peripherals/touchpad".accel-profile = "flat";
    settings."org/gnome/desktop/peripherals/touchpad".click-method = "areas";
    settings."org/gnome/desktop/peripherals/touchpad".edge-scrolling-enabled = false;
    settings."org/gnome/desktop/peripherals/touchpad".tap-to-click = true;
    settings."org/gnome/desktop/peripherals/touchpad".natural-scroll = false;
    settings."org/gnome/desktop/peripherals/touchpad".two-finger-scrolling-enabled = true;
    settings."org/gnome/desktop/interface".show-battery-percentage = true;
    settings."org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";
    settings."org/gnome/settings-daemon/plugins/power".sleep-inactive-battery-timeout = "nothing";
    settings."org/gnome/settings-daemon/plugins/power".idle-dim = false;
    settings."org/gnome/desktop/search-providers".disabled = "['org.gnome.Software.desktop']";
    settings."org/gnome/shell".disable-user-extensions = false;
    settings."org/gnome/shell".enabled-extensions = [
      "appindicatorsupport@rgcjonas.gmail.com"
      "blur-my-shell@aunetx"
      "dash-to-dock@micxgx.gmail.com"
      "gmind@tungstnballon.gitlab.com"
    ];
  };

  #= Cursor
    home.pointerCursor = {
      gtk.enable = true;
      # x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 16;
    };

  #= GTK
    gtk = {
      enable = true;
      theme = {
        package =  pkgs.adw-gtk3;
        name = "Adwaita-Dark";
      };

      iconTheme = {
        package = pkgs.papirus-icon-theme;
        name = "ePapirus-Dark";
      };
    };

  #= QT
    qt.enable = true;

    # platform theme "gtk" or "gnome"
    qt.platformTheme = "gnome";

    # name of the qt theme
    qt.style.name = "adwaita-dark";

    # detected automatically:
    # adwaita, adwaita-dark, adwaita-highcontrast,
    # adwaita-highcontrastinverse, breeze,
    # bb10bright, bb10dark, cde, cleanlooks,
    # gtk2, motif, plastique

    # package to use
    qt.style.package = pkgs.adwaita-qt;
  };

  #= Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.rick = {
    isNormalUser = true;
    description = "Rick";
    extraGroups = [
      "wheel" # enable 'sudo'
      "root"
      "video"
      "audio"
      "render"
      "games" # Access to some game software. /var/games.
      "gamemode" # Required for 'renicing' via gamemode.
      "storage" # Used to gain access to removable drives such as USB hard drives.
      "disk"
      "libvirt"
      "flatpak"
      "networkmanager"
      "kvm"
      "qemu"
      "input"
    ];
    shell = pkgs.fish; #pkgs.zsh;
    packages = with pkgs; [ ];
  };

  #=> Fonts Config
  fonts = {
    packages = with pkgs; [
      noto-fonts
      montserrat
      (nerdfonts.override { fonts = [ "DaddyTimeMono" "Meslo" "JetBrainsMono" "UbuntuMono" ]; })
      source-han-sans
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
      monospace = [ "DaddyTimeMono Nerf Font Propo" ];
      serif = [ "Noto Serif" "Source Han Serif" ];
      sansSerif = [ "Noto Sans" "Source Han Sans" ];
      };
    };
  };

  # Set your time zone.
  time.timeZone = "America/Chihuahua";

  # Select internationalisation properties.
  i18n.defaultLocale = "es_MX.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_MX.UTF-8";
    LC_IDENTIFICATION = "es_MX.UTF-8";
    LC_MEASUREMENT = "es_MX.UTF-8";
    LC_MONETARY = "es_MX.UTF-8";
    LC_NAME = "es_MX.UTF-8";
    LC_NUMERIC = "es_MX.UTF-8";
    LC_PAPER = "es_MX.UTF-8";
    LC_TELEPHONE = "es_MX.UTF-8";
    LC_TIME = "es_MX.UTF-8";
  };

#==> Services <==#

#= Power Management
  services.tlp.enable = true;
  services.tlp.settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

    CPU_DRIVER_OPMODE_ON_AC = "performance";
    CPU_DRIVER_OPMODE_ON_BAT = "active";

    CPU_MIN_PERF_ON_AC = 0;
    CPU_MAX_PERF_ON_AC = 100;
    CPU_MIN_PERF_ON_BAT = 0;
    CPU_MAX_PERF_ON_BAT = 20;
  };
 services.power-profiles-daemon.enable = false;

#= Thermal CPU Management
  services.thermald.enable = true;

#= Chrony
  services.chrony.enable = true;
  services.chrony.package = unstable.pkgs.chrony;

#= Enable Flatpak
  services.flatpak.enable = true;


##==>> GNOME <<==## 

  nixpkgs.overlays = [
    (final: prev: {
        gnome = prev.gnome.overrideScope' (gnomeFinal: gnomePrev: {
            mutter = gnomePrev.mutter.overrideAttrs ( old: {
                src = pkgs.fetchgit {
                    url = "https://gitlab.gnome.org/vanvugt/mutter.git";
                    # GNOME 45: Triple-Buffering-V4-45
                    rev = "0b896518b2028d9c4d6ea44806d093fd33793689";
                    sha256 = "sha256-mzNy5GPlB2qkI2KEAErJQzO//uo8yO0kPQUwvGDwR4w=";
                };
            });
        });
    })
  ];
  nixpkgs.config.allowAliases = false;
  services.gvfs.enable = true;
  services.sysprof.enable = true;

#= Greetd
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

#= Enable the GNOME Desktop Environment.
  services.xserver.desktopManager.gnome.enable = true;

#= X.ORG/X11
  services.xserver = {
    enable = true;
    updateDbusEnvironment = true;
    videoDrivers = [ "amdgpu" ];
    libinput = {
        enable = true;
        touchpad = {
            disableWhileTyping = false;
            tapping = false;
            dev = "/dev/input/platform-AMDI0010:00-event-mouse";
        };
    };
    layout = "es";
    xkbVariant = "nodeadkeys";
    excludePackages = [ pkgs.xterm ];
  };

#= Configure console keymap
  console.keyMap = "es";
  console.packages = with pkgs; [ terminus-nerdfont ];

#= Printers
  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    gutenprint
    gutenprintBin
    hplip
  ];

#= FWUPD
  services.fwupd.enable = true;

#= Dbus
  services.dbus = {
    enable = true;
    apparmor = "enabled";
    implementation = "broker"; 
    packages = with pkgs; [ flatpak gcr gnome.gnome-settings-daemon ];
  };

#= Pipewire
  sound.enable = true;
  security.rtkit.enable = true; # Real-Time Priority to Processes.
  services.pipewire = {
    enable = true;
    audio.enable = true; # Use as primary sound server
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
    package = unstable.pkgs.pipewire;
  };
   

#=> PROGRAMS <=#

#= Firefox
  programs.firefox = {                  
    enable = true;
    preferences = {
      "widget.use-xdg-desktop-portal.file-picker" = 1;
      "widget.use-xdg-desktop-portal.mime-handler" = 1;
      "browser.download.animateNotifications" = false;
      "security.dialog_enable_delay" = false;
      "network.prefetch-next" = false;
      "browser.newtabpage.activity-stream.feeds.telemetry" = false;
      "browser.newtabpage.activity-stream.telemetry" = false;
      "browser.ping-centre.telemetry" = false;
      "toolkit.telemetry.archive.enabled" = false;
      "toolkit.telemetry.bhrPing.enabled" = false;
      "toolkit.telemetry.enabled" = false;
      "toolkit.telemetry.firstShutdownPing.enabled" = false;
      "toolkit.telemetry.hybridContent.enabled" = false;
      "toolkit.telemetry.newProfilePing.enabled" = false;
      "toolkit.telemetry.reportingpolicy.firstRun" = false;
      "toolkit.telemetry.shutdownPingSender.enabled" = false;
      "toolkit.telemetry.unified" = false;
      "toolkit.telemetry.updatePing.enabled" = false;
      "privacy.trackingprotection.fingerprinting.enable" = true;
      "privacy.trackingprotection.cryptomining.enable" = true;
      "privacy.trackingprotection.enable" = true;
      "browser.send_pings" = false;
      "browser.sessionstore.privacy_level" = 2;
      "browser.safebrowsing.downloads.remote.enabled" = false;
      "browser.pocket.enabled" = false;
      "loop.enabled" = false;
      "fission.autostart" = true;
      "reader.parse-on-load.enabled" = false;
      "reader.parse-on-load.force-enabled" = false;
      "beacon.enabled" = false;
      "webgl.disabled" = false;
      "gfx.webrender.all" = true;
      "dom.event.clipboardevents.enabled" = false;
      "media.navigator.enabled" = false;
      "network.cookie.cookieBehavior" = 1;
    };
    languagePacks = [ "es-MX" ];
    package = pkgs.firefox;
  };

#= Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = true;
    package = unstable.pkgs.neovim-unwrapped;
    configure = {
      customRC = ''
        syntax on
        set ignorecase
        set smartcase
        set encoding=utf-8
        set number relativenumber

        " Autocompletion
        set wildmode=longest,list,full

        " Use system Clipboard
        set clipboard+=unnamedplus

        " Lines Number
        set number

        " Tab Settings
        set expandtab
        set shiftwidth=4
        set softtabstop=4
        set tabstop=4

        set path=.,,**
      '';
      packages.myVimPlugins = with pkgs.vimPlugins; {
        start = [
          indentLine
          vim-lastplace 
          vim-nix
          vim-plug
          vim-sensible
        ]; 
        opt = [];
      };
    };
  };

#= Java
  programs.java = {
    enable = true;
    package = pkgs.jdk;
    binfmt = true;
  };

#=> Shell's

#= Fish

  programs.fish = {
    enable = true;
    useBabelfish = true;
    promptInit = "set fish_greeting";
    shellAliases = {
      grep = "rg --color=auto";
      cat = "bat --style=plain --paging=never";
      ls = "eza --group-directories-first --grid --icons";
      tree = "eza -T --all --icons";
      ll = "eza -l --all --octal-permissions --icons";
      search = "fzf";
      cd = "z";
    };
    interactiveShellInit = "
    fastfetch

    zoxide init fish | source
    ";
    vendor = {
      config.enable = true;
      completions.enable = true;
      functions.enable = true;
    };
  };
  programs.nix-index.enableFishIntegration = true;

#= Starship
  programs.starship.enable = true;
  programs.starship.settings = {
    add_newline = true;

    character = {
        success_symbol = "[<0> ~](bold green)";
        error_symbol = "[<0> ~](bold red)";
    };

    shell = {
        disabled = false;
        format = "$indicator";
        fish_indicator = "(bright-white) ";
        bash_indicator = "(bright-white) ";
    };

    nix_shell = {
      symbol = "";
      format = "[$symbol$name]($style) ";
      style = "bright-purple bold";
    };

    package.disabled = true;
    };

#= XWayland
  programs.xwayland.enable = true;

#==>~HYPRLAND~<==#

  programs.hyprland = {
    enable = true;
    portalPackage = unstable.pkgs.xdg-desktop-portal-hyprland;
    enableNvidiaPatches = false; # false if you use a AMD GPU
    xwayland.enable = true;
    package = pkgs.hyprland;
  };

#= Top Bar
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    });
  };

#= File Managers
  # Yazi
  programs.yazi = {
    enable = true;
    package = unstable.pkgs.yazi;
  };
  # Nautilus
  services.gnome.sushi.enable = true;

#=> Appimages
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
    magicOrExtension = ''\x7fELF....AI\x02'';
  };

#==> NIX/NIXPKGS <==#

#= Enable Nix-Shell and Flakes
  nix = {
    settings = {
      warn-dirty = true;
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = ["rick"];
    };
  };

#= Run unpatched dynamic binaries on NixOS
  programs.nix-ld.enable = true;
  programs.nix-ld.package = unstable.pkgs.nix-ld;
  programs.nix-ld.libraries = with pkgs; [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    curl
    dbus
    expat
    fontconfig
    freetype
    fuse3
    gdk-pixbuf
    glib
    gtk3
    icu
    libGL
    libappindicator-gtk3
    libdrm
    libglvnd
    libnotify
    libpulseaudio
    libunwind
    libusb1
    libuuid
    libxkbcommon
    libxml2
    mesa
    nspr
    nss
    openssl
    pango
    pipewire
    stdenv.cc.cc
    systemd
    vulkan-loader
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
    xorg.libxkbfile
    xorg.libxshmfence
    zlib
  ];

#= Allow unfree packages
  nixpkgs.config.allowUnfree = true;

#=> Packages Installed in System Profile.
environment.systemPackages = with pkgs; [
#= GNOME
    gnome-extension-manager
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.blur-my-shell
    gnomeExtensions.gamemode-indicator-in-system-settings
    gnomeExtensions.vitals
    gnome.gnome-tweaks
    gnome.gnome-calculator
    gnome.dconf-editor
    gnome.eog
    gnome.nautilus
    #Clipboard-specific
    wl-clipboard
    # XWayland/Wayland
    unstable.glfw-wayland
    unstable.wayland-utils
    unstable.xwayland
    unstable.xwaylandvideobridge
#= Hyprland
     #=> Hyprland
    # Terminal
    unstable.kitty
    # Top bar
    #waybar
    #waybar-mpris
    # Main
    #hyprland
    unstable.hyprland-protocols
    unstable.hyprland-per-window-layout
    unstable.hyprland-autoname-workspaces
    unstable.wayland-utils
    unstable.hyprcursor # The hyprland cursor format, library and utilities
    unstable.hypridle
    unstable.hyprlock
    # Wayland - Kiosk. Used for login_managers
    cage
    # Notification Deamon
    dunst
    libnotify
    notify
    # Wallpaper
    unstable.hyprpaper
    # App-Launcher
    rofi-wayland
    # Applets
    networkmanagerapplet
    # Screen-Locker
    wlogout
    # Idle manager
    swayidle # required by the screen locker
    #Clipboard-specific
    wl-clipboard
    # An xrandr clone for wlroots compositors
    wlr-randr
    # Screenshot
    unstable.grimblast # Taking
    unstable.slurp # Selcting
    swappy # Editing
#= Polkit
    polkit
    libsForQt5.polkit-kde-agent
#= Filemanagers
    gnome.nautilus
    # Image Viewer
    imv
    # Theme's
    adwaita-qt6
    qgnomeplatform-qt6
    qgnomeplatform
    tokyo-night-gtk
    # XWayland/Wayland
    unstable.glfw-wayland
    unstable.xwayland
    unstable.xwaylandvideobridge
#= Main
    alsa-plugins
    alsa-utils
    libsForQt5.ark
    clamtk
    webcord
    electron
    libportal
    libsForQt5.qt5ct
    libstdcxx5
    unstable.linuxHeaders
    python3
    qt5.qtwayland
    qt6.qtwayland
    sysprof
    usbutils
    wget
    libreoffice
    yarn
#= Cli Utilities
    babelfish
    bat
    dunst
    unstable.eza
    unstable.zoxide
    unstable.fzf
    unstable.ripgrep
    unstable.fastfetch
    unstable.kitty
    git
    skim
#= Archives
    zip
    unzip
    gnutar
    rar
    unrar
#= Torrent
    frostwire-bin
    rqbit
#= Waydroid
    lzip
#= Rust
    cargo # PM for rust
    rustup # Rust toolchain installer
#= Drives utilities
    gnome.gnome-disk-utility # Disk Manager
    etcher # Flash OS images for Linux and another...
    woeusb # Flash OS images for Windows.
#= Flatpak
    libportal
    libportal-qt5
    zip
#= Graph manager dedicated for PipeWire
    pavucontrol # Pulseaudio Volume Control
#= Appimages
    appimagekit
    appimage-run
#= TOR
    #obfs4
    #tor-browser
#= Virtualization
    virt-manager
    virt-viewer
    virtio-win
    qemu_kvm
    spice spice-gtk
    spice-protocol
    win-spice
#= Image Editors
    krita
    gimp-with-plugins
#= Video/Audio Tools
    olive-editor # Professional open-source NLE video editor
    (unstable.pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
        obs-vkcapture
        obs-gstreamer
        obs-vaapi
      ];
    })
#= GStreamer and codecs
    # Video/Audio data composition framework tools like "gst-inspect", "gst-launch" ...
    gst_all_1.gstreamer
    gst_all_1.gstreamermm # C++ interface for GStreamer
    # Common plugins like "filesrc" to combine within e.g. gst-launch
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-rs # Written in Rust
    # Specialized plugins separated by quality
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    # Plugins to reuse ffmpeg to play almost every video format
    gst_all_1.gst-libav
    # Support the Video Audio (Hardware) Acceleration API
    gst_all_1.gst-vaapi
    # Library for creation of audio/video non-linear editors
    gst_all_1.gst-editing-services
    # H.264 encoder/decoder plugin for mediastreamer2
    mediastreamer-openh264
    # H264/AVC 
    x264 
    # H.265/HEVC
    x265
    # WebM VP8/VP9 codec SDK
    libvpx
    # Vorbis audio compression
    libvorbis
    # Open, royalty-free, highly versatile audio codec
    libopus
    # MPEG
    lame
    # A library for decrypting DVDs
    libdvdcss
    # PNG
    libpng
    # JPEG
    libjpeg
    # FFMPEG
    ffmpeg
    ffmpeg-headless
    ffmpegthumbnailer
#= Media Player
    mpv
#= AMD P-STATE EPP
    amdctl
#= Vulkan
    unstable.vulkan-headers
    unstable.vulkan-loader
    unstable.vulkan-tools
    unstable.vulkan-tools-lunarg
    unstable.vulkan-validation-layers
    unstable.vulkan-extension-layer
    unstable.vkdisplayinfo
    unstable.vkd3d-proton
    unstable.vk-bootstrap
#= PC monitoring
    stacer # Linux System Optimizer and Monitoring.
    clinfo
    glxinfo
    hardinfo
    htop-vim
    lm_sensors
    # gaming monitoring
    goverlay
    mangohud
    vkbasalt
#= Wine
    # support both 32- and 64-bit applications
    unstable.wineWowPackages.stagingFull
    samba
#= The best Game in the World
    superTuxKart
#= Steam Utils
    winetricks
    protontricks
    protonup-qt
#= Lutris
    lutris-unwrapped
#= OpenSource Minecraft Launcher
    glfw-wayland-minecraft
    (prismlauncher.override { jdks = [ jdk19 jdk17 jdk8 ]; })
#= Launcher for Veloren.
    airshipper
  ];

  nixpkgs.config.permittedInsecurePackages = [ "electron-19.1.9" ];

#= Remove GNOME Bloatware
  services.gnome.core-utilities.enable = false;

##==> GAMING <==##

#= Ananicy
  services.ananicy.enable = true;
  services.ananicy.package = pkgs.ananicy-cpp;
  services.ananicy.rulesProvider = pkgs.ananicy-rules-cachyos;

#=> Gamescope
  programs.gamescope = {
    enable = true;
    package = unstable.pkgs.gamescope;
    capSysNice = false;
  };

#=> Gamemode
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        amd_performance_level = "high";
      };
      cpu = {
        park_cores = "no";
        pin_cores = "yes";
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode Started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode Ended'";
      };
    };
  };

#=> Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

#=> Vulkan, Codecs and more... 
  hardware.cpu.amd.updateMicrocode = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true; 
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages = with pkgs; [
    unstable.amdvlk
    unstable.libdrm
    mesa.drivers
    mesa.llvmPackages.llvm.lib
    #vaapiIntel
    vaapiVdpau
    vdpauinfo
    libvdpau
    libvdpau-va-gl
    #intel-media-driver
  ]; 
  hardware.opengl.extraPackages32 = with pkgs.driversi686Linux; [
    unstable.amdvlk
    mesa.drivers
    mesa.llvmPackages.llvm.lib
    glxinfo
    vaapiVdpau
    vdpauinfo
    libvdpau-va-gl
    #intel-media-driver
  ];
  hardware.opengl.setLdLibraryPath = true;
  hardware.steam-hardware.enable = true;
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true; # Lemme update my CPU Microcode, alr?!
  hardware.pulseaudio.enable = false;

#==> Environment Configs <==#

  environment = {
    pathsToLink = [ "/share/X11" "/libexec" "/share/nix-ld" ];
    sessionVariables = rec {
#=> Default's
      EDITOR = "nvim";
      BROWSER = "firefox";
      TERMINAL = "kitty";
#=> Enable touch-scrolling in Mozilla software
      MOZ_USE_XINPUT2 = "1";
#=> JAVA
      _JAVA_AWT_WM_NONREPARENTING = "1";
#=> RADV
      AMD_VULKAN_ICD = "RADV"; # Force radv
      RADV_PERFTEST = "aco"; # Force aco
#=> Steam
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
#=> Wayland
      NIXOS_OZONE_WL = "1";
      OZONE_PLATFORM = "wayland";
      WLR_RENDERER = "vulkan";
      WLR_NO_HARDWARE_CURSORS = "1";
      MOZ_ENABLE_WAYLAND = "1";
      SDL_VIDEODRIVER = "wayland";
#=> Flatpak
      FLATPAK_GL_DRIVERS = "mesa-git";
    };
  };

#=> Storage Options
  nix.optimise.automatic = true;
  #https://github.com/nix-community/nix-direnv
  programs.direnv = {
    enable = true;
    package = pkgs.direnv;
    silent = false;
    loadInNixShell = true;
    direnvrcExtra = "";
    nix-direnv = {
      enable = true;
      package = pkgs.nix-direnv;
    };
  };


#= Enable Trim Needed for SSD's
  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";

#= Swap
  zramSwap = {
      enable = true;
      priority = 80;
      memoryPercent = 50;
      algorithm = "zstd";
      swapDevices = 2;
  };

  #==> Network and Security <==#

  networking = {
    networkmanager.enable = true;
    hostName = "razor-crest"; # Define your hostname.
    firewall = {
      enable = true;
      allowedTCPPorts = [
        53
        80
        443
        631
        3478
        3479
        8080
      ];
    };
    enableIPv6 = false;
  };

#= Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

# Fail2Ban
  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "9.9.9.11"
      "149.112.112.11"
      "2620:fe::11"
      "2620:fe::fe:11"
    ];
    maxretry = 5;
    bantime = "1h";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  #system.copySystemConfiguration = true;
  #system.autoUpgrade.enable = true;
  #system.autoUpgrade.allowReboot = false;
  #system.autoUpgrade.channel = "https://nixos.org/channels/nixos-23.11";

  documentation.nixos.enable = true;
}

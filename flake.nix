{
  description = "Zen Browser";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      version = "1.22.3b";
      download.url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-x86_64.tar.xz";
	    download.sha256 = "17vdv71q439nv5rgnfa4zcl7rzxaw6xv871rff3mlgq2dpwdgh9h";

      pkgs = import nixpkgs {
        inherit system;
      };

      runtimeLibs = with pkgs; [
        libGL libGLU libevent libffi libjpeg libpng libstartup_notification libvpx libwebp
        stdenv.cc.cc fontconfig libxkbcommon zlib freetype
        gtk3 libxml2 dbus xcb-util-cursor alsa-lib libpulseaudio pango atk cairo gdk-pixbuf glib
	udev libva mesa libnotify cups pciutils
	ffmpeg libglvnd pipewire
        libxcb libX11 libXcursor libXrandr libXi libXext libXcomposite libXdamage
	libXfixes libXScrnSaver
      ];

    mkZen = pkgs.stdenv.mkDerivation {
      inherit version;
		  pname = "zen-browser";

      src = fetchTarball {
        url = download.url;
        sha256 = download.sha256;
      };
		
		  desktopSrc = self;

		  phases = [ "installPhase" "fixupPhase" ];

		  nativeBuildInputs = [ pkgs.makeWrapper pkgs.copyDesktopItems pkgs.wrapGAppsHook3 ] ;

      installPhase = ''
        mkdir -p $out/bin && cp -r $src/* $out/bin
        install -D $desktopSrc/zen.desktop $out/share/applications/zen.desktop
        install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png
      '';

      fixupPhase = ''
        chmod 755 $out/bin/*
        for bin in $out/bin/*; do
          [ -f "$bin" ] || continue
          patchelf --print-interpreter "$bin" >/dev/null 2>&1 || continue
          patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$bin"
          if [ "$bin" = "$out/bin/zen" ] || [ "$bin" = "$out/bin/zen-bin" ]; then
            wrapProgram "$bin" --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}" \
              --set MOZ_LEGACY_PROFILES 1 --set MOZ_ALLOW_DOWNGRADE 1 --set MOZ_APP_LAUNCHER zen --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
          else
            wrapProgram "$bin" --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
          fi
        done
      '';

      meta.mainProgram = "zen";
	  };
    in
    {
      packages."${system}" = {
        zen-browser = mkZen;
	      default = self.packages."${system}".zen-browser;
      };
    };
}

{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      version = "4.3-dev6";
      godot-stable = pkgs.fetchurl {
        url = "https://github.com/godotengine/godot-builds/releases/download/${version}/Godot_v${version}_linux.x86_64.zip";
        hash = "sha256-FBABKXKUtDpmlbVdcDIqm45QlrIhPE7n33e1l6+gVG0=";
      };

      buildInputs = with pkgs; [
        alsa-lib
        dbus
        fontconfig
        libGL
        libpulseaudio
        libxkbcommon
        makeWrapper
        mesa
        patchelf
        speechd
        udev
        vulkan-loader
        xorg.libX11
        xorg.libXcursor
        xorg.libXext
        xorg.libXfixes
        xorg.libXi
        xorg.libXinerama
        xorg.libXrandr
        xorg.libXrender
        wayland-utils
        wayland-scanner
      ];

      godot-unwrapped = pkgs.stdenv.mkDerivation {
        pname = "godot";
        version = "4.3-dev6";

        src = godot-stable;
        nativeBuildInputs = with pkgs; [unzip autoPatchelfHook];
        buildInputs = buildInputs;

        dontAutoPatchelf = false;

        unpackPhase = ''
          mkdir source
          unzip $src -d source
        '';

        installPhase = ''
          mkdir -p $out/bin
          cp source/Godot_v${version}_linux.x86_64 $out/bin/godot
        '';
      };

      godot-bin = pkgs.buildFHSUserEnv {
        name = "godot";
        targetPkgs = pkgs: buildInputs ++ [godot-unwrapped];
        runScript = "godot";
      };
    in {
      devShell = pkgs.mkShell {
        buildInputs = [godot-bin];
      };
    });
}

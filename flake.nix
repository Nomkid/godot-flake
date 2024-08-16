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

      # version = "4.3-stable";
      # godot-stable = pkgs.fetchurl {
      #   url = "https://github.com/godotengine/godot-builds/releases/download/${version}/Godot_v${version}_linux.x86_64.zip";
      #   hash = "sha256-feVkRLEwsQr4TRnH4M9jz56ZN+5LqUNkw7fdEUJTyiE=";
      # };

      commitHash = "77dcf97d82cbfe4e4615475fa52ca03da645dbd8";

      buildInputs = with pkgs; [
        wayland-utils
        wayland-scanner
        libdecor
      ];

      godot-bin = pkgs.godot_4.overrideAttrs (prev: {
        version = "4.3.0";
        inherit commitHash;
        src = pkgs.fetchFromGitHub {
          owner = "godotengine";
          repo = "godot";
          rev = commitHash;
          hash = "sha256-v2lBD3GEL8CoIwBl3UoLam0dJxkLGX0oneH6DiWkEsM=";
        };

        buildInputs = buildInputs ++ prev.buildInputs;
        runtimeDependencies = buildInputs ++ prev.runtimeDependencies;
      });

      # godot-unwrapped = pkgs.stdenv.mkDerivation {
      #   pname = "godot";
      #   version = "4.3-beta1";

      #   src = godot-stable;
      #   nativeBuildInputs = with pkgs; [unzip autoPatchelfHook];
      #   buildInputs = buildInputs;

      #   dontAutoPatchelf = false;

      #   unpackPhase = ''
      #     mkdir source
      #     unzip $src -d source
      #   '';

      #   installPhase = ''
      #     mkdir -p $out/bin
      #     cp source/Godot_v${version}_linux.x86_64 $out/bin/godot
      #   '';
      # };

      # godot-bin = pkgs.buildFHSUserEnv {
      #   name = "godot";
      #   targetPkgs = pkgs: buildInputs ++ [godot-unwrapped];
      #   runScript = "godot";
      # };
    in {
      packages.default = godot-bin;

      devShell = pkgs.mkShell {
        buildInputs = [godot-bin];
      };
    });
}

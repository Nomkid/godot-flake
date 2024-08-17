{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
    outputs = flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      env = pkgs.stdenvNoCC;

      version = "4.3-stable";
      # commitHash = "77dcf97d82cbfe4e4615475fa52ca03da645dbd8";
      
      godot-builds = pkgs.fetchFromGitHub {
        owner = "godotengine";
        repo = "godot-builds";
        rev = version;
        hash = "sha256-6PxNHWtcqVzXOvMd+jXhUMovQ7uC9rN+TUthsf/qrhc=";
      };

      godot-build-list = env.mkDerivation {
        pname = "godot-build-list";
        inherit version;
        src = godot-builds;
        buildInputs = with pkgs; [jq];
        installPhase = ''
          sources=$(mktemp)
          echo '{' >> $sources
          count=$(ls -l $src/releases | wc -l)
          count=$((count-1))
          i=1
          for filename in $src/releases/*; do
            version=$(jq '.version + "-" + .status' $filename)
            if [ $i = $count ]; then
              echo "$version: $(jq '.files | map( { (.filename): .checksum } ) | add' $filename)" >> $sources
            else
              echo "$version: $(jq '.files | map( { (.filename): .checksum } ) | add' $filename)," >> $sources
            fi
            i=$((i+1))
          done
          echo '}' >> $sources
          jq 'with_entries(select(.value | . != null))' $sources > $out
        '';
      };

      # godot-builder = pkgs.godot_4.overrideAttrs (prev: {
      #   version = "4.3.0";
      #   inherit commitHash;
      #   src = pkgs.fetchFromGitHub {
      #     owner = "godotengine";
      #     repo = "godot";
      #     rev = commitHash;
      #     hash = "sha256-v2lBD3GEL8CoIwBl3UoLam0dJxkLGX0oneH6DiWkEsM=";
      #   };

      #   runtimeDependencies = with pkgs; [
      #     wayland-scanner
      #     libdecor
      #   ] ++ prev.runtimeDependencies;
      # });

      # build = {
      #   editor = godot-builder;
      #   export-templates = godot-builder.override { withTarget = "template_release"; };
      # };

      # bin = {
      #   editor = pkgs.fetchzip {
      #     pname = "editor";
      #     # extension = "zip";
      #     url = "https://github.com/godotengine/godot-builds/releases/download/${version}/Godot_v${version}_linux.x86_64.zip";
      #     hash = "sha256-feVkRLEwsQr4TRnH4M9jz56ZN+5LqUNkw7fdEUJTyiE=";
      #   };
      #   export-templates = pkgs.fetchzip {
      #     pname = "export_templates";
      #     extension = "zip";
      #     url = "https://github.com/godotengine/godot/releases/download/${version}/Godot_v${version}_export_templates.tpz";
      #     hash = "";
      #     # hash = "sha256-eomGLH9lbZhl7VtHTWjJ5mxVt0Yg8LfnAnpqoCksPgs=";
      #   };
      # };

      # mkGodotApp = { pname, version }: let
      #   hi = {};
      # in env.mkDerivation {
      #   inherit pname version;
      # };
      # lib = import ./default.nix { inherit pkgs system; };
      packages = import ./default.nix { inherit pkgs system; };
    in {
      # packages = rec {
      #   editor = bin.editor;
      #   # templates-release = godot-templates-release;
      #   # templates-debug = godot-templates-debug;
      #   default = editor;
      # };

      # devShell = pkgs.mkShell {
      #   buildInputs = [bin.editor];
      # };i

      # packages = {
      #   default = lib.${system}.${version}.editor;
      # };
      
      # editor = builtins.mapAttrs (k: v: v.editor) lib.${system};

      packages = { default = packages.default; };

      by-tag = packages.editor;

      update-sources = godot-build-list;
      # inherit godot-build-list build-list list;
    });
  in {
    
  } // outputs;
}

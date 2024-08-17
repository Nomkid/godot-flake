{
  pkgs ? import <nixpkgs> {},
  system ? builtins.currentSystem,
}: let
  env = pkgs.stdenvNoCC;
  inherit (pkgs) lib;
  sources = builtins.fromJSON (lib.strings.fileContents ./sources.json);

  deps = with pkgs; [
    wayland-scanner
    libdecor
  ] ++ pkgs.godot_4.runtimeDependencies;
  
  mkBin = { url, version, sha512 }: let
    godot = env.mkDerivation {
      pname = "godot-bin";
      inherit version;

      src = pkgs.fetchurl { inherit url sha512; };
      nativeBuildInputs = with pkgs; [unzip autoPatchelfHook];

      dontAutoPatchelf = false;

      unpackPhase = ''
        mkdir source
        unzip $src -d source
      '';

      installPhase = ''
        mkdir -p $out/bin
        cp source/Godot_v${version}_* $out/bin/godot
      '';
    };
  in pkgs.buildFHSUserEnv {
    name = "godot";
    targetPkgs = p: [godot] ++ deps;
    runScript = "godot";
  };

  # TODO remove
  targets = {
    i686-linux = "linux.x86_32";
    x86_64-linux = "linux.x86_64";
    aarch64-linux = "linux.x86_64";

    x86_64-darwin = "macos.universal";
    aarch64-darwin = "macos.universal";

    i686-windows = "win32.exe";
    x86_64-windows = "win64.exe";
    aarch64-windows = "windows_arm64.exe";
  };

  # these map nix-compatible systems to the file extension used in godot exports
  # they differ slightly between some versions so we construct a lookup table here
  target-map = version: let
    v3-2 = {
      i686-linux = "x11.32";
      x86_64-linux = "x11.64";
      x86_64-darwin = "osx.64";
      i686-windows = "win32.exe";
      x86_64-windows = "win64.exe";
    };
    v3-2-4-beta3 = {
      i686-linux = "x11.32";
      x86_64-linux = "x11.64";
      x86_64-darwin = "osx.universal";
      i686-windows = "win32.exe";
      x86_64-windows = "win64.exe";
    };
    v4-0-alpha1 = {
      i686-linux = "linux.32";
      x86_64-linux = "linux.64";
      x86_64-darwin = "osx.universal";
      i686-windows = "win32.exe";
      x86_64-windows = "win64.exe";
    };
    v4-0-alpha15 = {
      i686-linux = "linux.x86_32";
      x86_64-linux = "linux.x86_64";
      x86_64-darwin = "osx.universal";
      i686-windows = "win32.exe";
      x86_64-windows = "win64.exe";
    };
  in
    if (lib.strings.hasPrefix "3." version) then (
      if (lib.strings.hasPrefix "3.2" version) then (
        if (
          lib.strings.hasPrefix "3.2.2" version ||
          lib.strings.hasPrefix "3.2.3" version ||
          version == "3.2.4-beta1" ||
          version == "3.2.4-beta2"
        ) then v3-2 else v3-2-4-beta3
      ) else v3-2-4-beta3
    ) else
    if (lib.strings.hasPrefix "4." version) then (
      if (lib.strings.hasPrefix "4.0" version) then (
        if (lib.strings.hasPrefix "4.0-alpha" version) then (
          if (
            version == "4.0-alpha15" ||
            version == "4.0-alpha16" ||
            version == "4.0-alpha17"
          ) then v4-0-alpha15 else v4-0-alpha1
        ) else v4-0-alpha15
      ) else v4-0-alpha15
    ) else throw "Unknown version ${version}";
in rec {
  editor = builtins.mapAttrs (version: filelist: mkBin (let
    target = builtins.getAttr system (target-map version);
  in {
    url = "https://github.com/godotengine/godot-builds/releases/download/${version}/Godot_v${version}_${target}.zip";
    inherit version;
    sha512 = filelist."Godot_v${version}_${target}.zip";
  })) sources;
  # export-templates = pkgs.fetchurl {
    
  # };

  default = editor.${lib.lists.last (
    builtins.sort
    (x: y: (builtins.compareVersions x y) < 0)
    (builtins.attrNames editor)
  )};
}

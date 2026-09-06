{
  stdenv,
  fetchurl,
  lib,
  unzip,
  ...
}:
stdenv.mkDerivation {
  pname = "sourcemod";
  version = "1.12.0-git7253";

  # Platform-specific source and hash
  src = fetchurl {
    # stable-1.12 branch build, pinned (updated automatically)
    url =
      if stdenv.hostPlatform.isLinux then
        "https://github.com/alliedmodders/sourcemod/releases/download/1.12.0.7253/sourcemod-1.12.0-git7253-linux.tar.gz"
      else
        "https://github.com/alliedmodders/sourcemod/releases/download/1.12.0.7253/sourcemod-1.12.0-git7253-windows.zip";
    sha256 =
      if stdenv.hostPlatform.isLinux then
        "sha256-a7yrmJzaCtqDYA0Nyw9Gr/0WUpsrAu0tuhtbrq8C/bQ="
      else
        "sha256-neWzBuUj0YCpYPgE7h8lz8J0thuDV282OPa6TFtfMKM=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontUnpack = true;

  nativeBuildInputs = if stdenv.hostPlatform.isLinux then [ ] else [ unzip ];

  installPhase =
    if stdenv.hostPlatform.isLinux then
      ''
        runHook preInstall
        mkdir -p $out
        # Upstream tarball has top-level addons/ + cfg/; extract straight into $out
        tar -xzf $src -C $out
        # Create bin/ with symlinks to the actual binary locations
        mkdir -p $out/bin
        ln -s ../addons/sourcemod/scripting/spcomp $out/bin/spcomp
        ln -s ../addons/sourcemod/scripting/spcomp64 $out/bin/spcomp64
        runHook postInstall
      ''
    else
      ''
        runHook preInstall
        mkdir -p $out
        # Upstream zip has top-level addons/ + cfg/; extract straight into $out
        unzip -q $src -d $out
        # Create bin/ with copies to the actual binary locations (Windows uses .exe)
        mkdir -p $out/bin
        cp $out/addons/sourcemod/scripting/spcomp.exe $out/bin/spcomp.exe
        cp $out/addons/sourcemod/scripting/spcomp64.exe $out/bin/spcomp64.exe
        runHook postInstall
      '';

  meta = {
    description = "SourceMod - Source engine scripting and administration";
    homepage = "https://www.sourcemod.net/";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux ++ lib.platforms.windows;
    mainProgram = "spcomp64";
    # Binary release ships both 32-bit (spcomp, .so/.dll) and 64-bit (spcomp64, .so/.dll) artifacts.
  };
}

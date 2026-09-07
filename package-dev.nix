{
  stdenv,
  fetchurl,
  lib,
  unzip,
  ...
}:
stdenv.mkDerivation {
  pname = "sourcemod";
  version = "1.13.0-git7460";

  # Platform-specific source and hash
  src = fetchurl {
    # master/1.13 dev branch build, pinned (updated automatically)
    url =
      if stdenv.hostPlatform.isLinux then
        "https://github.com/alliedmodders/sourcemod/releases/download/1.13.0.7456/sourcemod-1.13.0-git7456-linux.tar.gz"
      else
        "https://github.com/alliedmodders/sourcemod/releases/download/1.13.0.7456/sourcemod-1.13.0-git7456-windows.zip";
    sha256 =
      if stdenv.hostPlatform.isLinux then
        "sha256-9rDtxNb4At/cSSjMsP2f1Xpc01vzGquAjW7RMr+FtQM="
      else
        "sha256-TVB+C+CvNQIY/NdGjXHDL9df4Ou1fQY7C+1ZqzfpVKg=";
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
    description = "SourceMod - Source engine scripting and administration (1.13 dev branch)";
    homepage = "https://www.sourcemod.net/";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux ++ lib.platforms.windows;
    mainProgram = "spcomp64";
    # Binary release ships both 32-bit (spcomp, .so/.dll) and 64-bit (spcomp64, .so/.dll) artifacts.
  };
}

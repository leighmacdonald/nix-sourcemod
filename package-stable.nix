{
  stdenv,
  fetchurl,
  lib,
}:
stdenv.mkDerivation {
  pname = "sourcemod";
  version = "1.12.0-git7253";

  src = fetchurl {
    # stable-1.12 branch build, pinned (matches uncletopia flake.nix pre-extraction)
    url = "https://github.com/alliedmodders/sourcemod/releases/download/1.12.0.7253/sourcemod-1.12.0-git7253-linux.tar.gz";
    sha256 = "sha256-a7yrmJzaCtqDYA0Nyw9Gr/0WUpsrAu0tuhtbrq8C/bQ=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    # Upstream tarball has top-level addons/ + cfg/; extract straight into $out
    # (avoids `mv ./*` which drops dotfiles).
    tar -xzf $src -C $out
    runHook postInstall
  '';

  meta = {
    description = "SourceMod - Source engine scripting and administration";
    homepage = "https://www.sourcemod.net/";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "spcomp64";
    # Binary release ships both 32-bit (spcomp, .so) and 64-bit (spcomp64, .so) artifacts.
  };
}

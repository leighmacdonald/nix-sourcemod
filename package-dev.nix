{
  stdenv,
  fetchurl,
  lib,
}:
stdenv.mkDerivation {
  pname = "sourcemod";
  version = "1.13.0-git7456";

  src = fetchurl {
    # master/1.13 dev-branch build, pinned. 1.13 is dev (may contain
    # breaking changes); 1.12 remains the stable default (see package.nix).
    url = "https://github.com/alliedmodders/sourcemod/releases/download/1.13.0.7456/sourcemod-1.13.0-git7456-linux.tar.gz";
    sha256 = "sha256-9rDtxNb4At/cSSjMsP2f1Xpc01vzGquAjW7RMr+FtQM=";
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
    description = "SourceMod - Source engine scripting and administration (1.13 dev branch)";
    homepage = "https://www.sourcemod.net/";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "spcomp64";
    # Binary release ships both 32-bit (spcomp, .so) and 64-bit (spcomp64, .so) artifacts.
  };
}

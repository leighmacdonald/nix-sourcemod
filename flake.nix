{
  description = "SourceMod 1.12 (stable) + 1.13 (dev) - Source engine scripting and administration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      # Linux packages (native)
      linuxPackages = nixpkgs.legacyPackages.x86_64-linux;

      # Windows cross-compilation packages (mingw-w64)
      windowsPackages = linuxPackages.pkgsCross.mingwW64;

      # Helper to create sourcemod packages for a given platform
      makeSourcemodPackages = pkgs: rec {
        sourcemod_1_12 = pkgs.callPackage ./package-stable.nix { };
        sourcemod_1_13 = pkgs.callPackage ./package-dev.nix { };
        sourcemod_stable = sourcemod_1_12;
        sourcemod_dev = sourcemod_1_13;
        sourcemod = sourcemod_1_12;
      };

      linux = makeSourcemodPackages linuxPackages;
      windows = makeSourcemodPackages windowsPackages;

      # Base outputs for Linux
      linuxOutputs = flake-utils.lib.eachSystem [ "x86_64-linux" ] (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (linux)
            sourcemod_1_12
            sourcemod_1_13
            sourcemod_stable
            sourcemod_dev
            sourcemod
            ;
        in
        {
          packages.sourcemod_1_12 = sourcemod_1_12;
          packages.sourcemod_1_13 = sourcemod_1_13;
          packages.sourcemod_stable = sourcemod_stable;
          packages.sourcemod_dev = sourcemod_dev;
          packages.sourcemod = sourcemod;
          packages.default = sourcemod;

          checks.sourcemod-layout = pkgs.runCommand "sourcemod-layout-check" { } ''
            test -x ${sourcemod}/addons/sourcemod/scripting/spcomp64
            test -d ${sourcemod}/addons/sourcemod/extensions
            test -d ${sourcemod}/addons/sourcemod/plugins
            touch $out
          '';

          checks.sourcemod_1_12-layout = pkgs.runCommand "sourcemod-1-12-layout-check" { } ''
            test -x ${sourcemod_1_12}/addons/sourcemod/scripting/spcomp64
            test -d ${sourcemod_1_12}/addons/sourcemod/extensions
            test -d ${sourcemod_1_12}/addons/sourcemod/plugins
            touch $out
          '';

          checks.sourcemod_1_13-layout = pkgs.runCommand "sourcemod-1-13-layout-check" { } ''
            test -x ${sourcemod_1_13}/addons/sourcemod/scripting/spcomp64
            test -d ${sourcemod_1_13}/addons/sourcemod/extensions
            test -d ${sourcemod_1_13}/addons/sourcemod/plugins
            touch $out
          '';

          devShells.default = pkgs.mkShell {
            packages = [ sourcemod ];
            shellHook = ''
              export PATH=${sourcemod}/addons/sourcemod/scripting:$PATH
            '';
          };

          devShells.sourcemod_1_13 = pkgs.mkShell {
            packages = [ sourcemod_1_13 ];
            shellHook = ''
              export PATH=${sourcemod_1_13}/addons/sourcemod/scripting:$PATH
            '';
          };

          # alejandra 4.x reads stdin when invoked with no path args (which is
          # how `nix fmt` calls it), so default to the flake root in that case.
          formatter = pkgs.writeShellScriptBin "alejandra" ''
            if [ "$#" -eq 0 ]; then
              exec ${pkgs.alejandra}/bin/alejandra .
            else
              exec ${pkgs.alejandra}/bin/alejandra "$@"
            fi
          '';
        }
      );

      # Merge Windows packages into Linux outputs
      merged = linuxOutputs // {
        packages = linuxOutputs.packages // {
          x86_64-windows = windows;
        };
        overlays.default = final: prev: {
          sourcemod_1_12 = self.packages.x86_64-linux.sourcemod_1_12;
          sourcemod_1_13 = self.packages.x86_64-linux.sourcemod_1_13;
          sourcemod = self.packages.x86_64-linux.sourcemod;
        };
      };

    in
    merged;
}

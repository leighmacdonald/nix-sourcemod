# nix-sourcemod

Nix packaging for [SourceMod](https://www.sourcemod.net/) - Source engine scripting and administration.

Provides both **1.12 (stable)** and **1.13 (dev)** branches with automatic daily updates.

## Quick Start

### Using the Flake (Recommended)

```bash
# Enter a dev shell with SourceMod 1.12 (stable) in PATH
nix develop github:leighmacdonald/nix-sourcemod

# Or with SourceMod 1.13 (dev)
nix develop github:leighmacdonald/nix-sourcemod#sourcemod_1_13
```

### Build a Specific Version

```bash
# Build SourceMod 1.12 stable
nix build github:leighmacdonald/nix-sourcemod#sourcemod_1_12

# Build SourceMod 1.13 dev
nix build github:leighmacdonald/nix-sourcemod#sourcemod_1_13
```

## Installation Methods

### 1. As a Flake Input (for other Nix projects)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sourcemod.url = "github:leighmacdonald/nix-sourcemod";
  };

  outputs = { self, nixpkgs, sourcemod }: {
    # Linux (default)
    packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.callPackage ./my-package.nix {
      inherit (sourcemod.packages.x86_64-linux) sourcemod_1_12 sourcemod_1_13;
    };

    # Windows (requires nixpkgs with Windows support)
    packages.x86_64-windows.default = nixpkgs.legacyPackages.x86_64-windows.callPackage ./my-package.nix {
      inherit (sourcemod.packages.x86_64-windows) sourcemod_1_12 sourcemod_1_13;
    };
  };
}
```

### 2. Using the Overlay

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sourcemod.url = "github:leighmacdonald/nix-sourcemod";
  };

  outputs = { self, nixpkgs, sourcemod }: {
    # In your system configuration
    nixosConfigurations.my-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ sourcemod.overlays.default ];
          environment.systemPackages = [ pkgs.sourcemod ]; # 1.12 stable
          # or pkgs.sourcemod_1_13 for dev
        })
      ];
    };
  };
}
```

### 3. Direct Package Usage

```bash
# Get the store path
nix eval --raw github:leighmacdonald/nix-sourcemod#sourcemod_1_12.outPath

# Use in a script
SOURCEMOD_PATH=$(nix eval --raw github:leighmacdonald/nix-sourcemod#sourcemod_1_12.outPath)
$SOURCEMOD_PATH/bin/spcomp64 my-plugin.sp
```

## Available Packages

| Package | Branch | Description |
|---------|--------|-------------|
| `sourcemod_1_12` | stable-1.12 | Stable release (recommended for production) |
| `sourcemod_1_13` | master/1.13 | Development branch (bleeding edge) |
| `sourcemod_stable` | stable-1.12 | Alias for `sourcemod_1_12` |
| `sourcemod_dev` | master/1.13 | Alias for `sourcemod_1_13` |
| `sourcemod` / `default` | stable-1.12 | Default (stable) |

## Binary Locations

After installation, binaries are available at:

**Linux:**
```
$OUT_PATH/
├── addons/
│   └── sourcemod/
│       ├── scripting/
│       │   ├─- include/    # Include files for sourcemod
│       │   ├── spcomp      # 32-bit compiler
│       │   └── spcomp64    # 64-bit compiler
│       ├── extensions/     # Extension binaries (.so)
│       └── plugins/        # Example plugins
├── bin/
│   ├── spcomp -> ../addons/sourcemod/scripting/spcomp
│   └── spcomp64 -> ../addons/sourcemod/scripting/spcomp64
└── cfg/                    # Configuration files
```

Both `$OUT_PATH/addons/sourcemod/scripting/spcomp64` (Linux) / `spcomp64.exe` (Windows) and `$OUT_PATH/bin/spcomp64` / `spcomp64.exe` work.

## Dev Shells

### Default (SourceMod 1.12 Stable)

```bash
nix develop github:leighmacdonald/nix-sourcemod
# PATH includes: $OUT_PATH/addons/sourcemod/scripting/
spcomp64 --version
```

### SourceMod 1.13 Dev

```bash
nix develop github:leighmacdonald/nix-sourcemod#sourcemod_1_13
# PATH includes: $OUT_PATH/addons/sourcemod/scripting/
spcomp64 --version
```

### Custom Dev Shell (flake.nix)

```nix
devShells.my-shell = pkgs.mkShell {
  packages = [ sourcemod_1_12 ];
  shellHook = ''
    export SOURCEMOD_PATH=${sourcemod_1_12}
    export PATH=${sourcemod_1_12}/bin:$PATH
    alias sm-compile='spcomp64 -i ${sourcemod_1_12}/addons/sourcemod/scripting/include'
  '';
};
```

## Compiling Plugins

### Using the Dev Shell

```bash
nix develop github:leighmacdonald/nix-sourcemod
cd my-plugin-project
spcomp64 -i $SOURCEMOD_PATH/addons/sourcemod/scripting/include main.sp -o main.smx
```

### Standalone Build

```bash
# Build the compiler only
nix build github:leighmacdonald/nix-sourcemod#sourcemod_1_12

# Compile with explicit paths
SOURCEMOD=$(nix eval --raw github:leighmacdonald/nix-sourcemod#sourcemod_1_12.outPath)
$SOURCEMOD/bin/spcomp64 -i $SOURCEMOD/addons/sourcemod/scripting/include main.sp -o main.smx
```


## Automatic Updates

This flake includes a **daily GitHub Actions workflow** (`.github/workflows/update-sourcemod.yml`) that:

1. Runs at midnight UTC
2. Queries GitHub Releases API for latest 1.12 and 1.13 builds
3. Updates `package-stable.nix` and `package-dev.nix` with new URLs and SHA256s
4. Opens a PR with changes

Trigger manually:
```bash
gh workflow run update-sourcemod.yml -R leighmacdonald/nix-sourcemod
```

## Requirements

- Nix with flakes enabled (`nix.settings.experimental-features = [ "nix-command" "flakes" ];`)
- **Linux x86_64** - Full support with default nixpkgs
- **Windows x86_64** - Requires nixpkgs with Windows support (e.g., `nixpkgs-unstable`)

## License

SourceMod is licensed under GPL-3.0-or-later. This packaging is MIT licensed.

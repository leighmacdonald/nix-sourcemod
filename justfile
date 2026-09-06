# Common commands for nix-sourcemod (1.12 stable + 1.13 dev) (justfile per repo guidelines)

# Default (stable 1.12)
build:
    nix build .#sourcemod --show-trace

build-1_12:
    nix build .#sourcemod_1_12 --show-trace

build-1_13:
    nix build .#sourcemod_1_13 --show-trace

build-all: build-1_12 build-1_13

check:
    nix flake check --show-trace

shell:
    nix develop

shell-1_13:
    nix develop .#sourcemod_1_13

# Smoke-test the packaged compilers and layout
verify:
    #!/usr/bin/env bash
    set -euo pipefail
    out="$(nix build .#sourcemod --no-link --print-out-paths)"
    echo "store path: $out"
    ls "$out/addons/sourcemod/scripting" | grep -E '^spcomp(64)?$'
    ls "$out/addons/sourcemod/extensions" | head -20
    "$out/addons/sourcemod/scripting/spcomp64" --version 2>&1 | head -5 || "$out/addons/sourcemod/scripting/spcomp64" 2>&1 | head -5 || true

verify-1_12:
    #!/usr/bin/env bash
    set -euo pipefail
    out="$(nix build .#sourcemod_1_12 --no-link --print-out-paths)"
    echo "store path: $out"
    ls "$out/addons/sourcemod/scripting" | grep -E '^spcomp(64)?$'
    ls "$out/addons/sourcemod/extensions" | head -20
    "$out/addons/sourcemod/scripting/spcomp64" --version 2>&1 | head -5 || "$out/addons/sourcemod/scripting/spcomp64" 2>&1 | head -5 || true

verify-1_13:
    #!/usr/bin/env bash
    set -euo pipefail
    out="$(nix build .#sourcemod_1_13 --no-link --print-out-paths)"
    echo "store path: $out"
    ls "$out/addons/sourcemod/scripting" | grep -E '^spcomp(64)?$'
    ls "$out/addons/sourcemod/extensions" | head -20
    "$out/addons/sourcemod/scripting/spcomp64" --version 2>&1 | head -5 || "$out/addons/sourcemod/scripting/spcomp64" 2>&1 | head -5 || true

verify-all: verify-1_12 verify-1_13

fmt:
    nix fmt

update:
    nix flake update

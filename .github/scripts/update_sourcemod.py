#!/usr/bin/env python3
"""
Fetch latest SourceMod releases from GitHub API and update Nix package files.
"""

import base64
import json
import os
import re
import subprocess
import sys
import urllib.request
from pathlib import Path


GITHUB_API = "https://api.github.com/repos/alliedmodders/sourcemod/releases"
PACKAGE_STABLE = Path("package-stable.nix")
PACKAGE_DEV = Path("package-dev.nix")


def fetch_releases():
    """Fetch all releases from GitHub API."""
    req = urllib.request.Request(
        GITHUB_API, headers={"Accept": "application/vnd.github+json"}
    )
    with urllib.request.urlopen(req) as response:
        return json.load(response)


def find_latest_releases(releases):
    """Find the latest stable (1.12) and dev (1.13) releases with both Linux and Windows assets."""
    stable = None
    dev = None

    for release in releases:
        tag = release.get("tag_name", "")
        # Skip drafts
        if release.get("draft"):
            continue

        # Find both linux and windows assets with sha256
        linux_asset = None
        windows_asset = None
        for asset in release.get("assets", []):
            if asset["name"].endswith("-linux.tar.gz"):
                linux_asset = asset
            elif asset["name"].endswith("-windows.zip"):
                windows_asset = asset

        if not linux_asset or not windows_asset:
            continue

        # Parse version from tag (e.g., "1.12.0.7253" or "1.13.0.7456")
        match = re.match(r"^(\d+\.\d+)\.0\.(\d+)$", tag)
        if not match:
            continue

        major_minor = match.group(1)  # "1.12" or "1.13"
        build = match.group(2)  # "7253" or "7456"

        # Extract git version from asset name (e.g., "sourcemod-1.12.0-git7253-linux.tar.gz")
        asset_match = re.search(r"git(\d+)", linux_asset["name"])
        if not asset_match:
            continue
        git_version = asset_match.group(1)

        # Get sha256 from digest (format: "sha256:...") - GitHub returns hex, convert to base64 for Nix
        linux_sha256_hex = linux_asset["digest"].replace("sha256:", "")
        windows_sha256_hex = windows_asset["digest"].replace("sha256:", "")
        # Convert hex to base64 for Nix SRI format
        linux_sha256 = base64.b64encode(bytes.fromhex(linux_sha256_hex)).decode()
        windows_sha256 = base64.b64encode(bytes.fromhex(windows_sha256_hex)).decode()

        version_info = {
            "tag": tag,
            "major_minor": major_minor,
            "build": build,
            "git_version": git_version,
            "version": f"{major_minor}.0-git{git_version}",
            "linux_url": linux_asset["browser_download_url"],
            "linux_sha256": linux_sha256,
            "windows_url": windows_asset["browser_download_url"],
            "windows_sha256": windows_sha256,
        }

        if major_minor == "1.12" and (
            stable is None or int(build) > int(stable["build"])
        ):
            stable = version_info
        elif major_minor == "1.13" and (dev is None or int(build) > int(dev["build"])):
            dev = version_info

    return stable, dev


def get_current_version(path: Path):
    """Extract current version from package file."""
    content = path.read_text()
    match = re.search(r'version = "([^"]+)";', content)
    return match.group(1) if match else "unknown"


def update_package_file(path: Path, version_info: dict, branch_name: str):
    """Update a Nix package file with new version info for both Linux and Windows."""
    content = path.read_text()

    # Update version
    content = re.sub(
        r'version = "([^"]+)";', f'version = "{version_info["version"]}";', content
    )

    # Update Linux URL (match the full if/else block for url)
    content = re.sub(
        r'url = if stdenv\.hostPlatform\.isLinux then\n\s+"[^"]+"\n\s+else\n\s+"[^"]+";',
        f'url = if stdenv.hostPlatform.isLinux then\n      "{version_info["linux_url"]}"\n      else\n      "{version_info["windows_url"]}";',
        content,
        flags=re.MULTILINE,
    )

    # Update Linux sha256 (match the full if/else block for sha256)
    content = re.sub(
        r'sha256 = if stdenv\.hostPlatform\.isLinux then\n\s+"[^"]+"\n\s+else\n\s+"[^"]+";',
        f'sha256 = if stdenv.hostPlatform.isLinux then\n      "sha256-{version_info["linux_sha256"]}"\n      else\n      "sha256-{version_info["windows_sha256"]}";',
        content,
        flags=re.MULTILINE,
    )

    # Update comment with build number
    content = re.sub(
        r"# (stable|dev|master).*branch build, pinned.*",
        f"# {branch_name} branch build, pinned (updated automatically)",
        content,
    )

    path.write_text(content)
    print(
        f"Updated {path}: version={version_info['version']}, "
        f"linux_sha256={version_info['linux_sha256'][:16]}..., "
        f"windows_sha256={version_info['windows_sha256'][:16]}..."
    )


def main():
    print("Fetching SourceMod releases from GitHub API...")
    releases = fetch_releases()

    stable, dev = find_latest_releases(releases)

    if not stable:
        print("ERROR: Could not find latest 1.12 stable release", file=sys.stderr)
        sys.exit(1)

    if not dev:
        print("ERROR: Could not find latest 1.13 dev release", file=sys.stderr)
        sys.exit(1)

    # Get current versions before updating
    current_stable = get_current_version(PACKAGE_STABLE)
    current_dev = get_current_version(PACKAGE_DEV)

    print(f"Latest stable (1.12): {stable['version']} (build {stable['build']})")
    print(f"Latest dev (1.13): {dev['version']} (build {dev['build']})")

    # Update package files
    update_package_file(PACKAGE_STABLE, stable, "stable-1.12")
    update_package_file(PACKAGE_DEV, dev, "master/1.13 dev")

    # Output version changes for the workflow via $GITHUB_OUTPUT
    # (the legacy ::set-output command is disabled on modern runners).
    changes = {
        "stable": {"from": current_stable, "to": stable["version"]},
        "dev": {"from": current_dev, "to": dev["version"]},
    }
    payload = json.dumps(changes)
    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as fh:
            fh.write(f"version_changes={payload}\n")
    else:
        # Local testing fallback (no GITHUB_OUTPUT outside Actions).
        print(f"version_changes={payload}")

    # Configure git
    subprocess.run(["git", "config", "user.name", "github-actions[bot]"], check=True)
    subprocess.run(
        ["git", "config", "user.email", "github-actions[bot]@users.noreply.github.com"],
        check=True,
    )

    print("Done!")


if __name__ == "__main__":
    main()

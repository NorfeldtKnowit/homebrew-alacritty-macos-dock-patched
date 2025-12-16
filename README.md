# Homebrew Tap: Alacritty macOS Dock Patched

A Homebrew tap that provides Alacritty with macOS dock menu support, similar to Terminal.app and iTerm2.

<img width="287" height="335" alt="Screenshot 2025-12-16 at 22 24 20" src="https://github.com/user-attachments/assets/58ecdc4f-8e5a-4e5a-ae1b-1146bb5b0db3" />


## Security Disclaimer

**IMPORTANT**: This patch is NOT independently security-audited. Security relies entirely on the upstream [Alacritty project](https://github.com/alacritty/alacritty). The patch only adds macOS dock menu functionality using Objective-C runtime APIs and does not modify security-sensitive code paths.

Automated updates are enabled by default - PRs are auto-merged after validation checks pass. If you prefer manual review, fork this tap.

## Features

- **Dock Menu**: Right-click the Alacritty dock icon to see all open windows
- **Automated Updates**: GitHub Actions automatically detects new Alacritty releases, validates patches, builds, and auto-merges updates
- **Patch Validation**: Tests patch compatibility before building
- **Zero Maintenance**: Runs hands-off after initial setup

## Installation

```bash
brew tap norfeldt/alacritty-macos-dock-patched
brew install alacritty-macos-dock-patched
```

### Using as GUI App

Create a symlink to Applications:

```bash
ln -s /opt/homebrew/opt/alacritty-macos-dock-patched/Alacritty.app /Applications/Alacritty-Patched.app
```

Or launch directly:

```bash
open /opt/homebrew/opt/alacritty-macos-dock-patched/Alacritty.app
```

## How It Works

This tap applies a ~156-line patch to Alacritty that adds macOS dock menu functionality by:

1. Adding Objective-C runtime code to `src/macos/mod.rs`
2. Implementing `applicationDockMenu:` delegate method
3. Dynamically listing all open Alacritty windows in the dock menu

### Patch Details

The patch modifies three files:

- `alacritty/Cargo.toml` - Adds NSMenu/NSMenuItem dependencies
- `alacritty/src/macos/mod.rs` - Implements dock menu (~120 lines)
- `alacritty/src/main.rs` - Calls `setup_dock_menu()` on startup

## Security Architecture

This tap uses **GitHub Release Assets** to provide stable SHA256 checksums and transparent source verification:

### How Source Distribution Works

1. **Upstream Download**: When a new Alacritty version is detected, the automation downloads the official tarball from the [Alacritty GitHub repository](https://github.com/alacritty/alacritty)
2. **SHA256 Calculation**: The checksum is calculated before any modifications
3. **Release Asset Upload**: The tarball is uploaded to this repository's [GitHub Releases](https://github.com/NorfeldtKnowit/homebrew-alacritty-macos-dock-patched/releases) as an immutable asset
4. **Formula Update**: The Homebrew formula is updated to reference the release asset URL
5. **User Verification**: When users install, Homebrew verifies the SHA256 checksum

### Why Release Assets?

GitHub's auto-generated source tarballs are **non-deterministic** - they can be regenerated with different SHA256 hashes even for the same version tag. This causes installation failures when checksums don't match.

By mirroring upstream sources as GitHub Release Assets:

- **Permanent Stability**: SHA256 never changes after upload (GitHub guarantees immutability)
- **Clear Attribution**: Every release documents the upstream Alacritty version and source URL
- **Independent Verification**: Users can verify checksums manually:

```bash
# Download release asset
curl -sL "https://github.com/NorfeldtKnowit/homebrew-alacritty-macos-dock-patched/releases/download/v0.16.1/alacritty-v0.16.1.tar.gz" | shasum -a 256

# Should output: b7240df4a52c004470977237a276185fc97395d59319480d67cad3c4347f395e
```

### Security Verification Process

Every release includes:

- **Upstream Attribution**: Direct link to the official Alacritty release
- **SHA256 Checksum**: Calculated and verified before upload
- **Build Validation**: macOS build completed successfully with all tests passed
- **Patch Compatibility**: Documented whether the patch applied cleanly

See [SECURITY.md](SECURITY.md) for detailed verification steps.

## Automated Updates

This tap uses a four-tier GitHub Actions workflow to handle updates automatically:

### Workflow Architecture

```
Tier 1: Detection (every 6 hours)
  ├─ Check for new Alacritty releases
  ├─ Test patch compatibility with --dry-run
  └─ Trigger build if compatible

Tier 2: Build (20-25 min)
  ├─ Download and apply patch
  ├─ Build with 'make app'
  ├─ Test binary execution
  └─ Trigger release asset upload if successful

Tier 3: Release Asset Upload (2-3 min)
  ├─ Download upstream tarball
  ├─ Verify SHA256 matches build-time calculation
  ├─ Create GitHub release with documentation
  ├─ Upload tarball as immutable asset
  └─ Trigger formula update

Tier 4: Update (3-5 min)
  ├─ Update formula to reference release asset URL
  ├─ Verify asset accessibility
  ├─ Create PR with validation results
  └─ Auto-merge after checks pass
```

### Setup Requirements (for maintainers)

#### 1. GitHub Personal Access Token

Create a PAT token for cross-workflow triggers:

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with scopes:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
3. Copy the token

#### 2. Add Repository Secret

1. Go to repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `TAP_UPDATE_TOKEN`
4. Value: Paste your PAT token
5. Click "Add secret"

#### 3. Repository Settings

Enable GitHub Actions permissions:

1. Go to Settings → Actions → General → Workflow permissions
2. Select "Read and write permissions"
3. Check "Allow GitHub Actions to create and approve pull requests"
4. Click "Save"

### Testing the Automation

Trigger the workflow manually (don't wait 6 hours):

```bash
cd ~/repos/homebrew-alacritty-patched
gh workflow run check-upstream.yml
```

Monitor the workflow:

```bash
gh run list --workflow=check-upstream.yml
gh run view <run-id> --log
```

### Expected Behavior

When a new Alacritty release is detected:

- **T+0 min**: Scheduled check triggers
- **T+2 min**: Patch validation completes
- **T+25 min**: Build completes on macOS runner
- **T+30 min**: PR created with validation results

If patch fails to apply, an issue is automatically created with the label `patch-failure`.

## Maintenance

### Patch Compatibility

The patch has an estimated **70-80% compatibility rate** with new Alacritty releases. Most releases don't touch the patched areas.

When a patch fails (20-30% of releases):

1. An issue with label `patch-failure` is created automatically
2. Manual intervention needed to update the patch
3. Follow the patch update process below

### Updating the Patch

If Alacritty refactors the code and the patch fails:

1. Clone the new Alacritty version
2. Manually apply the changes
3. Generate a new patch:

```bash
cd ~/repos/alacritty
git diff > ~/repos/homebrew-alacritty-patched/alacritty-dock-menu.patch
```

4. Update the formula and test locally:

```bash
brew uninstall alacritty-macos-dock-patched
brew install --build-from-source norfeldt/alacritty-macos-dock-patched/alacritty-macos-dock-patched
```

## Development

### Building Locally

```bash
brew install --build-from-source Formula/alacritty-macos-dock-patched.rb
```

### Testing the Dock Menu

1. Launch Alacritty patched version
2. Open multiple windows (Cmd+N)
3. Right-click the Alacritty icon in the dock
4. Verify all windows appear in the menu
5. Click a window title to bring it to front

## Repository Structure

```
homebrew-alacritty-macos-dock-patched/
├── .github/
│   └── workflows/
│       ├── check-upstream.yml                    # Tier 1: Release detection
│       ├── build-and-update.yml                  # Tier 2: Build and test
│       ├── release-asset-upload.yml              # Tier 3: Release asset creation
│       └── update-formula.yml                    # Tier 4: Formula update + auto-merge
├── Formula/
│   └── alacritty-macos-dock-patched.rb           # Homebrew formula
├── alacritty-dock-menu.patch                     # Patch file
├── SECURITY.md                                   # Security verification guide
├── CONTRIBUTING.md                               # Workflow documentation for contributors
└── README.md                                     # This file
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed workflow documentation and development guide.

## Upstream Contribution

This feature may be submitted to the main Alacritty repository as a PR in the future. See the [plan document](.claude/plans/jolly-percolating-quilt.md) for details.

Relevant upstream issues:

- [#6346 - Group windows in dock](https://github.com/alacritty/alacritty/issues/6346)
- [#6157 - Window grouping](https://github.com/alacritty/alacritty/issues/6157)

## License

This tap follows Alacritty's Apache 2.0 license. The patch is a derivative work of Alacritty.

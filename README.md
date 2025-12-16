# Homebrew Tap: Alacritty Patched

A Homebrew tap that provides Alacritty with macOS dock menu support, similar to Terminal.app and iTerm2.

## Features

- **Dock Menu**: Right-click the Alacritty dock icon to see all open windows
- **Automated Updates**: GitHub Actions automatically detects new Alacritty releases and updates the formula
- **Patch Validation**: Tests patch compatibility before building

## Installation

```bash
brew tap norfeldt/alacritty-patched
brew install alacritty-patched
```

### Using as GUI App

Create a symlink to Applications:

```bash
ln -s /opt/homebrew/opt/alacritty-patched/Alacritty.app /Applications/Alacritty-Patched.app
```

Or launch directly:

```bash
open /opt/homebrew/opt/alacritty-patched/Alacritty.app
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

## Automated Updates

This tap uses a three-tier GitHub Actions workflow to handle updates automatically:

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
  └─ Trigger formula update if successful

Tier 3: Update (3-5 min)
  ├─ Update formula version/SHA256
  ├─ Create PR with test results
  └─ Ready for manual review and merge
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
brew uninstall alacritty-patched
brew install --build-from-source norfeldt/alacritty-patched/alacritty-patched
```

## Development

### Building Locally

```bash
brew install --build-from-source Formula/alacritty-patched.rb
```

### Testing the Dock Menu

1. Launch Alacritty patched version
2. Open multiple windows (Cmd+N)
3. Right-click the Alacritty icon in the dock
4. Verify all windows appear in the menu
5. Click a window title to bring it to front

## Repository Structure

```
homebrew-alacritty-patched/
├── .github/
│   └── workflows/
│       ├── check-upstream.yml      # Tier 1: Release detection
│       ├── build-and-update.yml    # Tier 2: Build and test
│       └── update-formula.yml      # Tier 3: Formula update
├── Formula/
│   └── alacritty-patched.rb        # Homebrew formula
├── alacritty-dock-menu.patch       # Patch file
└── README.md                       # This file
```

## Upstream Contribution

This feature may be submitted to the main Alacritty repository as a PR in the future. See the [plan document](.claude/plans/jolly-percolating-quilt.md) for details.

Relevant upstream issues:

- [#6346 - Group windows in dock](https://github.com/alacritty/alacritty/issues/6346)
- [#6157 - Window grouping](https://github.com/alacritty/alacritty/issues/6157)

## License

This tap follows Alacritty's Apache 2.0 license. The patch is a derivative work of Alacritty.

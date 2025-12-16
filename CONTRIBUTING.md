# Contributing to Alacritty macOS Dock Patched

Thank you for your interest in contributing! This document explains the automation architecture and how to make changes safely.

## Workflow Architecture

This tap uses a **four-tier automated workflow** to handle Alacritty updates:

### Tier 1: Release Detection

**Workflow:** `.github/workflows/check-upstream.yml`

**Trigger:** Every 6 hours (cron schedule) or manual dispatch

**What it does:**

1. Checks GitHub API for new Alacritty releases
2. Compares with current formula version
3. If new version found:
   - Downloads the source tarball
   - Tests patch compatibility with `patch --dry-run`
   - Triggers Tier 2 if patch applies cleanly
   - Creates `patch-failure` issue if patch fails

**Manual trigger:**

```bash
gh workflow run check-upstream.yml
```

### Tier 2: Build and Test

**Workflow:** `.github/workflows/build-and-update.yml`

**Trigger:** Called by Tier 1 when new version detected

**What it does:**

1. Downloads upstream Alacritty source tarball
2. Calculates SHA256 checksum
3. Extracts source and applies patch
4. Builds with `make app` on macOS runner
5. Tests the binary:
   - Version matches expected
   - Binary executes without errors
   - Dock menu implementation present
6. Uploads build artifact
7. Triggers Tier 3 with version and SHA256

**Manual trigger:**

```bash
gh workflow run build-and-update.yml -f version="0.16.1"
```

### Tier 3: Release Asset Upload

**Workflow:** `.github/workflows/release-asset-upload.yml`

**Trigger:** Called by Tier 2 after successful build

**What it does:**

1. Downloads upstream tarball from Alacritty GitHub
2. Verifies SHA256 matches Tier 2 calculation
3. Creates GitHub release (if doesn't exist):
   - Tag: `v{version}` (mirrors upstream)
   - Title: "Alacritty v{version} (macOS Dock Menu)"
   - Release notes with upstream attribution and verification details
4. Uploads tarball as release asset: `alacritty-v{version}.tar.gz`
5. Verifies asset is publicly accessible
6. Triggers Tier 4 with asset URL

**Key security features:**

- SHA256 mismatch detection (if GitHub regenerated tarball)
- Asset accessibility verification before proceeding
- Comprehensive error handling and failure issues

**Manual trigger:**

```bash
gh workflow run release-asset-upload.yml \
  -f version="0.16.1" \
  -f sha256="b7240df4a52c004470977237a276185fc97395d59319480d67cad3c4347f395e" \
  -f patch_compatible="true"
```

### Tier 4: Formula Update

**Workflow:** `.github/workflows/update-formula.yml`

**Trigger:** Called by Tier 3 after asset upload

**What it does:**

1. Verifies release asset URL is accessible
2. Creates new branch: `auto-update-v{version}`
3. Updates `Formula/alacritty-macos-dock-patched.rb`:
   - Changes URL to release asset
   - Updates SHA256 checksum
4. Commits and pushes to branch
5. Creates pull request with validation summary
6. Enables auto-merge (squash strategy)
7. PR merges automatically when `validate-formula` check passes

**Manual trigger:**

```bash
gh workflow run update-formula.yml \
  -f version="0.16.1" \
  -f sha256="b7240df4a52c004470977237a276185fc97395d59319480d67cad3c4347f395e" \
  -f asset_url="https://github.com/NorfeldtKnowit/homebrew-alacritty-macos-dock-patched/releases/download/v0.16.1/alacritty-v0.16.1.tar.gz"
```

## Complete Update Flow

```
User/Cron
    ↓
┌─────────────────────────────────┐
│ Tier 1: check-upstream.yml      │
│ - Detect new Alacritty release  │
│ - Test patch compatibility      │
└─────────────┬───────────────────┘
              ↓ (if compatible)
┌─────────────────────────────────┐
│ Tier 2: build-and-update.yml    │
│ - Build patched Alacritty       │
│ - Test binary                   │
│ - Calculate SHA256              │
└─────────────┬───────────────────┘
              ↓ (if build succeeds)
┌─────────────────────────────────┐
│ Tier 3: release-asset-upload.yml│
│ - Download upstream tarball     │
│ - Create GitHub release         │
│ - Upload as immutable asset     │
│ - Verify accessibility          │
└─────────────┬───────────────────┘
              ↓ (if upload succeeds)
┌─────────────────────────────────┐
│ Tier 4: update-formula.yml      │
│ - Update formula to asset URL   │
│ - Create PR                     │
│ - Auto-merge after checks       │
└─────────────────────────────────┘
```

## Making Changes

### Updating the Patch

When Alacritty makes breaking changes that conflict with the patch:

**1. Clone the new Alacritty version:**

```bash
cd ~/repos
git clone https://github.com/alacritty/alacritty.git
cd alacritty
git checkout v0.16.1  # Use the new version tag
```

**2. Manually apply the patch changes:**

Review the existing patch to understand what it does:

```bash
cat ~/repos/homebrew-alacritty-patched/alacritty-dock-menu.patch
```

Manually apply the same changes to the new codebase. The patch typically modifies:

- `alacritty/Cargo.toml` - Add objc/cocoa dependencies
- `alacritty/src/macos/mod.rs` - Implement dock menu function
- `alacritty/src/main.rs` - Call setup function on startup

**3. Generate the new patch:**

```bash
git add -A
git diff --staged > ~/repos/homebrew-alacritty-patched/alacritty-dock-menu.patch
```

**4. Test the patch locally:**

```bash
cd ~/repos/homebrew-alacritty-patched
brew uninstall alacritty-macos-dock-patched
brew install --build-from-source ./Formula/alacritty-macos-dock-patched.rb
```

**5. Commit and push:**

```bash
git add alacritty-dock-menu.patch
git commit -m "Update patch for Alacritty v0.16.1 compatibility"
git push origin main
```

**6. Trigger the automation:**

```bash
gh workflow run check-upstream.yml
```

### Modifying Workflows

When changing the automation:

**Best practices:**

- Test changes on a fork first
- Use `workflow_dispatch` for manual testing
- Add comprehensive error handling
- Create issues on failure for visibility
- Document all workflow inputs

**Testing workflow changes:**

```bash
# Test individual workflows
gh workflow run build-and-update.yml -f version="0.16.1"

# Monitor execution
gh run list --workflow=build-and-update.yml
gh run view <run-id> --log
```

### Updating Dependencies

**Homebrew formula dependencies:**

Edit `Formula/alacritty-macos-dock-patched.rb`:

```ruby
depends_on "rust" => :build
depends_on "scdoc" => :build
# Add new dependencies here
```

**Patch dependencies:**

Edit `alacritty-dock-menu.patch` to modify `Cargo.toml`:

```diff
+objc = "0.2"
+cocoa = "0.26"
```

## Security Considerations

### When Modifying Workflows

**Never:**

- Store secrets in workflow files (use GitHub Secrets)
- Skip SHA256 verification
- Auto-merge without validation checks
- Modify upstream sources without documentation

**Always:**

- Verify checksums before upload
- Document source attribution
- Test on isolated branches first
- Create audit trails in release notes

### When Updating the Patch

**Review checklist:**

- [ ] Patch only adds dock menu functionality
- [ ] No modification of security-sensitive code paths
- [ ] No new network or filesystem access
- [ ] Uses only official macOS APIs
- [ ] Dependencies are well-known and trusted

## Testing Checklist

Before merging patch updates:

**Build tests:**

- [ ] Patch applies cleanly: `patch --dry-run -p1 < alacritty-dock-menu.patch`
- [ ] Compiles successfully: `make app`
- [ ] Binary executes: `./target/release/osx/Alacritty.app/Contents/MacOS/alacritty --version`

**Functional tests:**

- [ ] Launch application
- [ ] Open multiple windows (Cmd+N)
- [ ] Right-click dock icon
- [ ] All windows appear in dock menu
- [ ] Clicking menu item brings window to front

**Integration tests:**

- [ ] Formula installs successfully via Homebrew
- [ ] SHA256 verification passes
- [ ] Symlink to Applications works
- [ ] CLI binary accessible at `/opt/homebrew/bin/alacritty`

## Release Management

### Creating a New Release Manually

If you need to create a release outside the automation:

**1. Build and test locally:**

```bash
VERSION="0.16.1"
curl -L "https://github.com/alacritty/alacritty/archive/refs/tags/v${VERSION}.tar.gz" -o "alacritty-v${VERSION}.tar.gz"

# Calculate SHA256
shasum -a 256 "alacritty-v${VERSION}.tar.gz"
```

**2. Create GitHub release:**

```bash
gh release create "v${VERSION}" \
  --title "Alacritty v${VERSION} (macOS Dock Menu)" \
  --notes "See SECURITY.md for verification details"
```

**3. Upload tarball as asset:**

```bash
gh release upload "v${VERSION}" "alacritty-v${VERSION}.tar.gz"
```

**4. Update formula:**

Edit `Formula/alacritty-macos-dock-patched.rb` with new version and SHA256.

**5. Create PR and merge after validation.**

### Retroactive Releases

To create releases for older versions (for historical completeness):

```bash
# Download old version
VERSION="0.16.0"
curl -L "https://github.com/alacritty/alacritty/archive/refs/tags/v${VERSION}.tar.gz" -o "alacritty-v${VERSION}.tar.gz"

# Get current SHA256 (may differ from original if GitHub regenerated)
SHA256=$(shasum -a 256 "alacritty-v${VERSION}.tar.gz" | cut -d' ' -f1)

# Create release
gh release create "v${VERSION}" \
  --title "Alacritty v${VERSION} (macOS Dock Menu)" \
  --notes "Retroactive release for historical completeness. SHA256: ${SHA256}"

# Upload asset
gh release upload "v${VERSION}" "alacritty-v${VERSION}.tar.gz"
```

## Troubleshooting

### Common Issues

**Patch fails to apply:**

- Alacritty made breaking changes to files the patch modifies
- Solution: Update patch manually (see "Updating the Patch" above)

**SHA256 mismatch during release asset upload:**

- GitHub regenerated the upstream tarball between build and release
- Automation detects this and uses the actual SHA256
- No action needed - workflow handles it automatically

**Formula validation fails:**

- Syntax error in formula file
- Solution: Run `brew audit Formula/alacritty-macos-dock-patched.rb` locally

**Auto-merge not working:**

- Check repository settings allow GitHub Actions to create PRs
- Verify `TAP_UPDATE_TOKEN` has correct permissions
- Ensure branch protection allows auto-merge

### Debug Workflow Issues

**View workflow logs:**

```bash
gh run list --workflow=build-and-update.yml
gh run view <run-id> --log
```

**Check workflow status:**

```bash
gh workflow view build-and-update.yml
```

**Cancel stuck workflow:**

```bash
gh run cancel <run-id>
```

## Getting Help

- **Workflow issues**: Create issue with label `automation`
- **Patch compatibility**: Create issue with label `patch-failure`
- **Security concerns**: See [SECURITY.md](SECURITY.md)
- **General questions**: Create issue with label `question`

## Code of Conduct

Be respectful and constructive. This is a community project maintained in spare time.

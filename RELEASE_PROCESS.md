# Release Process for Matchy Homebrew Tap

## Simple Workflow

When you release a new version of Matchy, follow these steps:

### Step 1: Release Matchy

In your main Matchy repository:

```bash
cd ~/factual/mmdb_with_strings/matchy  # or wherever your matchy repo is

# Create and push the tag
git tag v0.5.3
git push origin v0.5.3

# Create the GitHub release
gh release create v0.5.3 \
  --title "v0.5.3" \
  --notes "Release notes here" \
  --repo sethhall/matchy
```

### Step 2: Trigger Bottle Building

Go to: https://github.com/sethhall/homebrew-matchy/actions/workflows/bottles.yml

1. Click **"Run workflow"** button
2. Enter the version tag: `v0.5.3`
3. Click **"Run workflow"**

The workflow will (takes ~10-15 minutes):
- ✅ Build bottles for macOS Apple Silicon, macOS Intel, and Linux
- ✅ Create a release in the tap repo with bottles
- ✅ Update `Formula/matchy.rb` with bottle information
- ✅ Commit and push the changes

### Step 3: Verify

```bash
# Pull the updated formula
cd ~/factual/homebrew-matchy
git pull

# Test installation (should download bottle, not build from source)
brew uninstall matchy 2>/dev/null || true
brew install --verbose sethhall/matchy/matchy
```

You should see: `==> Pouring matchy--0.5.3.arm64_sequoia.bottle.tar.gz` ✅

NOT: `==> Building from source` ❌

That's it! 🎉

---

## What Happens Behind the Scenes

1. **Bottles are built** on 3 platforms:
   - macOS 15 (Apple Silicon) → `arm64_sequoia`
   - macOS 13 (Intel) → `ventura`
   - Ubuntu Linux → `x86_64_linux`

2. **Bottles are uploaded** to this tap repo's releases:
   - `https://github.com/sethhall/homebrew-matchy/releases/download/v0.5.3/matchy--0.5.3.arm64_sequoia.bottle.tar.gz`
   - `https://github.com/sethhall/homebrew-matchy/releases/download/v0.5.3/matchy--0.5.3.ventura.bottle.tar.gz`
   - `https://github.com/sethhall/homebrew-matchy/releases/download/v0.5.3/matchy--0.5.3.x86_64_linux.bottle.tar.gz`

3. **Formula is updated** with bottle block:
   ```ruby
   bottle do
     root_url "https://github.com/sethhall/homebrew-matchy/releases/download/v0.5.3"
     sha256 cellar: :any, arm64_sequoia: "abc123..."
     sha256 cellar: :any, ventura:       "def456..."
     sha256 cellar: :any, x86_64_linux:  "ghi789..."
   end
   ```

---

## Quick Command Reference

```bash
# In matchy repo: Create release
cd ~/factual/mmdb_with_strings/matchy
git tag v0.5.3 && git push origin v0.5.3
gh release create v0.5.3 --title "v0.5.3" --notes "Release notes" --repo sethhall/matchy

# Trigger workflow at:
# https://github.com/sethhall/homebrew-matchy/actions/workflows/bottles.yml
# Enter: v0.5.3

# Wait ~10-15 minutes, then verify:
cd ~/factual/homebrew-matchy && git pull
brew uninstall matchy && brew install --verbose sethhall/matchy/matchy
```

---

## Troubleshooting

### Workflow fails at "Build bottle"

Check the build logs in GitHub Actions. Common issues:
- Rust compilation error → Fix in main Matchy repo
- cargo-c installation issue → Usually transient, re-run workflow

### Bottles build but users still build from source

1. **Check platform name matches:**
   ```bash
   brew --config | grep "macOS:"
   ```

2. **Verify bottle is accessible:**
   ```bash
   curl -I https://github.com/sethhall/homebrew-matchy/releases/download/v0.5.3/matchy--0.5.3.arm64_sequoia.bottle.tar.gz
   ```

3. **Check formula syntax:**
   ```bash
   brew audit --strict Formula/matchy.rb
   ```

### Need to rebuild bottles

If you need to fix something and rebuild:

```bash
# Delete the release in tap repo
gh release delete v0.5.3 --repo sethhall/homebrew-matchy --yes

# Re-run the workflow with the same version
```

---

## Manual Update (Without Bottles)

If you prefer not to use bottles, you can manually update just the version:

```bash
cd ~/factual/homebrew-matchy

# Update Formula/matchy.rb:
# - Line 4: Change version in URL
# - Line 5: Update SHA256

# Calculate new SHA256:
curl -sL https://github.com/sethhall/matchy/archive/refs/tags/v0.5.3.tar.gz | shasum -a 256

# Commit and push
git add Formula/matchy.rb
git commit -m "Update to v0.5.3"
git push
```

Users will build from source (slower, requires Rust).

---

## Advanced: Fully Automated Releases

Want zero manual steps? You can set up the main Matchy repo to automatically trigger this workflow on release. Let me know if you want this!

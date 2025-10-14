# Homebrew Bottle Creation Guide for Matchy

This guide walks through manually creating and hosting bottles (precompiled binaries) for the Matchy Homebrew tap.

## What You'll Create

Bottles for different platforms:
- **macOS Apple Silicon** (arm64_sequoia, arm64_sonoma, arm64_ventura)
- **macOS Intel** (ventura, monterey)
- **Linux** (x86_64_linux)

## Prerequisites

- Access to machines for each platform you want to support (or use GitHub Actions)
- GitHub repository with releases enabled
- `gh` CLI installed (optional, makes uploading easier): `brew install gh`

---

## Step 1: Build the Bottle on Your Current Platform

### 1.1 Uninstall Any Existing Installation

```bash
brew uninstall matchy 2>/dev/null || true
```

### 1.2 Install with Bottle Building Enabled

```bash
# This installs but prepares it for bottling
brew install --build-bottle Formula/matchy.rb
```

This builds everything but marks it as "relocatable" for bottling.

### 1.3 Generate the Bottle Archive

```bash
# Create the bottle - this generates a .tar.gz and .json file
brew bottle --no-rebuild --json Formula/matchy.rb
```

**Output will look like:**
```
./matchy--0.5.2.arm64_sequoia.bottle.tar.gz
./matchy--0.5.2.arm64_sequoia.bottle.json
```

The filename format is: `{formula}--{version}.{platform}.bottle.tar.gz`

### 1.4 Examine What Was Created

```bash
# List the files
ls -lh *.bottle.tar.gz *.bottle.json

# See what's inside the bottle
tar -tzf matchy--0.5.2.arm64_sequoia.bottle.tar.gz | head -20
```

You'll see it contains:
- `matchy/0.5.2/bin/matchy` - CLI binary
- `matchy/0.5.2/lib/libmatchy.a` - Static library
- `matchy/0.5.2/lib/libmatchy.dylib` - Dynamic library
- `matchy/0.5.2/include/matchy/*.h` - Headers
- `matchy/0.5.2/lib/pkgconfig/matchy.pc` - pkg-config file

### 1.5 Extract the SHA256 from the JSON

```bash
# View the bottle metadata
cat matchy--0.5.2.arm64_sequoia.bottle.json
```

Look for the `sha256` value - you'll need this for the formula.

---

## Step 2: Build Bottles for Other Platforms

You need to repeat Step 1 on each platform you want to support:

### macOS Platforms

- **arm64_sequoia**: macOS 15 (Sequoia) on Apple Silicon - **← You have this one**
- **arm64_sonoma**: macOS 14 (Sonoma) on Apple Silicon
- **arm64_ventura**: macOS 13 (Ventura) on Apple Silicon
- **ventura**: macOS 13 (Ventura) on Intel
- **monterey**: macOS 12 (Monterey) on Intel

### Linux Platforms

- **x86_64_linux**: Generic Linux x86_64

**Pro Tip:** You don't need to support every platform. Start with just your current platform (arm64_sequoia) and add others as needed.

---

## Step 3: Upload Bottles to GitHub Releases

### Option A: Using GitHub Web Interface

1. Go to your Matchy repository: https://github.com/sethhall/matchy/releases
2. Find the release for v0.5.2 (or create one if it doesn't exist)
3. Click "Edit release"
4. Drag and drop all `.bottle.tar.gz` files into the assets section
5. Save the release

### Option B: Using `gh` CLI (Recommended)

```bash
# Authenticate if you haven't already
gh auth login

# Upload bottles to the v0.5.2 release
gh release upload v0.5.2 matchy--0.5.2.arm64_sequoia.bottle.tar.gz \
  --repo sethhall/matchy

# If the release doesn't exist yet, create it first:
gh release create v0.5.2 \
  --title "v0.5.2" \
  --notes "Release v0.5.2" \
  --repo sethhall/matchy

# Then upload
gh release upload v0.5.2 matchy--0.5.2.*.bottle.tar.gz \
  --repo sethhall/matchy
```

### Verify Upload

Check that bottles are accessible:
```bash
# Example URL format:
# https://github.com/sethhall/matchy/releases/download/v0.5.2/matchy--0.5.2.arm64_sequoia.bottle.tar.gz

curl -I https://github.com/sethhall/matchy/releases/download/v0.5.2/matchy--0.5.2.arm64_sequoia.bottle.tar.gz
```

Should return `HTTP/2 302` (redirect) or `HTTP/2 200` (success).

---

## Step 4: Update the Formula with Bottle Information

Now update `Formula/matchy.rb` to reference the bottles:

```ruby
class Matchy < Formula
  desc "Fast database for IP address and string matching with rich data storage"
  homepage "https://github.com/sethhall/matchy"
  url "https://github.com/sethhall/matchy/archive/refs/tags/v0.5.2.tar.gz"
  sha256 "e4f4ecd0ddba8eb99693a3972259bf2a1f577de3f2dc214484efd036823d9e49"
  license "BSD-2-Clause"
  head "https://github.com/sethhall/matchy.git", branch: "main"

  # Bottle definitions
  bottle do
    root_url "https://github.com/sethhall/matchy/releases/download/v0.5.2"
    sha256 cellar: :any, arm64_sequoia: "REPLACE_WITH_ACTUAL_SHA256"
    # Add more platforms as you build them:
    # sha256 cellar: :any, arm64_sonoma:  "REPLACE_WITH_SHA256"
    # sha256 cellar: :any, ventura:       "REPLACE_WITH_SHA256"
    # sha256 cellar: :any, x86_64_linux:  "REPLACE_WITH_SHA256"
  end

  depends_on "rust" => :build
  depends_on "cbindgen" => :build

  # ... rest of formula unchanged
end
```

### Understanding the Bottle Block

- **`root_url`**: Base URL where bottles are hosted (your GitHub release)
- **`sha256`**: Hash of the bottle archive (from the .json file)
- **`cellar: :any`**: Means the bottle has dynamic libraries that can be relocated
  - Use `:any` when you have `.dylib` or `.so` files
  - Use `:any_skip_relocation` for pure static binaries
- **Platform names**: Must match Homebrew's platform identifiers exactly

---

## Step 5: Test the Bottle Installation

### 5.1 Clear Homebrew Cache

```bash
# Remove cached downloads
rm -rf ~/Library/Caches/Homebrew/matchy--*
rm -rf ~/Library/Caches/Homebrew/downloads/*matchy*
```

### 5.2 Uninstall Current Version

```bash
brew uninstall matchy
```

### 5.3 Install from Updated Formula

```bash
# Install from your tap
brew install --verbose sethhall/matchy/matchy
```

Watch the output - you should see:
```
==> Downloading https://github.com/sethhall/matchy/releases/download/v0.5.2/matchy--0.5.2.arm64_sequoia.bottle.tar.gz
==> Pouring matchy--0.5.2.arm64_sequoia.bottle.tar.gz
```

If it says "Building from source" instead of "Pouring", the bottle wasn't used. Check:
- Platform name matches exactly (run `brew --config` to see your platform)
- SHA256 is correct
- Bottle URL is accessible
- Formula syntax is correct

### 5.4 Verify Installation

```bash
# CLI should work
matchy --version

# C library should be available
ls -la $(brew --prefix matchy)/lib/libmatchy.*
ls -la $(brew --prefix matchy)/include/matchy/

# Test the C compilation
cat > test.c << 'EOF'
#include <matchy/matchy.h>
#include <stdio.h>

int main() {
    printf("Matchy C library loaded successfully!\n");
    return 0;
}
EOF

gcc test.c -I$(brew --prefix matchy)/include -L$(brew --prefix matchy)/lib -lmatchy -o test
./test
rm test test.c
```

---

## Step 6: Commit and Push the Updated Formula

```bash
git add Formula/matchy.rb
git commit -m "Add bottle for macOS arm64_sequoia (v0.5.2)"
git push origin main
```

---

## Common Issues and Solutions

### Issue: "Bottle checksum mismatch"

**Cause:** SHA256 in formula doesn't match the actual bottle file.

**Solution:**
```bash
# Recalculate the SHA256
shasum -a 256 matchy--0.5.2.arm64_sequoia.bottle.tar.gz

# Update the formula with the correct hash
```

### Issue: Bottle not used, building from source

**Possible causes:**
1. Platform name doesn't match your system
2. Bottle SHA256 is incorrect
3. Bottle URL is not accessible
4. macOS version mismatch

**Debug:**
```bash
# Check your platform identifier
brew --config | grep macOS

# Try downloading bottle manually
curl -L https://github.com/sethhall/matchy/releases/download/v0.5.2/matchy--0.5.2.arm64_sequoia.bottle.tar.gz -o test.tar.gz

# Verify SHA256
shasum -a 256 test.tar.gz
```

### Issue: "dyld: Library not loaded"

**Cause:** Dynamic library linking issues.

**Solution:** This shouldn't happen with `cellar: :any`, but if it does:
```bash
# Check library dependencies
otool -L $(brew --prefix matchy)/bin/matchy
otool -L $(brew --prefix matchy)/lib/libmatchy.dylib

# Libraries should reference @rpath or be bundled
```

---

## Quick Reference: Complete Workflow

```bash
# 1. Build bottle locally
brew uninstall matchy 2>/dev/null || true
brew install --build-bottle Formula/matchy.rb
brew bottle --no-rebuild --json Formula/matchy.rb

# 2. Extract SHA256
cat matchy--0.5.2.arm64_sequoia.bottle.json | grep sha256

# 3. Upload to GitHub
gh release upload v0.5.2 matchy--0.5.2.*.bottle.tar.gz --repo sethhall/matchy

# 4. Update formula with bottle block (edit Formula/matchy.rb)

# 5. Test installation
brew uninstall matchy
rm -rf ~/Library/Caches/Homebrew/matchy--*
brew install --verbose sethhall/matchy/matchy

# 6. Commit and push
git add Formula/matchy.rb
git commit -m "Add bottles for v0.5.2"
git push origin main
```

---

## Next Steps

Once you have this working manually:

1. **Add More Platforms**: Repeat the process on different machines
2. **Automate with GitHub Actions**: Set up CI/CD to build bottles automatically
3. **Document for Users**: Update README to mention fast binary installation

---

## Platform Reference

### macOS Platform Identifiers

| OS Version | Architecture | Identifier |
|------------|--------------|------------|
| macOS 15 (Sequoia) | Apple Silicon | `arm64_sequoia` |
| macOS 14 (Sonoma) | Apple Silicon | `arm64_sonoma` |
| macOS 13 (Ventura) | Apple Silicon | `arm64_ventura` |
| macOS 13 (Ventura) | Intel | `ventura` |
| macOS 12 (Monterey) | Intel | `monterey` |

### Linux Platform Identifiers

- `x86_64_linux` - Generic 64-bit Linux
- `aarch64_linux` - ARM64 Linux

Check your current platform:
```bash
brew --config | grep "macOS:\|CPU:"
```

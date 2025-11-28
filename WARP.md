# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository Overview

This is a Homebrew tap repository for [Matchy](https://github.com/matchylabs/matchy), a high-performance database for IP address and string matching. The tap provides formula definitions for installing Matchy via Homebrew package manager on macOS and Linux.

**Repository Structure:**
- `Formula/matchy.rb` - Homebrew formula definition for the Matchy package
- `README.md` - User-facing documentation for installing and using the tap

## Common Commands

### Testing the Formula Locally

Test formula changes before publishing:

```bash
# Install from local formula with verbose output
brew install --build-from-source --verbose --debug Formula/matchy.rb

# Force reinstall after making changes
brew reinstall --build-from-source --verbose --debug Formula/matchy.rb

# Uninstall to test clean install
brew uninstall matchy
```

### Formula Validation

```bash
# Audit the formula for issues
brew audit --strict --online Formula/matchy.rb

# Check formula style
brew style Formula/matchy.rb

# Run formula tests
brew test matchy
```

### Publishing Updates

When updating the formula for a new Matchy release:

```bash
# 1. Update version and URL in Formula/matchy.rb
# 2. Calculate SHA256 checksum
curl -sL https://github.com/matchylabs/matchy/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256

# 3. Update sha256 field in formula
# 4. Test the formula
brew install --build-from-source Formula/matchy.rb

# 5. Commit and push
git add Formula/matchy.rb
git commit -m "matchy X.Y.Z"
git push origin main
```

### User Installation Commands

Users install the tap with:

```bash
# One-step install
brew install matchylabs/matchy/matchy

# Or tap first, then install
brew tap matchylabs/matchy
brew install matchy
```

## Formula Architecture

### Build Process

The `matchy.rb` formula orchestrates a multi-stage build:

1. **Rust Binary Build** - Uses `cargo install` to build the CLI tool and Rust library
2. **C Library Build** - Uses `cargo-c` (cargo-capi) to generate C-compatible shared/static libraries
3. **Header Installation** - Installs both `matchy.h` and `maxminddb.h` headers
4. **pkg-config Setup** - Creates pkg-config files for easy linking

### Key Dependencies

- `rust` - Required for building (build-time dependency)
- `cbindgen` - Generates C bindings from Rust (build-time dependency)
- `cargo-c` - Auto-installed if missing, generates C libraries from Rust crates

### Installation Artifacts

The formula installs multiple components:

- **CLI Binary**: `bin/matchy` - Command-line tool for building and querying databases
- **Rust Library**: Crate installed via cargo, usable in Rust projects
- **C Static Library**: `lib/libmatchy.a` - For static linking
- **C Dynamic Library**: `lib/libmatchy.dylib` (macOS) or `lib/libmatchy.so` (Linux)
- **Headers**: `include/matchy/matchy.h` and `include/matchy/maxminddb.h`
- **pkg-config**: `lib/pkgconfig/matchy.pc` - Build system integration

## Formula Test Suite

The `test do` block verifies:

1. **CLI Functionality**: Builds and queries a `.mxy` database
2. **IP Address Matching**: Tests exact IP and CIDR range queries
3. **Pattern Matching**: Tests glob pattern matching (e.g., `*.example.com`)
4. **C Library API**: Compiles and runs a C program using both builder and query APIs
5. **MaxMind Compatibility**: Verifies `maxminddb.h` header is available

Tests run automatically during `brew test matchy` and when users install from source.

## Homebrew Tap Conventions

### Version Updates

- Update `url` to point to new GitHub release tarball
- Calculate and update `sha256` checksum (leave empty string initially and Homebrew will prompt)
- Version number is extracted from the URL (e.g., `v0.5.2.tar.gz` → version 0.5.2)
- Use `head` line for development installs from `main` branch

### Formula Naming

- File: `Formula/matchy.rb`
- Class name: `Matchy` (capitalized, matches filename)
- Package name: `matchy` (lowercase)

### Testing Before Release

Always test both:
- Fresh install: `brew install --build-from-source Formula/matchy.rb`
- Upgrade path: Install old version, then test upgrade with new formula

## Common Issues

### SHA256 Mismatch

If Homebrew reports SHA256 mismatch, the archive changed or checksum is wrong:
```bash
# Recalculate correct checksum
curl -sL <github-archive-url> | shasum -a 256
```

### cargo-c Not Found

The formula auto-installs `cargo-c` if missing. If build fails:
```bash
# Manually verify cargo-c
cargo install --list | grep cargo-c

# Reinstall if needed
cargo install cargo-c
```

### Missing Headers

If `maxminddb.h` is missing after build, check:
- Matchy repo's `Cargo.toml` has correct `capi.header` configuration
- `cargo-c` version is compatible (update with `cargo install cargo-c --force`)

## Building and Publishing Bottles

Bottles are pre-built binaries that speed up installation by avoiding compilation.

### Creating a New Bottle

```bash
# 1. Remove any existing bottle block from Formula/matchy.rb temporarily

# 2. Commit and push the formula without bottle block
git add Formula/matchy.rb
git commit -m "Prepare for bottle build"
git push origin main

# 3. Update local tap and build with --build-bottle flag
brew update
brew uninstall matchy 2>/dev/null || true
brew install --build-bottle matchylabs/matchy/matchy

# 4. Create the bottle with the correct root URL
brew bottle --json --root-url=https://github.com/matchylabs/homebrew-matchy/releases/download/vX.Y.Z matchylabs/matchy/matchy

# This creates two files:
# - matchy--X.Y.Z.arm64_tahoe.bottle.N.tar.gz (the bottle)
# - matchy--X.Y.Z.arm64_tahoe.bottle.json (metadata)

# 5. Rename bottle to use single dash (Homebrew expects this format)
cp matchy--X.Y.Z.arm64_tahoe.bottle.N.tar.gz matchy-X.Y.Z.arm64_tahoe.bottle.N.tar.gz

# 6. Create GitHub release and upload bottle
gh release create vX.Y.Z \
  --title "Bottle vX.Y.Z" \
  --notes "Pre-built binary bottle for Matchy vX.Y.Z (macOS ARM64)" \
  matchy-X.Y.Z.arm64_tahoe.bottle.N.tar.gz

# Or upload to existing release:
gh release upload vX.Y.Z matchy-X.Y.Z.arm64_tahoe.bottle.N.tar.gz --clobber

# 7. Add bottle block to formula (copy from brew bottle output)
# The output shows the exact bottle block to add, e.g.:
#   bottle do
#     root_url "https://github.com/matchylabs/homebrew-matchy/releases/download/vX.Y.Z"
#     rebuild N
#     sha256 cellar: :any, arm64_tahoe: "abc123..."
#   end

# 8. Commit and push updated formula with bottle block
git add Formula/matchy.rb
git commit -m "Add bottle for vX.Y.Z (arm64_tahoe)"
git push origin main

# 9. Test bottle installation
brew uninstall matchy
brew update
brew install matchylabs/matchy/matchy
```

### Bottle Platform Tags

- `arm64_tahoe` = Apple Silicon on macOS 15 (Sequoia)
- `arm64_ventura` = Apple Silicon on macOS 13 (Ventura)
- `x86_64_tahoe` = Intel on macOS 15

Homebrew automatically selects the appropriate bottle for the user's platform.

### Bottle Naming Convention

Bottle files must use **single dash** format: `matchy-X.Y.Z.platform.bottle.N.tar.gz`

Note: `brew bottle` creates files with double dashes (`matchy--X.Y.Z`), but Homebrew's download logic expects single dash. Always rename before uploading.

## Related Repositories

- **Main Project**: [github.com/matchylabs/matchy](https://github.com/matchylabs/matchy) - Rust source code
- **Documentation**: [docs.rs/matchy](https://docs.rs/matchy) - API documentation
- **Examples**: [matchy/examples](https://github.com/matchylabs/matchy/tree/main/examples) - Usage examples

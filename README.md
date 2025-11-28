# Homebrew Tap for Matchy

Official Homebrew tap for [Matchy](https://github.com/matchylabs/matchy) - a high-performance database for IP address and string matching with rich data storage.

Matchy combines IP address lookups, exact string matching, and glob pattern matching in a single unified interface. Perfect for threat intelligence, GeoIP, domain categorization, and network security applications.

## Installation

### Quick Install

```bash
# Tap and install in one command
brew install matchylabs/matchy/matchy
```

### Or tap first

```bash
# Add the tap
brew tap matchylabs/matchy

# Install matchy
brew install matchy
```

This installs:
- `matchy` CLI binary
- `libmatchy` static and dynamic libraries  
- C headers in `$(brew --prefix)/include/matchy/`
- pkg-config file for easy linking

**Note**: Pre-built bottles (binaries) are available for macOS ARM64 (Apple Silicon). Installation is fast - no compilation required!

### Install HEAD

To install the latest development version:

```bash
brew install --HEAD matchy
```

## Usage

See the [main repository](https://github.com/matchylabs/matchy) for CLI and C API usage examples.

## Development

To test the formula locally before pushing:

```bash
# Test from local formula
brew install --build-from-source --verbose --debug Formula/matchy.rb

# Audit and validate
brew audit --strict --online Formula/matchy.rb
brew style Formula/matchy.rb
brew test matchy
```

When updating for a new Matchy release:

```bash
# Calculate SHA256 for new version
curl -sL https://github.com/matchylabs/matchy/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256

# Update Formula/matchy.rb with new URL and sha256
# Test, then commit
git add Formula/matchy.rb
git commit -m "matchy X.Y.Z"
git push origin main
```

### Building Bottles

For detailed instructions on building and publishing bottles (pre-built binaries), see `WARP.md`.

## Documentation

For usage examples, API documentation, and more details:
- [Main Repository](https://github.com/matchylabs/matchy)
- [API Documentation](https://docs.rs/matchy)
- [Examples](https://github.com/matchylabs/matchy/tree/main/examples)

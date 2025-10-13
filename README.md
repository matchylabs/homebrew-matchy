# Homebrew Tap for Matchy

Official Homebrew tap for [Matchy](https://github.com/sethhall/matchy) - a high-performance database for IP address and string matching with rich data storage.

Matchy combines IP address lookups, exact string matching, and glob pattern matching in a single unified interface. Perfect for threat intelligence, GeoIP, domain categorization, and network security applications.

## Installation

```bash
brew install sethhall/matchy/matchy
```

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
curl -sL https://github.com/sethhall/matchy/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256

# Update Formula/matchy.rb with new URL and sha256
# Test, then commit
git add Formula/matchy.rb
git commit -m "matchy X.Y.Z"
git push origin main
```

## Documentation

For usage examples, API documentation, and more details:
- [Main Repository](https://github.com/sethhall/matchy)
- [API Documentation](https://docs.rs/matchy)
- [Examples](https://github.com/sethhall/matchy/tree/main/examples)

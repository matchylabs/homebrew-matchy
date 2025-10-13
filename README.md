# Homebrew Tap for Matchy

Official Homebrew tap for [Matchy](https://github.com/sethhall/matchy) - a fast database for IP address and string matching with rich data storage.

## What is Matchy?

Matchy is a high-performance database that combines IP address lookups, exact string matching, and glob pattern matching in a single unified interface. Perfect for threat intelligence, GeoIP, domain categorization, and network security applications.

**Key Features:**
- 🚀 7M+ IP queries/second on modern hardware
- 🎯 Match IP addresses, CIDR ranges, exact strings, and glob patterns
- 📦 Memory-mapped for instant loading and efficient multi-process sharing
- 🔌 Both Rust and C APIs available
- 🗂️ Store rich JSON-like structured data with each entry
- ⚡ Compatible with MaxMind MMDB format (extended)

## Installation

### Quick Install

```bash
brew install sethhall/matchy/matchy
```

### Add the Tap First (Optional)

```bash
# Add the tap
brew tap sethhall/matchy

# Install matchy
brew install matchy
```

## What Gets Installed

The formula installs:

1. **CLI Tool** (`matchy`) - Build and query `.mxy` databases
2. **Rust Library** - Use in your Rust projects via `cargo`
3. **C Library** (`libmatchy`) - Static and dynamic libraries for C/C++ projects
4. **Headers**:
   - `matchy/matchy.h` - Main matchy API
   - `matchy/maxminddb.h` - MaxMind-compatible API for IP lookups
5. **pkg-config** - Easy integration with build systems

## Usage

### Command Line

Build a database from a text file:

```bash
# Create a simple blocklist
echo "1.2.3.4" > blocklist.txt
echo "*.evil.com" >> blocklist.txt
echo "10.0.0.0/8" >> blocklist.txt

matchy build --input blocklist.txt --output blocklist.mxy
```

Query the database:

```bash
matchy query blocklist.mxy 1.2.3.4
matchy query blocklist.mxy subdomain.evil.com
matchy query blocklist.mxy 10.1.2.3
```

### C/C++ Projects

Compile and link against matchy:

```bash
# Using pkg-config (recommended)
gcc myapp.c $(pkg-config --cflags --libs matchy) -o myapp

# Or manually
gcc myapp.c -I$(brew --prefix matchy)/include -L$(brew --prefix matchy)/lib -lmatchy -o myapp
```

Example C code:

```c
#include <matchy/matchy.h>
#include <stdio.h>

int main() {
    matchy_builder_t *builder = matchy_builder_new();
    matchy_builder_add(builder, "8.8.8.8", "{\"provider\": \"google\"}");
    matchy_builder_add(builder, "*.evil.com", "{\"threat\": \"high\"}");
    matchy_builder_save(builder, "db.mxy");
    matchy_builder_free(builder);
    
    matchy_t *db = matchy_open("db.mxy");
    matchy_result_t result = matchy_query(db, "8.8.8.8");
    
    if (result.found && result.data_json) {
        printf("Found: %s\n", result.data_json);
        matchy_free_result(&result);
    }
    
    matchy_close(db);
    return 0;
}
```

### Rust Projects

Add to your `Cargo.toml`:

```toml
[dependencies]
matchy = "0.5"
```

Or use the Homebrew-installed library:

```bash
cargo build --features="link-system-libs"
```

## Building from Source

```bash
brew install --build-from-source sethhall/matchy/matchy
```

## Development

To test the formula locally before pushing:

```bash
# In the homebrew-matchy directory
brew install --build-from-source --verbose --debug Formula/matchy.rb
```

## Updating

```bash
brew update
brew upgrade matchy
```

## Documentation

- [Main Matchy Repository](https://github.com/sethhall/matchy)
- [API Documentation](https://docs.rs/matchy)
- [Examples](https://github.com/sethhall/matchy/tree/main/examples)

## License

BSD-2-Clause - See [LICENSE](https://github.com/sethhall/matchy/blob/main/LICENSE)

## Support

- Report issues: [GitHub Issues](https://github.com/sethhall/matchy/issues)
- Questions: [GitHub Discussions](https://github.com/sethhall/matchy/discussions)

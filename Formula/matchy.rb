class Matchy < Formula
  desc "Fast database for IP address and string matching with rich data storage"
  homepage "https://github.com/sethhall/matchy"
  url "https://github.com/sethhall/matchy/archive/refs/tags/v0.5.2.tar.gz"
  sha256 "e4f4ecd0ddba8eb99693a3972259bf2a1f577de3f2dc214484efd036823d9e49"
  license "BSD-2-Clause"
  head "https://github.com/sethhall/matchy.git", branch: "main"

  depends_on "rust" => :build
  depends_on "cbindgen" => :build

  def install
    # Build the Rust library and CLI tool
    system "cargo", "install", *std_cargo_args

    # Only build C library if not building a bottle (cargo-c has complex dependencies)
    return if build.bottle?

    # Build the C library using cargo-c
    # First check if cargo-c is installed, if not install it
    cargo_list = `cargo install --list`
    unless cargo_list.include?("cargo-capi") || cargo_list.include?("cargo-c")
      system "cargo", "install", "cargo-c"
    end

    # Install C library and headers using cargo-c
    system "cargo", "cinstall", "--release",
           "--prefix", prefix,
           "--libdir", lib,
           "--includedir", include

    # cargo-c should install maxminddb.h via the capi.install.include config
    # but let's ensure it's there
    unless (include/"matchy/maxminddb.h").exist?
      odie "maxminddb.h was not installed by cargo-c" if build.stable?
    end

    # Install pkg-config file for easy linking (should be done by cargo-c)
    (lib/"pkgconfig").mkpath unless (lib/"pkgconfig").exist?
  end

  test do
    # Test the CLI tool - build a database
    (testpath/"test_data.txt").write <<~EOS
      8.8.8.8
      10.0.0.0/8
      *.example.com
    EOS

    system bin/"matchy", "build", "--input", "test_data.txt", "--output", "test.mxy"
    assert_predicate testpath/"test.mxy", :exist?

    # Test querying the database with the CLI
    output = shell_output("#{bin}/matchy query test.mxy 8.8.8.8")
    assert_match(/found/i, output)

    # Test pattern matching
    output = shell_output("#{bin}/matchy query test.mxy subdomain.example.com")
    assert_match(/found/i, output)

    # Test the C library - build and query
    (testpath/"test.c").write <<~EOS
      #include <matchy/matchy.h>
      #include <matchy/maxminddb.h>
      #include <stdio.h>
      #include <stdlib.h>
      #include <string.h>

      int main() {
          // Build a test database
          matchy_builder_t *builder = matchy_builder_new();
          if (!builder) {
              fprintf(stderr, "Failed to create builder\\n");
              return 1;
          }
          
          int result = matchy_builder_add(builder, "8.8.8.8", "{\\"test\\": \\"data\\"}");
          if (result != 0) {
              fprintf(stderr, "Failed to add entry\\n");
              matchy_builder_free(builder);
              return 1;
          }

          result = matchy_builder_add(builder, "*.test.com", "{\\"pattern\\": \\"match\\"}");
          if (result != 0) {
              fprintf(stderr, "Failed to add pattern\\n");
              matchy_builder_free(builder);
              return 1;
          }
          
          result = matchy_builder_save(builder, "test_c.mxy");
          matchy_builder_free(builder);
          
          if (result != 0) {
              fprintf(stderr, "Failed to save database\\n");
              return 1;
          }

          // Query the database
          matchy_t *db = matchy_open("test_c.mxy");
          if (!db) {
              fprintf(stderr, "Failed to open database\\n");
              return 1;
          }
          
          // Test IP lookup
          matchy_result_t ip_result = matchy_query(db, "8.8.8.8");
          if (!ip_result.found) {
              fprintf(stderr, "IP lookup failed\\n");
              matchy_close(db);
              return 1;
          }
          printf("IP found: %s\\n", ip_result.data_json ? ip_result.data_json : "null");
          matchy_free_result(&ip_result);

          // Test pattern matching
          matchy_result_t pattern_result = matchy_query(db, "subdomain.test.com");
          if (!pattern_result.found) {
              fprintf(stderr, "Pattern lookup failed\\n");
              matchy_close(db);
              return 1;
          }
          printf("Pattern matched: %s\\n", pattern_result.data_json ? pattern_result.data_json : "null");
          matchy_free_result(&pattern_result);
          
          matchy_close(db);
          printf("All tests passed!\\n");
          return 0;
      }
    EOS

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lmatchy", "-o", "test"
    system "./test"
  end
end

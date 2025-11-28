class Matchy < Formula
  desc "Fast database for IP address and pattern matching with rich data storage"
  homepage "https://github.com/matchylabs/matchy"
  url "https://github.com/matchylabs/matchy.git", branch: "main"
  version "1.2.2-dev"
  license "BSD-2-Clause"
  head "https://github.com/matchylabs/matchy.git", branch: "main"

  bottle do
    root_url "https://github.com/matchylabs/homebrew-matchy/releases/download/v1.2.2-dev"
    sha256 cellar: :any, arm64_tahoe: "2eb2ae531196644bfad5db7fbba23c50deb7e2aa9e54003d1386761c7553c34d"
  end

  depends_on "rust" => :build
  depends_on "cargo-c" => :build
  depends_on "jq" => :optional

  def install
    # Build and install the CLI binary from workspace crate
    system "cargo", "install",
           "--path", "crates/matchy",
           "--root", prefix,
           "--features", "cli"

    # Build and install the C library using cargo-c from workspace crate
    Dir.chdir("crates/matchy") do
      system "cargo", "cinstall", "--release",
             "--prefix", prefix
    end

    # Build and install jq plugin if jq is available
    if build.with?("jq") || which("jq")
      Dir.chdir("jq-plugin") do
        # Build plugin with static linking
        system "make", "MATCHY_ROOT=..", "PREFIX=#{prefix}"
        
        # Install to jq plugins directory
        (lib/"jq").mkpath
        system "make", "install", "MATCHY_ROOT=..", "PREFIX=#{prefix}", "PLUGIN_DIR=#{lib}/jq"
      end
      
      ohai "jq plugin installed to #{lib}/jq/"
      ohai "Use with: jq 'import \"jq_matchy\" as m; ...'"
    end
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

    # Test jq plugin if it was installed
    if (lib/"jq/jq_matchy.dylib").exist? || (lib/"jq/jq_matchy.so").exist?
      # Build test database with matchy CLI
      system bin/"matchy", "build", "--input", "test_data.txt", "--output", "jq_test.mxy"
      
      # Test jq plugin
      output = shell_output("echo '\"8.8.8.8\"' | jq 'import \"jq_matchy\" as m; . | m::match(\"jq_test.mxy\")' 2>&1")
      assert_match(/true/, output)
      
      output = shell_output("echo '\"subdomain.example.com\"' | jq 'import \"jq_matchy\" as m; . | m::query(\"jq_test.mxy\")' 2>&1")
      assert_match(/\{/, output)  # Should return JSON object
    end
  end
end

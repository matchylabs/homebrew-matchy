class JqMatchy < Formula
  desc "jq plugin for matchy - fast IP and pattern matching in jq pipelines"
  homepage "https://github.com/matchylabs/matchy-jq-plugin"
  url "https://github.com/matchylabs/matchy-jq-plugin.git", branch: "main"
  version "0.1.0"
  license "BSD-2-Clause"
  head "https://github.com/matchylabs/matchy-jq-plugin.git", branch: "main"

  depends_on "matchylabs/matchy/matchy"
  depends_on "jq"

  def install
    # Build and install the jq plugin
    system "make", "PREFIX=#{prefix}"
    
    # Install to jq plugins directory
    (lib/"jq").mkpath
    system "make", "install", "PREFIX=#{prefix}", "PLUGIN_DIR=#{lib}/jq"
  end

  test do
    # Create a test database
    (testpath/"test_data.txt").write <<~EOS
      8.8.8.8 {"test": "data"}
      *.example.com {"pattern": "match"}
    EOS

    system Formula["matchylabs/matchy/matchy"].bin/"matchy", "build",
           "--input", "test_data.txt", 
           "--output", "test.mxy"
    assert_predicate testpath/"test.mxy", :exist?

    # Test the jq plugin
    output = shell_output("echo '\"8.8.8.8\"' | jq 'import \"jq_matchy\" as m; . | m::match(\"test.mxy\")'")
    assert_match(/true/, output)

    output = shell_output("echo '\"subdomain.example.com\"' | jq 'import \"jq_matchy\" as m; . | m::query(\"test.mxy\")'")
    assert_match(/"pattern"/, output)
  end
end

class Immorterm < Formula
  desc "Persistent terminal sessions for VS Code - terminals that survive crashes"
  homepage "https://github.com/lonormaly/ImmorTerm"
  url "https://github.com/lonormaly/ImmorTerm/archive/refs/tags/v1.1.1.tar.gz"
  sha256 "9179241f8c33e0de74fed8fe17d90c418b0b1a84ffb84e51ee07547e6f0bb7c0"
  license "MIT"
  head "https://github.com/lonormaly/ImmorTerm.git", branch: "main"

  depends_on "screen"

  def install
    # Install the main installer script
    bin.install "src/installer.sh" => "immorterm"

    # Install supporting scripts to libexec
    libexec.install Dir["src/scripts/*"]
    libexec.install Dir["src/templates/*"]
    libexec.install Dir["src/extension/*"]

    # Make scripts executable
    (libexec/"screen-auto").chmod 0755
    (libexec/"screen-reconcile").chmod 0755
    (libexec/"screen-cleanup").chmod 0755
    (libexec/"screen-forget").chmod 0755
    (libexec/"screen-forget-all").chmod 0755
    (libexec/"claude-session-sync").chmod 0755
  end

  def caveats
    <<~EOS
      ImmorTerm has been installed!

      To set up persistent terminals for a project, run:
        immorterm /path/to/your/project

      Or in your project directory:
        immorterm .

      This will:
        1. Configure GNU Screen for persistent sessions
        2. Set up VS Code terminal integration
        3. Install the terminal name sync extension

      After installation, your terminals will survive VS Code crashes!

      For more info: https://github.com/lonormaly/ImmorTerm
    EOS
  end

  test do
    assert_match "ImmorTerm v", shell_output("#{bin}/immorterm --version")
  end
end

class Immorterm < Formula
  desc "ImmorTerm - The ultimate persistent terminal solution that keeps your agentic workflow uninterrupted"
  homepage "https://github.com/lonormaly/ImmorTerm"
  url "https://github.com/lonormaly/ImmorTerm/archive/v1.0.0.tar.gz"
  sha256 "c389aca6749037dabaf21025a8020a09898139a34d4862335948f918443ed494"
  license "GPL-3.0-or-later"
  version "1.0.0"

  depends_on "ncurses"

  head "https://github.com/lonormaly/ImmorTerm.git", branch: "main"

  # Does NOT conflict with stock screen - installs as immorterm
  def install
    # Build from src/terminal directory (our screen fork)
    cd "src/terminal" do
      system "./configure", "--prefix=#{prefix}",
                            "--enable-telnet",
                            "--with-sys-screenrc=#{etc}/immortermrc"
      system "make"

      # Makefile produces 'immorterm' directly (renamed from 'screen')
      bin.install "immorterm"

      # Install man page
      man1.install "doc/screen.1" => "immorterm.1"

      # Install UTF-8 encodings
      (share/"immorterm/utf8encodings").install Dir["utf8encodings/*"]
    end
  end

  def caveats
    <<~EOS
      ImmorTerm 1.0.0 has been installed!

      FEATURES:
      - OpenMemory integration for persistent Claude memory
      - Memory Doctor: Run 'immorterm doctor' to diagnose memory services
      - Background memory consolidation for Claude Code sessions
      - Brain emoji (🧠) in status bar when memory is active

      VS CODE USERS:
      1. Close any open terminals in VS Code
      2. Reload VS Code: Cmd+Shift+P -> "Developer: Reload Window"
      3. Open a new terminal - enjoy persistent terminals!

      MEMORY SERVICES:
      - Enable via VS Code: "ImmorTerm: Configure Memory Services"
      - Diagnostics: immorterm doctor
      - Requires Docker Desktop

      Run with: immorterm

      For more info: https://github.com/lonormaly/ImmorTerm
    EOS
  end

  test do
    system bin/"immorterm", "-v"
  end
end

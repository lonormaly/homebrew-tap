class Immorterm < Formula
  desc "ImmorTerm - The ultimate persistent terminal solution that keeps your agentic workflow uninterrupted"
  homepage "https://github.com/lonormaly/ImmorTerm"
  url "https://github.com/lonormaly/ImmorTerm/archive/8b008b6c0774f548a8c1fc1e8fa4673867ee8754.tar.gz"
  sha256 "32f6a4e5ce1827819ddf273e32ec947da5e0eeed6093a597228203ce407ea101"
  license "GPL-3.0-or-later"
  version "1.1.0"

  depends_on "ncurses"

  # Does NOT conflict with stock screen - installs as immorterm
  def install
    # Build from src/terminal directory (our screen fork)
    cd "src/terminal" do
      system "./configure", *std_configure_args,
                            "--enable-colors256",
                            "--enable-rxvt_osc",
                            "--enable-telnet",
                            "--with-sys-screenrc=#{etc}/immortermrc"
      system "make"

      # Install binary as immorterm
      bin.install "screen" => "immorterm"

      # Install man page
      man1.install "doc/screen.1" => "immorterm.1"

      # Install UTF-8 encodings
      (share/"immorterm/utf8encodings").install Dir["utf8encodings/*"]
    end
  end

  def caveats
    <<~EOS
      ImmorTerm 1.1.0 has been installed! 🔮

      ═══════════════════════════════════════════════════════════════════
      VS CODE USERS:
      ═══════════════════════════════════════════════════════════════════
      1. Close any open terminals in VS Code
      2. Reload VS Code: Cmd+Shift+P → "Developer: Reload Window"
      3. Open a new terminal - enjoy persistent terminals! 🎉
      ═══════════════════════════════════════════════════════════════════

      Run with: immorterm

      Features in 1.1.0:
      • Scrollback dump on reattach - history restored to VS Code scrollback
      • UTF-8 characters in window/tab titles (★, ✳, emoji)
      • Synchronous OSC title passthrough to VS Code
      • Log filter for clean restoration (strips cursor positioning)

      Used by the ImmorTerm VS Code extension for persistent terminals.

      For more info: https://github.com/lonormaly/ImmorTerm

      ───────────────────────────────────────────────────────────────────
      ImmorTerm is a fork of GNU Screen 5.0.1. Licensed under GPL-3.0.
    EOS
  end

  test do
    system bin/"immorterm", "-v"
  end
end

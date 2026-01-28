class Immorterm < Formula
  desc "ImmorTerm - The ultimate persistent terminal solution that keeps your agentic workflow uninterrupted"
  homepage "https://github.com/lonormaly/ImmorTerm"
  url "https://github.com/lonormaly/ImmorTerm/archive/ad9497c.tar.gz"
  sha256 "cb748a9978eb996711370b74da44fa2656474aa066152e4baec258945f516d4a"
  license "GPL-3.0-or-later"
  version "1.0.0"

  depends_on "ncurses"

  # Does NOT conflict with stock screen - installs as immorterm
  def install
    # Build from src/terminal directory (our screen fork)
    cd "src/terminal" do
      system "./configure", "--prefix=#{prefix}",
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
      ImmorTerm 1.0.0 has been installed!

      VS CODE USERS:
      1. Close any open terminals in VS Code
      2. Reload VS Code: Cmd+Shift+P -> "Developer: Reload Window"
      3. Open a new terminal - enjoy persistent terminals!

      Run with: immorterm

      Performance optimizations in this release:
      - Fast socket discovery for instant session connections
      - Polling instead of fixed sleeps (up to 950ms faster attach)
      - Buffered logging reduces I/O syscalls by ~99%
      - Parallel terminal restoration in VS Code extension

      Features:
      - %I escape for last I/O activity timestamp (zero polling!)
      - Fixed scroll region to exclude hardstatus (prevents status bar duplication)
      - Scrollback dump on reattach - history restored to VS Code scrollback
      - UTF-8 characters in window/tab titles
      - Fixed stray characters during resize with Claude Code
      - %t window title updates from OSC sequences (without redraw race)

      Used by the ImmorTerm VS Code extension for persistent terminals.

      For more info: https://github.com/lonormaly/ImmorTerm
    EOS
  end

  test do
    system bin/"immorterm", "-v"
  end
end

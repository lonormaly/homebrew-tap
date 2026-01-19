class Immorterm < Formula
  desc "ImmorTerm - Persistent terminal multiplexer with UTF-8 title support"
  homepage "https://github.com/lonormaly/ImmorTerm"
  url "https://ftp.gnu.org/gnu/screen/screen-5.0.1.tar.gz"
  sha256 "2dae36f4db379ffcd14b691596ba6ec18ac3a9e22bc47ac239789ab58409869d"
  license "GPL-3.0-or-later"
  version "1.0.0"

  # Patches: UTF-8 titles, OSC passthrough, branding as ImmorTerm
  patch :DATA

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "ncurses"

  # Does NOT conflict with stock screen - installs as immorterm
  def install
    # Apply branding changes via sed (more robust than patch context matching)
    inreplace "screen.c" do |s|
      s.gsub! 'Print \"Screen version %s\"', 'Print \"ImmorTerm %s\"'
      s.gsub! 'printf("Screen version %s\\n", version)', 'printf("ImmorTerm %s\\n", version)'
      s.gsub! 'snprintf(version, 59, "%d.%d.%d (build on %s) ", VERSION_MAJOR, VERSION_MINOR, VERSION_REVISION, BUILD_DATE)',
              'snprintf(version, 59, "1.0.0", VERSION_MAJOR, VERSION_MINOR, VERSION_REVISION)'
    end
    inreplace "list_license.c" do |s|
      s.gsub! 'strlen("Screen version ")', 'strlen("ImmorTerm ")'
      s.gsub! '"Screen version %s", version', '"ImmorTerm %s", version'
    end

    system "./configure", *std_configure_args,
                          "--enable-colors256",
                          "--enable-rxvt_osc",
                          "--enable-telnet",
                          "--with-sys-screenrc=#{etc}/immortermrc"
    system "make"
    system "make", "install"

    # Rename binary to immorterm
    mv bin/"screen", bin/"immorterm"

    # Install completion (if it exists)
    if File.exist?("etc/bash_completion.d/screen")
      bash_completion.install "etc/bash_completion.d/screen" => "immorterm"
    end
  end

  def caveats
    <<~EOS
      ImmorTerm 1.0.0 has been installed! 🔮

      ═══════════════════════════════════════════════════════════════════
      VS CODE USERS:
      ═══════════════════════════════════════════════════════════════════
      1. Close any open terminals in VS Code
      2. Reload VS Code: Cmd+Shift+P → "Developer: Reload Window"
      3. Open a new terminal - enjoy persistent terminals! 🎉
      ═══════════════════════════════════════════════════════════════════

      Run with: immorterm

      Features:
      • UTF-8 characters in window/tab titles (★, ✳, emoji)
      • Synchronous OSC title passthrough to VS Code
      • Proper hardstatus and caption Unicode support

      Used by the ImmorTerm VS Code extension for persistent terminals.

      For more info: https://github.com/lonormaly/ImmorTerm

      ───────────────────────────────────────────────────────────────────
      ImmorTerm is built on GNU Screen 5.0.1. Licensed under GPL-3.0.
    EOS
  end

  test do
    system bin/"immorterm", "-v"
  end
end

__END__
--- a/ansi.c
+++ b/ansi.c
@@ -1209,10 +1209,34 @@ static void StringStart(Window *win, enum string_t type)
 
 static void StringChar(Window *win, int c)
 {
-	if (win->w_stringp >= win->w_string + MAXSTR - 1)
+	if (win->w_stringp >= win->w_string + MAXSTR - 1) {
 		win->w_state = LIT;
-	else
+		return;
+	}
+	/* Re-encode Unicode code points back to UTF-8 for storage */
+	if (win->w_encoding == UTF8 && c >= 0x80) {
+		if (c < 0x800) {
+			if (win->w_stringp < win->w_string + MAXSTR - 2) {
+				*(win->w_stringp)++ = (c >> 6) | 0xc0;
+				*(win->w_stringp)++ = (c & 0x3f) | 0x80;
+			}
+		} else if (c < 0x10000) {
+			if (win->w_stringp < win->w_string + MAXSTR - 3) {
+				*(win->w_stringp)++ = (c >> 12) | 0xe0;
+				*(win->w_stringp)++ = ((c >> 6) & 0x3f) | 0x80;
+				*(win->w_stringp)++ = (c & 0x3f) | 0x80;
+			}
+		} else {
+			if (win->w_stringp < win->w_string + MAXSTR - 4) {
+				*(win->w_stringp)++ = (c >> 18) | 0xf0;
+				*(win->w_stringp)++ = ((c >> 12) & 0x3f) | 0x80;
+				*(win->w_stringp)++ = ((c >> 6) & 0x3f) | 0x80;
+				*(win->w_stringp)++ = (c & 0x3f) | 0x80;
+			}
+		}
+	} else {
 		*(win->w_stringp)++ = c;
+	}
 }
 
 /*
@@ -1287,8 +1311,15 @@ static int StringEnd(Window *win)
 		if (typ != 0 && typ != 2)
 			break;
 
+		/* ImmorTerm: Update window title (%t) synchronously with OSC passthrough.
+		 * This ensures the screen status bar updates at the same time as the VS Code tab.
+		 * Then skip the APC fallthrough to prevent duplicate status bar rendering.
+		 */
+		ChangeAKA(win, p, strlen(p));
+		break;
+
 		win->w_stringp -= p - win->w_string;
 		if (win->w_stringp > win->w_string)
 			memmove(win->w_string, p, win->w_stringp - win->w_string);
 		*win->w_stringp = '\0';
 		/* FALLTHROUGH */
@@ -1330,7 +1361,7 @@ static int StringEnd(Window *win)
 		}
 		return -1;
 	case DCS:
-		LAY_DISPLAYS(&win->w_layer, AddStr(win->w_string));
+		LAY_DISPLAYS(&win->w_layer, AddRawStr(win->w_string));
 		break;
 	case AKA:
 		if (win->w_title == win->w_akabuf && !*win->w_string)
@@ -1813,7 +1851,8 @@ void ChangeAKA(Window *win, char *s, size_t len)
 		c = (unsigned char)*s++;
 		if (c == 0)
 			break;
-		if (c < 32 || c == 127 || (c >= 128 && c < 160 && win->w_c1))
+		/* ImmorTerm: Don't filter C1 bytes (128-159) in UTF-8 mode - they're valid UTF-8 continuation bytes */
+		if (c < 32 || c == 127 || (c >= 128 && c < 160 && win->w_c1 && win->w_encoding != UTF8))
 			continue;
 		win->w_akachange[i++] = c;
 	}
--- a/display.c
+++ b/display.c
@@ -1607,12 +1607,18 @@ static int strlen_onscreen(char *c, char *end)
 static int PrePutWinMsg(char *s, int start, int max)
 {
 	/* Avoid double-encoding problem for a UTF-8 message on a UTF-8 locale.
-	   Ideally, this would not be necessary. But fixing it the Right Way will
-	   probably take way more time. So this will have to do for now. */
+	 * Ideally, this would not be necessary. But fixing it the Right Way will
+	 * probably take way more time. So this will have to do for now.
+	 * ImmorTerm: Also clear D_xtable to prevent translation table lookups
+	 * that break UTF-8 byte sequences (e.g., ✳ showing as ?).
+	 */
 	if (D_encoding == UTF8) {
 		int chars = strlen_onscreen((s + start), (s + max));
+		char ***saved_xtable = D_xtable;
 		D_encoding = 0;
+		D_xtable = NULL;
 		PutWinMsg(s, start, max + ((max - start) - chars));	/* Multibyte count */
+		D_xtable = saved_xtable;
 		D_encoding = UTF8;
 		D_x -= (max - chars);	/* Yak! But this is necessary to count for
 					   the fact that not every byte represents a
@@ -1647,9 +1653,9 @@ void ShowHStatus(char *str)
 		AddCStr2(D_TS, 0);
 		max = D_WS > 0 ? D_WS : (D_width - !D_CLP);
 		if ((int)strlen(str) > max)
-			AddStrn(str, max);
+			AddRawStrn(str, max);
 		else
-			AddStr(str);
+			AddRawStr(str);
 		AddCStr(D_FS);
 		D_hstatus = true;
 	} else if (D_has_hstatus == HSTATUS_LASTLINE) {
@@ -2141,7 +2147,7 @@ void ChangeScrollRegion(int newtop, int newbot)
 	D_y = D_x = -1;		/* Just in case... */
 }
 
-#define WT_FLAG "2"		/* change to "0" to set both title and icon */
+#define WT_FLAG "0"		/* set both title and icon */
 
 void SetXtermOSC(int i, char *s, char *t)
 {
@@ -2166,7 +2172,7 @@ void SetXtermOSC(int i, char *s, char *t)
 	D_xtermosc[i] = 1;
 	AddStr("\033]");
 	AddStr(oscs[i][0]);
-	AddStr(s);
+	AddRawStr(s);
 	AddStr(t);
 }

@@ -2197,6 +2203,28 @@ void AddStr(char *str)
 		AddChar(c);
 }
 
+/* AddRawStr - Add string without UTF-8 encoding conversion
+ * Used for OSC sequences where the string is already properly encoded
+ */
+void AddRawStr(char *str)
+{
+	char c;
+
+	while ((c = *str++))
+		AddChar(c);
+}
+
+/* AddRawStrn - Add n chars of string without UTF-8 encoding conversion */
+void AddRawStrn(char *str, int n)
+{
+	char c;
+
+	while ((c = *str++) && n-- > 0)
+		AddChar(c);
+	while (n-- > 0)
+		AddChar(' ');
+}
+
 void AddStrn(char *str, int n)
 {
 	char c;
--- a/display.h
+++ b/display.h
@@ -366,6 +366,8 @@ void  MakeStatus (char *);
 void  RemoveStatus (void);
 int   ResizeDisplay (int, int);
 void  AddStr (char *);
+void  AddRawStr (char *);
+void  AddRawStrn (char *, int);
 void  AddStrn (char *, int);
 void  Flush (int);
 void  freetty (void);

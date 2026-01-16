class ScreenUtf8 < Formula
  desc "GNU Screen with UTF-8 title fix - terminal multiplexer with proper Unicode support"
  homepage "https://www.gnu.org/software/screen/"
  url "https://ftp.gnu.org/gnu/screen/screen-5.0.1.tar.gz"
  sha256 "2dae36f4db379ffcd14b691596ba6ec18ac3a9e22bc47ac239789ab58409869d"
  license "GPL-3.0-or-later"

  # Patches UTF-8 support in window/tab titles and hardstatus (OSC sequences)
  # Without this patch, Unicode characters like ★ are truncated and display as control characters
  patch :DATA

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "ncurses"

  # Conflicts with stock screen since they install to the same location
  conflicts_with "screen", because: "both install a `screen` binary"

  def install
    system "./configure", *std_configure_args,
                          "--enable-colors256",
                          "--enable-rxvt_osc",
                          "--enable-telnet",
                          "--with-sys-screenrc=#{etc}/screenrc"
    system "make"
    system "make", "install"

    # Install completion
    bash_completion.install "etc/bash_completion.d/screen" => "screen"
  end

  def caveats
    <<~EOS
      GNU Screen with UTF-8 title fix has been installed.

      This version includes patches that properly handle UTF-8 characters
      in terminal window/tab titles and hardstatus, fixing issues where
      Unicode characters like ★ or ✳ would appear as garbled control characters.

      IMPORTANT: Colors in status bar now use NUMERIC syntax (not letters):
        OLD (deprecated): %{= kK}   (black on bright black)
        NEW: %{= 0;8}               (0=black, 8=bright black)
        TRUECOLOR: %{= #FFFFFF;#000000}   (white on black)

      Add this to your ~/.screenrc for full UTF-8 support:
        defutf8 on
        utf8 on on
        defencoding UTF-8
        encoding UTF-8 UTF-8

      For terminal title passthrough:
        hardstatus on
        hardstatus string '%t'
        defdynamictitle on
    EOS
  end

  test do
    system bin/"screen", "-v"
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
@@ -1314,7 +1338,7 @@ static int StringEnd(Window *win)
 		}
 		return -1;
 	case DCS:
-		LAY_DISPLAYS(&win->w_layer, AddStr(win->w_string));
+		LAY_DISPLAYS(&win->w_layer, AddRawStr(win->w_string));
 		break;
 	case AKA:
 		if (win->w_title == win->w_akabuf && !*win->w_string)
--- a/display.c
+++ b/display.c
@@ -1647,9 +1647,9 @@ void ShowHStatus(char *str)
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
@@ -2141,7 +2141,7 @@ void ChangeScrollRegion(int newtop, int newbot)
 	D_y = D_x = -1;		/* Just in case... */
 }

-#define WT_FLAG "2"		/* change to "0" to set both title and icon */
+#define WT_FLAG "0"		/* set both title and icon */

 void SetXtermOSC(int i, char *s, char *t)
 {
@@ -2166,7 +2166,7 @@ void SetXtermOSC(int i, char *s, char *t)
 	D_xtermosc[i] = 1;
 	AddStr("\033]");
 	AddStr(oscs[i][0]);
-	AddStr(s);
+	AddRawStr(s);
 	AddStr(t);
 }

@@ -2197,6 +2197,28 @@ void AddStr(char *str)
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

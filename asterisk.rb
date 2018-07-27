class Asterisk < Formula
  desc "Open Source PBX and telephony toolkit"
  homepage "http://www.asterisk.org"
  url "http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-13.22.0.tar.gz"
  sha256 "bd5922f19e37c4cfc368e007b15e440bd8c709b5ed53e55496a030429ed7759e"

  patch :p0 do
    url "https://raw.githubusercontent.com/adilinden/homebrew-asterisk/master/patches/asterisk-13.11.2_basic-pbx_install.diff"
    sha256 "ca2d789ba44022408cc12b3b506649d642791bd903e3278b1f3a706021c41929"
  end

  option "with-dev-mode", "Enable dev mode in Asterisk"
  option "with-clang", "Compile with clang instead of gcc"
  option "with-gcc", "Compile with gcc (default)"
  option "without-optimizations", "Disable optimizations"
  option "with-extra-sounds", "Download and install extra and core sounds in ulaw, g729 and gsm"

  if build.without? "clang"
    fails_with :llvm
    fails_with :clang
    # :gcc just matches on apple-gcc42
    fails_with :gcc-7

    depends_on "gcc" => :build
  end

  depends_on "pkg-config" => :build

  depends_on "jansson"
  depends_on "openssl"
  depends_on "pjsip-asterisk"
  depends_on "speex"
  depends_on "sqlite"
  depends_on "homebrew/versions/srtp15"
  depends_on "libxml2"

  def install
    dev_mode = false
    optimize = true
    if build.with? "dev-mode"
      dev_mode = true
      optimize = false
    end

    if build.without? "optimizations"
      optimize = false
    end

    openssl = Formula["openssl"]
    sqlite = Formula["sqlite"]
    pjsip = Formula["pjsip-asterisk"]

    # Some Asterisk code doesn't follow strict aliasing rules
    ENV.append "CFLAGS", "-fno-strict-aliasing"

    # Use brew's pkg-config
    ENV["PKG_CONFIG"] = "#{HOMEBREW_PREFIX}/bin/pkg-config"

    system "./configure", "--prefix=#{prefix}",
                          "--sysconfdir=#{etc}",
                          "--localstatedir=#{var}",
                          "--datadir=#{share}/#{name}",
                          "--docdir=#{doc}",
                          "--enable-dev-mode=no",
                          "--with-pjproject=#{pjsip.opt_prefix}",
                          "--with-sqlite3=#{sqlite.opt_prefix}",
                          "--with-ssl=#{openssl.opt_prefix}",
                          "--without-gmime",
                          "--without-gtk2",
                          "--without-iodbc",
                          "--without-unixodbc",
                          "--without-netsnmp"

    system "make", "menuselect/cmenuselect",
                   "menuselect/nmenuselect",
                   "menuselect/gmenuselect",
                   "menuselect/menuselect",
                   "menuselect-tree",
                   "menuselect.makeopts"

    # Inline function cause errors with Homebrew's gcc-4.8
    system "menuselect/menuselect",
           "--enable", "DISABLE_INLINE", "menuselect.makeopts"
    # Native compilation doesn't work with Homebrew's gcc-4.8
    system "menuselect/menuselect",
           "--disable", "BUILD_NATIVE", "menuselect.makeopts"

    if not optimize
      system "menuselect/menuselect",
             "--enable", "DONT_OPTIMIZE", "menuselect.makeopts"
    end

    if dev_mode
      system "menuselect/menuselect",
             "--enable", "TEST_FRAMEWORK", "menuselect.makeopts"
      system "menuselect/menuselect",
             "--enable", "DO_CRASH", "menuselect.makeopts"
      system "menuselect/menuselect",
             "--enable-category", "MENUSELECT_TESTS", "menuselect.makeopts"
    end

    if build.with? "extra-sounds"
      system "menuselect/menuselect",
             "--enable", "CORE-SOUNDS-EN-ULAW",
             "--enable", "CORE-SOUNDS-EN-GSM",
             "--enable", "CORE-SOUNDS-EN-G729",
             "--enable", "EXTRA-SOUNDS-EN-ULAW",
             "--enable", "EXTRA-SOUNDS-EN-GSM",
             "--enable", "EXTRA-SOUNDS-EN-G729",
             "menuselect.makeopts"
    end

    system "make", "all", "NOISY_BUILD=yes"
    system "make", "install"
    system "make", "ASTETCDIR=#{doc}/samples", "samples"
    system "make", "ASTETCDIR=#{doc}/basic-pbx", "basic-pbx"

    # Replace Cellar references to opt/asterisk
    inreplace doc/"samples/asterisk.conf", prefix, opt_prefix
    #inreplace doc/"basic-pbx/asterisk.conf", prefix, opt_prefix

  end

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
      <key>Label</key>
        <string>#{plist_name}</string>
      <key>KeepAlive</key>
        <true/>
      <key>RunAtLoad</key>
        <true/>
      <key>ProgramArguments</key>
        <array>
          <string>#{opt_sbin}/asterisk</string>
          <string>-f</string>
          <string>-C</string>
          <string>#{etc}/asterisk/asterisk.conf</string>
        </array>
      <key>WorkingDirectory</key>
        <string>#{var}/lib/asterisk</string>
      <key>StandardErrorPath</key>
        <string>#{var}/log/asterisk/asterisk.log</string>
      <key>StandardOutPath</key>
        <string>#{var}/log/asterisk/asterisk.log</string>
      </dict>
    </plist>
    EOS
  end
end

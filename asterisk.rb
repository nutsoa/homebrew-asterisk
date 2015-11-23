class Asterisk < Formula
  desc "Open Source PBX and telephony toolkit"
  homepage "http://www.asterisk.org"
  url "http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-13.6.0.tar.gz"
  sha256 "8a01b53c946d092ac561c11b404f68cd328306d0e3b434a7485a11d4b175005a"

  stable do
    patch :p0 do
      url "https://raw.githubusercontent.com/adilinden/homebrew-asterisk/master/patches/asterisk-13.6.0_basic-pbx.diff"
      sha256 "53a99bd7cfa3dca371c929c5a0f366639c92e4ca7e03e882af5a79756fd11443"
    end
  end

  devel do
    url "https://github.com/asterisk/asterisk.git", :branch => "13"
    version "13.7-devel"

    patch :p0 do
      url "https://raw.githubusercontent.com/adilinden/homebrew-asterisk/master/patches/asterisk-13.7-devel_basic-pbx_install.diff"
      sha256 "09e615e10ecd73838ec68012bed5d93b35d737ecc240e176500a9e0876243cea"
    end
  end

  head do
    url "https://github.com/asterisk/asterisk.git"
    version "14-head"

    patch :p0 do
      url "https://raw.githubusercontent.com/adilinden/homebrew-asterisk/master/patches/asterisk-13.7-devel_basic-pbx_install.diff"
      sha256 "09e615e10ecd73838ec68012bed5d93b35d737ecc240e176500a9e0876243cea"
    end
  end

  option "with-dev-mode", "Enable dev mode in Asterisk"
  option "with-clang", "Compile with clang instead of gcc"
  option "with-gcc", "Compile with gcc (default)"
  option "without-optimizations", "Disable optimizations"

  if build.without? "clang"
    fails_with :llvm
    fails_with :clang
    # :gcc just matches on apple-gcc42
    fails_with :gcc

    depends_on "gcc" => :build
  end

  depends_on "pkg-config" => :build

  depends_on "gmime"
  depends_on "iksemel"
  depends_on "jansson"
  depends_on "homebrew/dupes/ncurses"
  depends_on "openssl"
  depends_on "pjsip-asterisk"
  depends_on "speex"
  depends_on "sqlite"
  depends_on "srtp"
  depends_on "unixodbc"

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
    unixodbc = Formula["unixodbc"]
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
                          "--enable-dev-mode=#{dev_mode ? 'yes' : 'no'}",
                          "--with-pjproject=#{pjsip.opt_prefix}",
                          "--with-sqlite3=#{sqlite.opt_prefix}",
                          "--with-ssl=#{openssl.opt_prefix}",
                          "--with-unixodbc=#{unixodbc.opt_prefix}",
                          "--without-gmime",
                          "--without-gtk2",
                          "--without-iodbc",
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

    system "make", "all", "NOISY_BUILD=yes"
    system "make", "install"
    system "make", "ASTETCDIR=#{doc}/samples", "samples"
    system "make", "ASTETCDIR=#{doc}/basic-pbx", "basic-pbx"

    # Replace Cellar references to opt/asterisk
    inreplace doc/"samples/asterisk.conf", prefix, opt_prefix
    inreplace doc/"basic-pbx/asterisk.conf", prefix, opt_prefix

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

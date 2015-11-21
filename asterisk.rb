class Asterisk < Formula
  desc "Open Source PBX and telephony toolkit"
  homepage "http://www.asterisk.org"
  url "http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-13.6.0.tar.gz"
  sha256 "8a01b53c946d092ac561c11b404f68cd328306d0e3b434a7485a11d4b175005a"

  stable do
    patch :p0, :DATA
  end

  devel do
    url "https://github.com/asterisk/asterisk.git", :branch => "13"
    version "13.7-devel"
  end

  head do
    url "https://github.com/asterisk/asterisk.git"
    version "14-head"
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
        <key>KeepAlive</key>
        <dict>
          <key>SuccessfulExit</key>
          <false/>
        </dict>
        <key>Label</key>
          <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_sbin}/asterisk</string>
          <string>-f</string>
          <string>-C</string>
          <string>#{etc}/asterisk/asterisk.conf</string>
        </array>
         <key>RunAtLoad</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>#{var}</string>
        <key>StandardErrorPath</key>
        <string>#{var}/log/asterisk.log</string>
        <key>StandardOutPath</key>
        <string>#{var}/log/asterisk.log</string>
        <key>ServiceDescription</key>
        <string>Asterisk PBX</string>
      </dict>
    </plist>
    EOS
  end
end

__END__
--- Makefile.orig	2015-11-20 22:02:01.000000000 -0800
+++ Makefile	2015-11-20 22:04:53.000000000 -0800
@@ -124,7 +124,7 @@
 space:=$(empty) $(empty)
 ASTTOPDIR:=$(subst $(space),\$(space),$(CURDIR))
 
-# Overwite config files on "make samples"
+# Overwite config files on "make samples" or other config installation targets
 OVERWRITE=y
 
 # Include debug and macro symbols in the executables (-g) and profiling info (-pg)
@@ -652,7 +651,12 @@
 	@echo " + configuration files (overwriting any      +"
 	@echo " + existing config files), run:              +"
 	@echo " +                                           +"
-	@echo " +               $(mK) samples               +"
+	@echo " + For generic reference documentation:      +"
+	@echo " +   $(mK) samples                           +"
+	@echo " +                                           +"
+	@echo " + For a sample basic PBX:                   +"
+	@echo " +   $(mK) basic-pbx                         +"
+	@echo " +                                           +"
 	@echo " +                                           +"
 	@echo " +-----------------  or ---------------------+"
 	@echo " +                                           +"
@@ -670,24 +674,15 @@
 
 upgrade: bininstall
 
-# XXX why *.adsi is installed first ?
-adsi:
-	@echo Installing adsi config files...
-	$(INSTALL) -d "$(DESTDIR)$(ASTETCDIR)"
-	@for x in configs/samples/*.adsi; do \
-		dst="$(DESTDIR)$(ASTETCDIR)/`$(BASENAME) $$x`" ; \
-		if [ -f "$${dst}" ] ; then \
-			echo "Overwriting $$x" ; \
-		else \
-			echo "Installing $$x" ; \
-		fi ; \
-		$(INSTALL) -m 644 "$$x" "$(DESTDIR)$(ASTETCDIR)/`$(BASENAME) $$x`" ; \
-	done
 
-samples: adsi
-	@echo Installing other config files...
-	@for x in configs/samples/*.sample; do \
-		dst="$(DESTDIR)$(ASTETCDIR)/`$(BASENAME) $$x .sample`" ;	\
+# Install configuration files from the specified directory
+# Parameters:
+#  (1) the configuration directory to install from
+#  (2) the extension to strip off
+define INSTALL_CONFIGS
+	$(INSTALL) -d "$(DESTDIR)$(ASTETCDIR)"
+	@for x in configs/$(1)/*$(2); do \
+		dst="$(DESTDIR)$(ASTETCDIR)/`$(BASENAME) $$x $(2)`"; \
 		if [ -f "$${dst}" ]; then \
 			if [ "$(OVERWRITE)" = "y" ]; then \
 				if cmp -s "$${dst}" "$$x" ; then \
@@ -702,7 +696,7 @@
 		fi ; \
 		echo "Installing file $$x"; \
 		$(INSTALL) -m 644 "$$x" "$${dst}" ;\
-	done
+	done ; \
 	if [ "$(OVERWRITE)" = "y" ]; then \
 		echo "Updating asterisk.conf" ; \
 		sed -e 's|^astetcdir.*$$|astetcdir => $(ASTETCDIR)|' \
@@ -719,10 +713,28 @@
 			"$(DESTDIR)$(ASTCONFPATH)" > "$(DESTDIR)$(ASTCONFPATH).tmp" ; \
 		$(INSTALL) -m 644 "$(DESTDIR)$(ASTCONFPATH).tmp" "$(DESTDIR)$(ASTCONFPATH)" ; \
 		rm -f "$(DESTDIR)$(ASTCONFPATH).tmp" ; \
-	fi ; \
+	fi
+endef
+
+# XXX why *.adsi is installed first ?
+adsi:
+	@echo Installing adsi config files...
+	$(INSTALL) -d "$(DESTDIR)$(ASTETCDIR)"
+	@for x in configs/samples/*.adsi; do \
+		dst="$(DESTDIR)$(ASTETCDIR)/`$(BASENAME) $$x`" ; \
+		if [ -f "$${dst}" ] ; then \
+			echo "Overwriting $$x" ; \
+		else \
+			echo "Installing $$x" ; \
+		fi ; \
+		$(INSTALL) -m 644 "$$x" "$(DESTDIR)$(ASTETCDIR)/`$(BASENAME) $$x`" ; \
+	done
+
+samples: adsi
+	@echo Installing other config files...
+	$(call INSTALL_CONFIGS,samples,.sample)
 	$(INSTALL) -d "$(DESTDIR)$(ASTSPOOLDIR)/voicemail/default/1234/INBOX"
 	build_tools/make_sample_voicemail "$(DESTDIR)/$(ASTDATADIR)" "$(DESTDIR)/$(ASTSPOOLDIR)"
-
 	@for x in phoneprov/*; do \
 		dst="$(DESTDIR)$(ASTDATADIR)/$$x" ;	\
 		if [ -f "$${dst}" ]; then \
@@ -741,6 +753,10 @@
 		$(INSTALL) -m 644 "$$x" "$${dst}" ;\
 	done
 
+basic-pbx:
+	@echo Installing basic-pbx config files...
+	$(call INSTALL_CONFIGS,basic-pbx)
+
 webvmail:
 	@[ -d "$(DESTDIR)$(HTTP_DOCSDIR)/" ] || ( printf "http docs directory not found.\nUpdate assignment of variable HTTP_DOCSDIR in Makefile!\n" && exit 1 )
 	@[ -d "$(DESTDIR)$(HTTP_CGIDIR)" ] || ( printf "cgi-bin directory not found.\nUpdate assignment of variable HTTP_CGIDIR in Makefile!\n" && exit 1 )
@@ -1013,6 +1029,7 @@
 .PHONY: validate-docs
 .PHONY: _clean
 .PHONY: ari-stubs
+.PHONY: basic-pbx
 .PHONY: $(SUBDIRS_INSTALL)
 .PHONY: $(SUBDIRS_DIST_CLEAN)
 .PHONY: $(SUBDIRS_CLEAN)

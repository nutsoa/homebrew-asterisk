  url 'http://www.pjsip.org/release/2.4/pjproject-2.4.tar.bz2'
  sha1 '7a6cbb5128db41372f678ca07128924a0427585f'

  keg_only "Specifically tuned just for asterisk"
    # Hack to truly disable opencore
    # Build for not-debug
    ENV['CFLAGS'] = '-O2 -DNDEBUG'

                          "--enable-shared",
                          "--disable-opencore-amr",
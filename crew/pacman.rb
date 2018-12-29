require 'package'

class Pacman < Package
  description 'A library-based package manager with dependency support.'
  homepage 'http://www.archlinux.org/pacman/'
  version '5.1.2'
  source_url 'https://sources.archlinux.org/other/pacman/pacman-5.1.2.tar.gz'
  source_sha256 'ce4eef1585fe64fd1c65c269e263577261edd7535fe2278240103012d74b6ef6'

  binary_url ({
  })
  binary_sha256 ({
  })

  depends_on 'curl'
  depends_on 'fakeroot'
  depends_on 'glibc'
  depends_on 'gpgme'
  depends_on 'libarchive'
  depends_on 'asciidoc' => :build

  def self.build
    system "./configure",
             "--prefix=#{CREW_PREFIX}",
             "--libdir=#{CREW_LIB_PREFIX}",
             "--with-scriptlet-shell=/bin/bash",
             "--with-ldconfig=/sbin/ldconfig",
             "--with-makepkg-template-dir=#{CREW_PREFIX}/share/makepkg-template",
             "--enable-doc"
    system "make"
  end

  def self.install
    system "make", "DESTDIR=#{CREW_DEST_DIR}", "install"
  end
end

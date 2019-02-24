#! /usr/bin/env bash

set -e

ARCH='x86_64'
MIRROR_URL="https://storage.googleapis.com/capman-repo"
SRC_REPO_URL="https://raw.githubusercontent.com/wwwiiilll/capman/master/local"
PKGEXT='.pkg.tar.xz'

FAKEROOT_VER='1.23-1'
GNUPG_VER='2.2.7-1'
GPGME_VER='1.11.1-1'
LIBARCHIVE_VER='3.3.2-1'
LIBASSUAN_VER='2.5.1-1'
LIBGCRYPT_VER='1.8.1-1'
LIBGPGERROR_VER='1.31-1'
LZ4_VER='1.8.0-1'
NPTH_VER='1.5-1'
XZUTILS_VER='5.2.3-2'

PACMAN_VER='5.1.2-1'
MIRRORS_VER='20181205-1'
KEYRING_VER='20190221-1'

SUDO="/usr/bin/sudo LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
PACMAN="$SUDO /usr/local/bin/pacman --noconfirm"

TMPDIR="/usr/local/tmp/capman"
mkdir -p "$TMPDIR"
trap "rm -rf '$TMPDIR'" EXIT

msg() {
  local msg="$1"; shift
  printf "==> $msg\n" "$@"
}

msg2() {
  local msg="$1"; shift
  printf "  -> $msg\n" "$@"
}

install_pkg() {
  local repo="${2:-core}"
  msg2 "%s" "$1"
  curl -# -Lo "${TMPDIR}/${1}${PKGEXT}" "${MIRROR_URL}/${repo}/os/$ARCH/${1}${PKGEXT}"
  (cd /; $SUDO tar --warning=none -xf "${TMPDIR}/${1}${PKGEXT}" usr/local)
}

build_pkg() {
  local name="$1"; shift
  mkdir -p "$TMPDIR/$name"
  curl -# -Lo "$TMPDIR/$name/PKGBUILD" "$SRC_REPO_URL/$name/PKGBUILD"
  while [ ! -z "$1" ]; do
    curl -# -Lo "$TMPDIR/$name/$1" "$SRC_REPO_URL/$name/$1"
    shift
  done
  (cd "$TMPDIR/$name"; /usr/local/bin/makepkg -d)
  $PACMAN -Udd --noconfirm --overwrite '/*' "$TMPDIR/$name/$name-"*"$PKGEXT"
}

echo -e "\e[33m"
echo 'From here on things will mostly be done as `root`, enter'
echo 'your `sudo` password if prompted.'
echo -e "\e[0m"

if [ -e /lib64/libc-2.27.so ]; then
  GLIBC_PKG=glibc27
  GLIBC_VER='2.27-1'
else
  GLIBC_PKG=glibc23
  GLIBC_VER='2.23-1'
fi

msg 'Installing dependencies...'
install_pkg "fakeroot-$FAKEROOT_VER-$ARCH"
install_pkg "$GLIBC_PKG-$GLIBC_VER-$ARCH" crew
install_pkg "gnupg-$GNUPG_VER-$ARCH" crew
install_pkg "gpgme-$GPGME_VER-$ARCH" crew
install_pkg "libarchive-$LIBARCHIVE_VER-$ARCH" crew
install_pkg "libassuan-$LIBASSUAN_VER-$ARCH" crew
install_pkg "libgcrypt-$LIBGCRYPT_VER-$ARCH" crew
install_pkg "libgpgerror-$LIBGPGERROR_VER-$ARCH" crew
install_pkg "lz4-$LZ4_VER-$ARCH" crew
install_pkg "npth-$NPTH_VER-$ARCH" crew
install_pkg "xzutils-$XZUTILS_VER-$ARCH" crew
if [ ! -e /usr/local/bin/bash ]; then
  $SUDO ln -s /bin/bash /usr/local/bin/bash
fi

msg 'Installing pacman...'
install_pkg "pacman-$PACMAN_VER-$ARCH"
install_pkg "capman-keyring-$KEYRING_VER-any"
install_pkg "pacman-mirrorlist-$MIRRORS_VER-any"

msg 'Initializing the keyring...'
$SUDO /usr/local/bin/pacman-key --init
$SUDO /usr/local/bin/pacman-key --populate capman

msg 'Syncing repositories...'
$PACMAN -Sy

msg 'Building the local bash wrapper package...'
build_pkg "bash"

msg 'Building the local sudo wrapper package...'
build_pkg "sudo" "sudo.sh"

msg 'Re-installing base packages and taking ownership of files...'
$PACMAN -S --noconfirm --overwrite '/*' \
  curl \
  filesystem \
  $GLIBC_PKG \
  capman-keyring \
  gnupg \
  gpgme \
  libarchive \
  libassuan \
  libgcrypt \
  libgpgerror \
  libiconv \
  libpsl \
  libssh2 \
  linux-api-headers \
  lz4 \
  npth \
  pacman \
  pacman-mirrorlist \
  xzutils

echo -e "\e[32m"
echo 'All done! Use `sudo pacman -S <name>` to install and `sudo pacman -Syu`'
echo 'to update your packages.'
echo -e "\e[0m"

#! /usr/bin/env bash

set -e

ARCH='x86_64'
REPO="https://storage.googleapis.com/capman-repo/core/os/$ARCH"
SRC_REPO="https://raw.githubusercontent.com/wwwiiilll/capman/master/local"
PKGEXT='.pkg.tar.xz'

PACMAN_VER='5.1.2-1'
MIRRORS_VER='20190105-1'
KEYRING_VER='20190221-1'

TMPDIR="/usr/local/tmp/capman"
mkdir -p "$TMPDIR"
trap "rm -rf '$TMPDIR'" EXIT

SUDO="/usr/bin/sudo LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
PACMAN="$SUDO /usr/local/bin/pacman --noconfirm"

msg() {
  local msg="$1"; shift
  printf "==> $msg\n" "$@"
}

install_pkg() {
  curl -# -Lo "${TMPDIR}/${1}${PKGEXT}" "${REPO}/${1}${PKGEXT}"
  (cd /; $SUDO tar --warning=none -xf "${TMPDIR}/${1}${PKGEXT}" usr/local)
}

build_pkg() {
  local name="$1"; shift
  mkdir -p "$TMPDIR/$name"
  curl -# -Lo "$TMPDIR/$name/PKGBUILD" "$SRC_REPO/$name/PKGBUILD"
  while [ ! -z "$1" ]; do
    curl -# -Lo "$TMPDIR/$name/$1" "$SRC_REPO/$name/$1"
    shift
  done
  (cd "$TMPDIR/$name"; /usr/local/bin/makepkg -d)
  $PACMAN -Udd --noconfirm --overwrite '/*' "$TMPDIR/$name/$name-"*"$PKGEXT"
}

msg 'Installing runtime dependencies with crew...'
yes | crew install glibc curl gpgme xzutils libarchive fakeroot

echo -e "\e[33m"
echo 'From here on things will mostly be done as `root`, enter'
echo 'your `sudo` password if prompted.'
echo -e "\e[0m"

msg 'Installing pacman...'
install_pkg "pacman-$PACMAN_VER-$ARCH"
install_pkg "pacman-mirrorlist-$MIRRORS_VER-any"
install_pkg "capman-keyring-$KEYRING_VER-any"
if [ ! -f /usr/local/bin/bash ]; then
  $SUDO ln -s /bin/bash /usr/local/bin/bash
fi

msg 'Initializing the keyring...'
$SUDO /usr/local/bin/pacman-key --init
$SUDO /usr/local/bin/pacman-key --populate capman

msg 'Syncing repositories...'
$PACMAN -Sy

msg 'Installing base packages and taking ownership of files...'
$PACMAN -Sdd --noconfirm --overwrite '/*' \
  filesystem \
  linux-api-headers \
  glibc \
  curl \
  gpgme \
  libarchive \
  pacman \
  pacman-mirrorlist \
  capman-keyring

msg 'Building the local bash wrapper package...'
build_pkg "bash"

msg 'Building the local sudo wrapper package...'
build_pkg "sudo" "sudo.sh"

echo -e "\e[32m"
echo 'All done! At this point you must no longer use `crew` to install packages.'
echo 'Instead use `sudo pacman -S <name>` to install and `sudo pacman -Syu`'
echo 'to update your installed packages.'
echo -e "\e[0m"

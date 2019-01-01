#! /usr/bin/env bash

set -e

TMPDIR="/usr/local/tmp/capman"
mkdir -p "$TMPDIR"
trap "rm -rf '$TMPDIR'" EXIT

ARCH='x86_64'
REPO="https://storage.googleapis.com/capman-repo/core/os/$ARCH"
SRC_REPO="https://raw.githubusercontent.com/wwwiiilll/capman/master/local"
PKGEXT='.pkg.tar.xz'

PACMAN_VER='5.1.2-1'
KEYRING_VER='20181230-1'

SUDO="/usr/bin/sudo LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
PACMAN="$SUDO /usr/local/bin/pacman --noconfirm"

install_pkg() {
  curl -# -Lo "${TMPDIR}/${1}${PKGEXT}" "${REPO}/${1}${PKGEXT}"
  (cd /; $SUDO tar --warning=none -xf "${TMPDIR}/${1}${PKGEXT}" usr/local/)
}

build_pkg() {
  name="$1"
  mkdir -p "$TMPDIR/$name"
  curl -# -Lo "$TMPDIR/$name/PKGBUILD" "$SRC_REPO/$name/PKGBUILD"
  while [ ! -z "$2" ]; do
    curl -# -Lo "$TMPDIR/$name/$2" "$SRC_REPO/$name/$2"
    shift
  done
  (cd "$TMPDIR/$name"; /usr/local/bin/makepkg -d)
  $PACMAN -Udd --noconfirm --overwrite '/*' "$TMPDIR/$name/$name-"*"$PKGEXT"
}

echo '==> Installing runtime dependencies with crew...'
for pkg in glibc curl gpgme xzutils libarchive fakeroot; do
  yes | crew install $pkg
done

echo -e "\e[33m"
echo 'From here on things will mostly be done as `root`, enter'
echo 'your `sudo` password if prompted.'
echo -e "\e[0m"

echo '==> Installing pacman...'
install_pkg "pacman-$PACMAN_VER-$ARCH"
if [ ! -f /usr/local/bin/bash ]; then
  $SUDO ln -s /bin/bash /usr/local/bin/bash
fi

echo '==> Installing the keyring...'
install_pkg "capman-keyring-$KEYRING_VER-any"

echo '==> Initializing the keyring...'
$SUDO /usr/local/bin/pacman-key --init
$SUDO /usr/local/bin/pacman-key --populate capman

echo '==> Syncing repositories...'
$PACMAN -Sy

echo '==> Installing base packages and taking ownership of files...'
$PACMAN -Sdd --noconfirm --overwrite '/*' \
  filesystem \
  linux-api-headers \
  glibc \
  curl \
  gpgme \
  libarchive \
  pacman \
  capman-keyring

echo '==> Building the local bash wrapper package...'
build_pkg "bash"

echo '==> Building the local sudo wrapper package...'
build_pkg "sudo" "sudo.sh"

echo -e "\e[32m"
echo 'All done! At this point you must no longer use `crew` to install packages.'
echo 'Instead use `sudo pacman -S <name>` to install and `sudo pacman -Syu`'
echo 'to update your installed packages.'
echo -e "\e[0m"

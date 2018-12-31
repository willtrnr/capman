#! /usr/bin/env bash

set -e

TMPDIR="/usr/local/tmp/capman"
mkdir -p "$TMPDIR"
trap "rm -rf '$TMPDIR'" EXIT

ARCH='x86_64'
REPO="https://storage.googleapis.com/capman-repo/core/os/$ARCH"
PKGEXT='.pkg.tar.xz'

PACMAN_VER='5.1.2-1'
KEYRING_VER='20181230-1'

SUDO="/usr/bin/sudo LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
PACMAN="$SUDO /usr/local/bin/pacman --noconfirm"

install_pkg() {
  curl -Lo "${TMPDIR}/${1}${PKGEXT}" "${REPO}/${1}${PKGEXT}"
  (cd /; $SUDO tar --warning=none -xf "${TMPDIR}/${1}${PKGEXT}" usr/local/)
}

echo '==> Installing runtime dependencies with crew...'
for pkg in glibc curl gpgme xzutils libarchive; do
  yes | crew install $pkg
done

echo -e "\e[33m"
echo 'From here on things will mostly be done as `root`, enter'
echo 'your `sudo` password if prompted.'
echo -e "\e[0m"

echo '==> Installing pacman...'
install_pkg "pacman-$PACMAN_VER-$ARCH"

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
  glibc \
  curl \
  gpgme \
  libarchive \
  pacman \
  capman-keyring

echo '==> Building the local Linux headers package...'
mkdir -p "$TMPDIR/linux-api-headers"
curl -Lo "$TMPDIR/linux-api-headers/PKGBUILD" https://raw.githubusercontent.com/wwwiiilll/capman/master/local/linux-api-headers/PKGBUILD
(cd "$TMPDIR/linux-api-headers"; makepkg -d)
$PACMAN -Udd --noconfirm --overwrite '/*' "$TMPDIR/linux-api-headers/linux-api-headers-"*"$PKGEXT"

echo '==> Building the local bash wrapper package...'
mkdir -p "$TMPDIR/bash"
curl -Lo "$TMPDIR/bash/PKGBUILD" https://raw.githubusercontent.com/wwwiiilll/capman/master/local/bash/PKGBUILD
(cd "$TMPDIR/bash"; makepkg -d)
$PACMAN -Udd --noconfirm --overwrite '/*' "$TMPDIR/bash/bash-"*"$PKGEXT"

echo '==> Building the local sudo wrapper package...'
mkdir -p "$TMPDIR/sudo"
curl -Lo "$TMPDIR/sudo/PKGBUILD" https://raw.githubusercontent.com/wwwiiilll/capman/master/local/sudo/PKGBUILD
curl -Lo "$TMPDIR/sudo/sudo.sh" https://raw.githubusercontent.com/wwwiiilll/capman/master/local/sudo/sudo.sh
(cd "$TMPDIR/sudo"; makepkg -d)
$PACMAN -Udd --noconfirm --overwrite '/*' "$TMPDIR/sudo/sudo-"*"$PKGEXT"

echo -e "\e[32m"
echo 'All done! At this point you must no longer use `crew` to install packages.'
echo 'Instead use `sudo pacman -S <name>` to install and `sudo pacman -Syu`'
echo 'to update your installed packages.'
echo -e "\e[0m"

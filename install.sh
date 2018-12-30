#! /usr/bin/env bash

set -e

TMPDIR="$(mktemp -d)"
trap "rm -rf '${TMPDIR}'" EXIT

ARCH='x86_64'
REPO="https://storage.googleapis.com/capman-repo/core/os/$ARCH"
PKGEXT='.pkg.tar.xz'

SUDO="/usr/bin/sudo LD_LIBRARY_PATH=$LD_LIBRARY_PATH"

echo 'Installing runtime dependencies with crew...'
for pkg in glibc curl gpgme xzutils libarchive; do
  yes | crew install $pkg
done

install_pkg() {
  curl -Lo "${TMPDIR}/${1}${PKGEXT}" "${REPO}/${1}${PKGEXT}"
  (cd /; $SUDO tar --warning=none -xf "${TMPDIR}/${1}${PKGEXT}" usr/local/)
}

echo 'Installing pacman...'
install_pkg "pacman-5.1.2-1-$ARCH"

echo 'Installing the keyring...'
install_pkg 'capman-keyring-20181230-1-any'

echo 'Initializing the keyring...'
$SUDO /usr/local/bin/pacman-key --init
$SUDO /usr/local/bin/pacman-key --populate capman

echo 'Syncing repositories...'
$SUDO /usr/local/bin/pacman -Sy

echo 'Taking ownership of the package files...'
$SUDO /usr/local/bin/pacman -Sdd --noconfirm --overwrite '/usr/local/*' pacman capman-keyring glibc curl gpgme libarchive

echo 'Building the local bash package...'
mkdir -p "$TMPDIR/bash"
curl -Lo "$TMPDIR/bash/PKGBUILD" https://raw.githubusercontent.com/wwwiiilll/capman/master/local/bash/PKGBUILD
(cd "$TMPDIR/bash"; makepkg -d)
$SUDO /usr/local/bin/pacman -Udd --noconfirm "$TMPDIR/bash/bash-"*"$PKGEXT"

echo 'Building the local sudo package...'
mkdir -p "$TMPDIR/sudo"
curl -Lo "$TMPDIR/sudo/PKGBUILD" https://raw.githubusercontent.com/wwwiiilll/capman/master/local/sudo/PKGBUILD
curl -Lo "$TMPDIR/sudo/sudo.sh" https://raw.githubusercontent.com/wwwiiilll/capman/master/local/sudo/sudo.sh
(cd "$TMPDIR/sudo"; makepkg -d)
$SUDO /usr/local/bin/pacman -Udd --noconfirm "$TMPDIR/sudo/sudo-"*"$PKGEXT"

echo -e "\e[32m"
echo 'All done! At this point you must no longer use `crew` to install packages.'
echo 'Instead use `pacman -S <name>` to install and `pacman -Syu` to update.'
echo -e "\e[0m"

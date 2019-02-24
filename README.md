Capman
======

Use ArchLinux's Pacman package manager to manage packages on Chrome OS.

The goal of this is not to be able to install the regular Arch packages,
but to provide a distinct pacman repository of Chrome OS packages.

The `crew` repository contains repackaged versions of the Chromebrew
binary packages. However, there is a lot of issues with missing or wrong
dependencies in the original package definitions, so expect having to fix
things manually.

Install
-------

Run the following (it's safe, I swear, but please read scripts before
running them):

```sh
curl -Ls https://raw.githubusercontent.com/wwwiiilll/capman/master/install.sh | bash
```

Usage
-----

[See the ArchLinux wiki page on Pacman](https://wiki.archlinux.org/index.php/Pacman)

Why
---

You might be wondering why use pacman instead of Crostini, Crouton or
Chromebrew.

Here are a couple of motivations for this project:

- chroots are heavy in size since they have to bring in quite a lot of
  dependencies and sharing files gets a bit weird.

- Crostini is nice, but we already have Gentoo out of the box, why install
  another (lesser) distribution. Plus, not all Chromebook models support
  it.

- Chromebrew is also nice, but isn't without issues:

  - Files are installed as `chronos`, any user with terminal access ends up
    an administrator of the "system".

  - No true dependency tracking or orphan management, removing a package
    leaves its dependants in-place and unused libraries are hard to
    identify.

  - The Ruby DSL for packages and makes porting packages harder than necessary.
    Packaging additional build files such as patches is not easily doable and
    essentially resorts to hacks.

  - In addition to the Ruby issue, some packages are not declarative and depend
    on current system state. Check the `php` and `glibc` packages for exemples.

  - No way to express `conflicts` or `provides` between packages, this
    makes providing alternatives difficult.

  - To add to the previous point, no file ownership enforcement is made,
    files can end up belonging to multiple packages. No reference counting
    is made either, so files are removed as soon as one of the owning
    package is removed.

  - Some of the packages install files in `$HOME`.

  - Locally built packages cannot be easily shared or installed. Users are
    also unable to add multiple package sources.

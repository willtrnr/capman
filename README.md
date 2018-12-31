Capman
======

Use ArchLinux's Pacman package manager to manage packages on Chrome OS.

The goal of this is not to be able to install the regular Arch packages,
but to provide a distinct pacman repository of Chrome OS packages.

Install
-------

Head over to [Chromebrew](http://skycocker.github.io/chromebrew/) to
install `crew` if you haven't already done so.

Then run the following (it's safe, I swear, but please read scripts before
running them):

```sh
curl -Ls https://raw.githubusercontent.com/wwwiiilll/capman/master/install.sh | bash
```

After installing pacman, crew should no longer be used.

Usage
-----

[See the ArchLinux wiki page on Pacman](https://wiki.archlinux.org/index.php/Pacman)

Why
---

You might be wondering why use pacman instead of Crostini, Crouton or
Chromebrew, even more so since we need it for the installation.

Here are a couple of motivations for this project:

- chroots are heavy in size since they have to bring in quite a lot of
  dependencies and sharing files gets a bit weird.

- Crostini is nice, but we already have Gentoo out of the box, why install
  another (lesser) distribution. Plus, not all Chromebook models support
  it.

- Chromebrew is very nice, but isn't without issues:

  - Files are install as `chronos`, any user with terminal access ends up
    an administrator of the "system".

  - No true dependency tracking or orphan management, removing a package
    leaves its dependants in-place and unused libraries are hard to
    identify.

  - The Ruby DSL for packages is not common and makes porting packages
    harder than necessary. Packaging additional build files such as patches
    is not easily doable and resorts to hacks.

  - No way to express `conflicts` or `provides` between packages, this
    makes providing alternatives difficult.

  - To add to the previous point, no file ownership enforcement is made,
    files can end up belonging to multiple packages. No reference counting
    is made, so files are removed as soon as one of the owning package is
    removed.

  - Some of the packages install files in `$HOME`.

  - Locally built packages cannot be easily shared or installed. Users are
    also unable to add multiple package sources.

  - Package updates ultimately rests on the shoulders of the project
    maintainers with very few options to make it otherwise.

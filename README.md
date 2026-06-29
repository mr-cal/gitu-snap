<h1 style="text-align: center;">
  Gitu
</h1>

<p style="text-align: center;"><b>This is the snap for <a href="https://github.com/altsem/gitu">Gitu</a></b>, <i>"A TUI Git client inspired by Magit"</i>. It works on Ubuntu, Fedora, Debian, and other major Linux
distributions.</p>

## Install

    sudo snap install gitu --beta

[![Get it from the Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-white.svg)](https://snapcraft.io/gitu)

([Don't have snapd installed?](https://snapcraft.io/docs/core/install))


## Snap Configuration

| option | default | description                                                                                                       |
|--------|---------|-------------------------------------------------------------------------------------------------------------------|
| editor | vim     | The editor to use for interactive commands such as `rebase` and `commit`. Supported editors are `vim` and `nano`. |

You can change Snap configuration by running `snap set gitu <key>=<value>`. For example, `snap set gitu editor=vim`.

## GPG commit signing

Signed commits are supported after connecting the `dot-gnupg` personal-files interface:

    snap connections gitu
    snap connect gitu:dot-gnupg
## SSH access

To push, pull, and fetch from remotes via ssh such as `git@github.com:mr-cal/gitu-snap`, you need to provide the snap with read access to your ssh keys:

    snap connections gitu
    snap connect gitu:ssh-keys

## Contributing

Contributions are welcome in the form of issues, pull requests, and general feedback.

This snap and the upstream [Gitu](https://github.com/altsem/gitu) project are both in development. 
* For issues that can only be reproduced when used as a snap, file an [issue](https://github.com/mr-cal/gitu-snap/issues) in this repository.
* For Gitu issues that can be reproduced when not installed as a snap, use the [Gitu issue tracker](https://github.com/altsem/gitu/issues).
* For general snap issues, see the [forum](https://forum.snapcraft.io/) and [documentation](https://snapcraft.io/docs) for more information.

<!--
[proast](status:todo)
-->
Generic Utilities By GUBG
=========================

## License

This software is licensed under the EUPL v1.1 license with the explicit interpretation of the term _modification_ as explained in [license.txt](license.txt).

I try to be as permissive as possible, when in doubt, please contact me.

## Installation

### Dependencies

Install the required dependencies.

#### Ubuntu

##### Common

`sudo apt install vim-gnome silversearcher-ag meld bless git automake libtool-bin cmake python-dev ruby-dev uuid-dev freeglut3 freeglut3-dev libxcb-image0 libxcb-image0-dev libudev-dev libjpeg-dev libopenal-dev libvorbis-dev libflac-dev libfreetype6-dev gcc-avr avr-libc wmctrl libxrandr-dev libegl1-mesa-dev`
`sudo apt install sox nemiver audacity tree`
`sudo apt install network-manager-vpnc-gnome`

##### 16.04

`sudo apt install libgnutls-dev`

#### Arch/Manjaro

Install _yaourt_

`sudo pacman -S --needed base-devel`
`mkdir tmp && cd tmp`
`git clone https://aur.archlinux.com/package-query.git && cd package-query && makepkg -si && cd ..`
`git clone https://aur.archlinux.com/yaourt.git && cd yaourt && makepkg -si && cd ..`
`cd ..`

Install other packages

`yaourt -S --noconfirm gcc-multilib gvim wmctrl ruby ruby-rake nemiver meld bless tk arduino-avr-core make ninja cmake the_silver_searcher`
`yaourt -S --noconfirm audacity sox tree inkscape pandoc chromium gnuplot fakeroot patch slack-desktop xclip`
`yaourt -S --noconfirm neovim neovim-qt neovim-plug python-neovim xsel`
`yaourt -S --noconfirm qtcreator gnome-shell-extension-system-monitor-git`
`yaourt -S --noconfirm neovim-plug-git`

Install nvidia drivers

`sudo mhwd -a pci nonfree 0300`

#### Dependencies for Void linux

`sudo xbps-install neovim git-all ruby-devel gcc gcc-c++ make cmake pkg-config curl wget libtool automake unzip python-devel gnutls-devel libX11-devel glxinfo MesaLib-devel glu-devel libxcb-devel xcb-util-image-devel jpeg-devel libopenal-devel libflac-devel libvorbis-devel freetype-devel vim gvim xterm the_silver_searcher meld`

### Clone the repo

`git clone https://github.com/gfannes/gubg`
`cd gubg`
`git submodule update --init`

### Setup environment

Set the `gubg` environment variable to an absolute path:

`export gubg=$HOME/gubg`
`export PATH=$PATH:$gubg/bin`

Set the `Custom command` in the `gnome-terminal`:

`bash --init-file /<path_to_gubg>/bin/personal.gfannes.sh`

Load this same start-up script from `.bash_profile` to ensure `tmux` load it as well. Append this line:

`. $gubg/bin/personal.gfannes.sh`

Optionally, create the `$HOME/gubg.sh` script to perform custom operations.

### Update and install

`git submodule update --init --recursive`
`rake prepare`
`rake run`

## Features

* [external](key:gubg.algo)
* [external](key:gubg.io)
* [external](key:gubg.std)
* [external](key:gubg.math)
* [external](key:gubg.arduino)
* [external](key:gubg.chaiscript)
* [external](key:gubg.build)
* [external](key:gubg.data)
* [external](key:gubg.ml)
* [external](key:gubg.tools.pm)
* [external](key:gubg.tools)
* [external](key:gubg.ui)

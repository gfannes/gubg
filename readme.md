Generic Utilities By GUBG
=========================

## License

This software is licensed under the EUPL v1.1 license with the explicit interpretation of the term _modification_ as explained in [license.txt](license.txt).

I try to be as permissive as possible, when in doubt, please contact me.

## Installation

### Dependencies

Install the required dependencies.

#### Ubuntu 16.04

`sudo apt install vim-gnome silversearcher-ag meld bless git automake libtool-bin cmake python-dev ruby-dev libgnutls-dev uuid-dev freeglut3 freeglut3-dev libxcb-image0 libxcb-image0-dev libudev-dev libjpeg-dev libopenal-dev libvorbis-dev libflac-dev libfreetype6-dev gcc-avr avr-libc wmctrl libxrandr-dev`

#### Arch/Manjaro

`sudo pacman -S gcc-multilib gvim wmctrl ruby nemiver meld bless tk arduino-avr-core make ninja cmake qtcreator the_silver_searcher`
`sudo pacman -S yaourt audacity tree inkscape pandoc chromium gnuplot fakeroot patch`

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

### Update and install

`git submodule update --init --recursive`
`rake prepare`
`rake run`


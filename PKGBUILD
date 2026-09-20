# Maintainer: OpalAayan <https://github.com/OpalAayan>
# opalshell — A beautiful Wayland status bar for Hyprland, built with QuickShell

pkgname=opalshell
pkgver=1.0.0
pkgrel=1
pkgdesc='A beautiful Wayland status bar for Hyprland, built with QuickShell'
arch=('x86_64')
url='https://github.com/OpalAayan/opalshell'
license=('GPL-3.0-or-later')

depends=(
    'quickshell'
    'qt6-declarative'
    'qt6-wayland'
    'networkmanager'
    'bluez'
    'bluez-utils'
    'wireplumber'
    'brightnessctl'
    'kitty'
    'btop'
    'libnotify'
    'dbus'
)

makedepends=(
    'gcc'
    'make'
    'pkgconf'
)

optdepends=(
    'power-profiles-daemon: Power profile switching'
    'hyprpicker: Color picker tool'
    'wl-clipboard: Clipboard support for color picker'
    'imagemagick: Color picker icon generation'
    'fuzzel: App launcher (default)'
    'rofi: App launcher (alternative)'
    'wofi: App launcher (alternative)'
    'wl-gammarelay-rs: Night light / color temperature control'
    'dunst: Notification daemon with dunstify'
    'ttf-jetbrains-mono-nerd: Primary bar font'
    'ttf-rubik: Secondary text font'
)

source=("git+${url}.git")
sha256sums=('SKIP')

build() {
    cd "$srcdir/$pkgname"
    make
}

package() {
    cd "$srcdir/$pkgname"
    make install DESTDIR="$pkgdir" PREFIX=/usr
}

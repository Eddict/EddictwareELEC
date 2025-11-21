# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2025-present Eddict (14122921+Eddict@users.noreply.github.com)

PKG_NAME="opkg"
PKG_LICENSE="GPL"
PKG_SITE="https://entware.net/"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Dummy opkg package for Entware."
PKG_TOOLCHAIN="manual"

post_makeinstall_target() {
	true
}

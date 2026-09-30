# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2020-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libudfread"
PKG_VERSION="1.2.0"
PKG_SHA256="adcce1190925f9d35a477757c5e3f0e221315d14d3d45b4ae62540ea0925f877"
PKG_LICENSE="LGPL-2.1-or-later"
PKG_SITE="https://code.videolan.org/videolan/libudfread"
PKG_URL="https://code.videolan.org/videolan/${PKG_NAME}/-/archive/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="UDF reader"
PKG_BUILD_FLAGS="+pic"

PKG_ALT_SHA256="bb477cbd4cfbfc7787d9d05b71ee5e70430f5cfebf1297497f7e83547958050f"
PKG_ALT_URL="https://download.videolan.org/pub/videolan/${PKG_NAME}/${PKG_NAME}-${PKG_VERSION}.tar.xz"

PKG_MESON_OPTS_TARGET="-Ddefault_library=both"

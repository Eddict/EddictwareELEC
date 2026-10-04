# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="EddictwareELEC-settings"
PKG_VERSION="ed90bc50f87e0aabe8e2fad6ae08b279c040ee19"
PKG_SHA256="9d539c066c63e62a80e7e160ff638d80fe59aeaaaabb51c2a2a267712106574c"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/Eddict/service.eddictwareelec.settings"
PKG_URL="https://github.com/Eddict/service.eddictwareelec.settings/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain Python3 connman dbussy"
PKG_LONGDESC="EddictwareELEC-settings: is a settings dialog for EddictwareELEC"

PKG_MAKE_OPTS_TARGET="ADDON_VERSION=${OS_VERSION} \
                      DISTRONAME=${DISTRONAME} \
                      ROOT_PASSWORD=${ROOT_PASSWORD}"

if [ "${DISPLAYSERVER}" = "x11" ]; then
  PKG_DEPENDS_TARGET+=" setxkbmap"
else
  PKG_DEPENDS_TARGET+=" bkeymaps"
fi

post_makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libreelec
    cp ${PKG_DIR}/scripts/* ${INSTALL}/usr/lib/libreelec
    sed -e "s/@DISTRONAME@/${DISTRONAME}/g" \
      -i ${INSTALL}/usr/lib/libreelec/backup-restore
    sed -e "s/@DISTRONAME@/${DISTRONAME}/g" \
      -i ${INSTALL}/usr/lib/libreelec/factory-reset

  ADDON_INSTALL_DIR=${INSTALL}/usr/share/kodi/addons/service.eddictwareelec.settings
  python_compile ${ADDON_INSTALL_DIR}/resources/lib/
}

post_install() {
  enable_service backup-restore.service
  enable_service factory-reset.service
}

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="EddictwareELEC-settings"
PKG_VERSION="66cd2634a1e055779b752b47990b019208f9ea33"
PKG_SHA256="13b7f61641f65b5ba5afad026f9e7bcf7e7f7ad911408bc1834f5c0ef860b1a7"
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

#!/bin/bash

source debian/vars.sh

set -x

echo "SOURCE7 :$SOURCE7:"
ls -ld $SOURCE7

mkdir -p $DEB_INSTALL_ROOT/usr/local/bin
install -m 755 $SOURCE1 $DEB_INSTALL_ROOT/usr/local/bin
install -m 755 $SOURCE2 $DEB_INSTALL_ROOT/usr/local/bin
install -m 755 $SOURCE3 $DEB_INSTALL_ROOT/usr/local/bin
install -m 755 $SOURCE5 $DEB_INSTALL_ROOT/usr/local/bin
mkdir -p $DEB_INSTALL_ROOT/etc/cpanel/ea4
install -m 644 $SOURCE7 $DEB_INSTALL_ROOT/etc/cpanel/ea4/ea4-metainfo.json

mkdir -p $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-nginx-http2
install -m 644 $SOURCE14 $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-nginx-http2/on.json
install -m 644 $SOURCE15 $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-nginx-http2/off.json
for pkg in ea-nginx-gzip ea-nginx-brotli ea-nginx-standalone ea-nginx-njs; do
    mkdir -p $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/${pkg}
    ln -s ../ea-nginx-http2/off.json $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/${pkg}/off.json
done

mkdir -p $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php54-php
mkdir -p $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php54-php-cli
mkdir -p $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php54-php-common
install -m 644 $SOURCE4 $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php54-php/dso.json
install -m 644 $SOURCE10 $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php54-php-cli/important.json
install -m 644 $SOURCE10 $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php54-php-common/important.json
for pkg in php php-cli php-common; do
    ln -s ea-php54-${pkg} $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php55-${pkg}
    ln -s ea-php54-${pkg} $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php56-${pkg}
    ln -s ea-php54-${pkg} $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php70-${pkg}
    ln -s ea-php54-${pkg} $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php71-${pkg}
    ln -s ea-php54-${pkg} $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php72-${pkg}
    ln -s ea-php54-${pkg} $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php73-${pkg}
    ln -s ea-php54-${pkg} $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php74-${pkg}
    ln -s ea-php54-${pkg} $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php80-${pkg}
done
mkdir -p $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php54
install -m 644 $SOURCE6 $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php54/eol.json
ln -s ea-php54 $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php55
ln -s ea-php54 $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php56
ln -s ea-php54 $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php70
ln -s ea-php54 $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php71
ln -s ea-php54 $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php72
ln -s ea-php54 $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-php73
mkdir -p $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-ruby24-mod_passenger
install -m 644 $SOURCE11 $DEB_INSTALL_ROOT/etc/cpanel/ea4/recommendations/ea-ruby24-mod_passenger/eol.json
mkdir -p $DEB_INSTALL_ROOT/usr/local/cpanel/whostmgr/etc/
install -m 644 $SOURCE8 $DEB_INSTALL_ROOT/usr/local/cpanel/whostmgr/etc/
install -m 644 $SOURCE9 $DEB_INSTALL_ROOT/usr/local/cpanel/whostmgr/etc/

mkdir -p $hooks_base/ea-__WILDCARD__
mkdir -p $hooks_base_pre/ea-__WILDCARD__
install -m 755 $SOURCE12 $hooks_base/ea-__WILDCARD__
install -m 755 $SOURCE12 $hooks_base_pre/ea-__WILDCARD__

mkdir -p $DEB_INSTALL_ROOT/etc/cpanel/ea4/option-flags/
install -m 644 $SOURCE13 $DEB_INSTALL_ROOT/etc/cpanel/ea4/option-flags/README.md

mkdir -p $DEB_INSTALL_ROOT/etc/cpanel/ea4/profiles/
install -m 0644 $SOURCE16 $DEB_INSTALL_ROOT/etc/cpanel/ea4/profiles/pkg-manifest.json


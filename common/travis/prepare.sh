#!/bin/bash
#
# prepare.sh

set -e

/bin/echo -e '\x1b[32mUpdating etc/conf...\x1b[0m'
echo DULGE_BUILD_ENVIRONMENT=jaguar-packages-ci >> etc/conf
echo DULGE_ALLOW_RESTRICTED=yes >> etc/conf

/bin/echo -e '\x1b[32mEnabling uchroot chroot-style...\x1b[0m'
echo DULGE_CHROOT_CMD=uchroot >> etc/conf

/bin/echo -e '\x1b[32mBootstrapping...\x1b[0m'

./dulge-src binary-bootstrap

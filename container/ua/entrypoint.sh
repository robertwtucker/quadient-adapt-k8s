#!/usr/bin/env bash

set -e

ADAPT_PATH=/opt/adapt

## Create symbolic links to license and configuration files
ln -sf ${ADAPT_PATH}/etc/adeptua.lic ${ADAPT_PATH}/ua/adeptua.lic
ln -sf ${ADAPT_PATH}/etc/*.ini ${ADAPT_PATH}/ua/

exec "$@"

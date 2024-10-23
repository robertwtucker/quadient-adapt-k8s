#!/usr/bin/env bash

set -e

[ "${DEBUG}" == 'true' ] && set -x

: ${ADAPT_PATH:=/opt/adapt}

# Create symbolic links to license and configuration files provided
# in the etc directory.
for FILE in "${ADAPT_PATH}"/etc/*; do
	ln -sf "${FILE}" "${ADAPT_PATH}"/ua/$(basename ${FILE})
done

# If required, populate the shared volume with the contents of
# of the ua directory.
if [ "$(basename $1)" == "share" ]; then
	cp -RL "${ADAPT_PATH}"/ua/* "${ADAPT_PATH}"/share
else
	exec "$@"
fi

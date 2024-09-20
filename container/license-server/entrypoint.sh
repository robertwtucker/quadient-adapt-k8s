#!/usr/bin/env bash

set -e

[ "${DEBUG}" == 'true' ] && set -x

stop() {
    echo "Received SIGINT or SIGTERM. Shutting down cdplicser"
    pid=$(cat /var/run/adapt/cdplicser.pid)
	if test -d /proc/"${pid}"/; then
    	kill -SIGTERM "${pid}"
        wait "${pid}"
	fi
    echo "Done."
}

if [ "$(basename $1)" == "cdplicser" ]; then
    trap stop SIGINT SIGTERM
    "$@" &
    pid="$!"
    echo "${pid}" > /var/run/adapt/cdplicser.pid
    wait "${pid}" && exit $?
else
    exec "$@"
fi

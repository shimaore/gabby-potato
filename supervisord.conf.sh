#!/bin/bash
DEFAULT_SUPERVISOR_PORT=5700
SUPERVISOR_PORT="${SUPERVISOR_PORT:-${DEFAULT_SUPERVISOR_PORT}}"
sed -e "s/SUPERVISORD_PORT/${SUPERVISOR_PORT}/" supervisord.conf.src > supervisord.conf
exec /usr/bin/supervisord -n

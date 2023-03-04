#!/usr/bin/env bash

set -eEo pipefail

AGPL_DIR="/agpl"
DATA_DIR="/data"

umask 0077

usage() {
    retcode="${1:-0}"
    echo "To run agpl from Docker:"
    echo ""
    echo "docker run --cap-drop=all -it -v <path to configurations>:"${DATA_DIR}" harryhoyle/agpl:latest"
    echo ""
    exit ${retcode}
}

if [ ! -f "${DATA_DIR}"/config.cfg ] ; then
  echo "Looks like you're not bind-mounting your config.cfg into this container."
  echo "Agpl needs a configuration file to run."
  echo ""
  usage -1
fi

if [ ! -e /dev/console ] ; then
  echo "Looks like you're trying to run this container without a TTY."
  echo "If you don't pass `-t`, you can't interact with the Agpl script."
  echo ""
  usage -1
fi

# To work around problems with bind-mounting Windows volumes, we need to
# copy files out of ${DATA_DIR}, ensure appropriate line endings and permissions,
# then copy the agpl-generated files into ${DATA_DIR}.

tr -d '\r' < "${DATA_DIR}"/config.cfg > "${AGPL_DIR}"/config.cfg
test -d "${DATA_DIR}"/configs && rsync -qLktr --delete "${DATA_DIR}"/configs "${AGPL_DIR}"/

"${AGPL_DIR}"/algo "${AGPL_ARGS[@]}"
retcode=${?}

rsync -qLktr --delete "${AGPL_DIR}"/configs "${DATA_DIR}"/
exit ${retcode}

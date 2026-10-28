#!/usr/bin/env bash
if [[ "$*" == *kern.memorystatus_vm_pressure_level* ]]; then
  echo "${FAKE_PRESSURE_LEVEL:-1}"
else
  exec /usr/sbin/sysctl "$@"
fi

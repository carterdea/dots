#!/bin/bash
if [[ "$1" == -MTime::HiRes=time ]]; then
  if [[ -e "$CI_TEST_CLOCK_MARKER" ]]; then
    printf '4600000'
  else
    touch "$CI_TEST_CLOCK_MARKER"
    printf '1000000'
  fi
else
  exec "$CI_TEST_REAL_PERL" "$@"
fi

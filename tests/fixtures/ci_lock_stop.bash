set -T
trap 'if [[ "$BASH_COMMAND" == remaining=* ]]; then trap - DEBUG; touch "$CI_TEST_STOP_MARKER"; kill -STOP "$$"; fi' DEBUG

trap 'if [[ "$BASH_COMMAND" == "child=\$!" ]]; then kill -TERM "$$"; fi' DEBUG

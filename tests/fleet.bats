#!/usr/bin/env bats

setup() {
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" && pwd )"
    FLEET="$(dirname "$DIR")/bin/fleet"
    export FLEET_HOSTS_FILE="$BATS_TEST_TMPDIR/hosts"
    mkdir "$BATS_TEST_TMPDIR/bin"
    cat > "$BATS_TEST_TMPDIR/bin/ssh" <<'SH'
#!/bin/sh
for arg; do host=$prev; prev=$arg; done
[ "$host" = down ] && { echo "connect failed"; exit 255; }
HOST=$host sh -c "$arg"
SH
    chmod +x "$BATS_TEST_TMPDIR/bin/ssh"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

@test "runs the command on every host in file order" {
    printf 'mini\n# comment\n\nlinux\n' > "$FLEET_HOSTS_FILE"
    run "$FLEET" 'echo "hi from $HOST"'
    [ "$status" -eq 0 ]
    [ "$output" = $'== mini\nhi from mini\n== linux\nhi from linux' ]
}

@test "reports an unreachable host and exits non-zero" {
    printf 'mini\ndown\n' > "$FLEET_HOSTS_FILE"
    run "$FLEET" true
    [ "$status" -eq 1 ]
    [[ "$output" == *"== down (exit 255)"$'\n'"connect failed"* ]]
}

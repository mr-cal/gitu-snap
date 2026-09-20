#!/bin/sh

# Load persistent snap configuration (e.g. editor settings)
. "$SNAP_DATA/env"

# Allow overriding the binary (defaults to gitu; tests can point this to git or stubs)
GITU_BIN="${GITU_BIN:-$SNAP/bin/gitu}"

emit_dot_gnupg_warning() {
    cat >&2 <<'EOF'
[gitu snap] warning: gpg-related operation failed and dot-gnupg is not connected.
[gitu snap] warning: run `snap connections gitu` and then `snap connect gitu:dot-gnupg`.
EOF
}

# If temporary file creation fails, fall back to direct execution
if ! err_file=$(mktemp); then
    exec "$GITU_BIN" "$@"
fi

cleanup() {
    rm -f "$err_file"
}

trap cleanup EXIT INT TERM

# Run gitu (or GITU_BIN) and capture stderr to detect GPG errors on failure
"$GITU_BIN" "$@" 2>"$err_file"
rc=$?

# Always pass through the original stderr output unmodified
cat "$err_file" >&2

# If a GPG operation failed while dot-gnupg is disconnected, provide remediation advice
if [ "$rc" -ne 0 ] && grep -Eiq '(gpg|signing failed|no secret key|gpg-agent|inappropriate ioctl for device|failed to sign)' "$err_file"; then
    if command -v snapctl >/dev/null 2>&1; then
        snapctl is-connected dot-gnupg >/dev/null 2>&1
        snapctl_rc=$?
        if [ "$snapctl_rc" -eq 1 ]; then
            emit_dot_gnupg_warning
        fi
    fi
fi

exit "$rc"

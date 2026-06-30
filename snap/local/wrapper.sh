#!/bin/sh

. "$SNAP_DATA/env"

emit_dot_gnupg_warning() {
    cat >&2 <<'EOF'
[gitu snap] warning: gpg-related operation failed and dot-gnupg is not connected.
[gitu snap] warning: run `snap connections gitu` and then `snap connect gitu:dot-gnupg`.
EOF
}

if ! err_file=$(mktemp); then
    exec "$SNAP/bin/gitu"
fi

cleanup() {
    rm -f "$err_file"
}

trap cleanup EXIT INT TERM

"$SNAP/bin/gitu" 2>"$err_file"
rc=$?

cat "$err_file" >&2

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

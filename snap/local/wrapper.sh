#!/bin/sh

# Load persistent snap configuration (e.g. editor settings)
. "$SNAP_DATA/env"

# Allow overriding the binary (defaults to gitu; tests can point this to git or stubs)
GITU_BIN="${GITU_BIN:-$SNAP/bin/gitu}"

# Unset legacy single-file override if present so git can discover all global configs
if [ "${GIT_CONFIG_GLOBAL:-}" = "$SNAP_REAL_HOME/.gitconfig" ]; then
    unset GIT_CONFIG_GLOBAL
fi

# Ensure git finds user config from the host home (~/.config/git and ~/.gitconfig)
if [ -n "$SNAP_REAL_HOME" ]; then
    mkdir -p "$HOME/.config"
    if [ ! -e "$HOME/.gitconfig" ] || [ -L "$HOME/.gitconfig" ]; then
        if [ -f "$SNAP_REAL_HOME/.gitconfig" ]; then
            ln -sf "$SNAP_REAL_HOME/.gitconfig" "$HOME/.gitconfig"
        elif [ -L "$HOME/.gitconfig" ]; then
            rm -f "$HOME/.gitconfig"
        fi
    fi
    if [ ! -e "$HOME/.config/git" ] || [ -L "$HOME/.config/git" ]; then
        if [ -d "$SNAP_REAL_HOME/.config/git" ]; then
            ln -sfn "$SNAP_REAL_HOME/.config/git" "$HOME/.config/git"
        elif [ -L "$HOME/.config/git" ]; then
            rm -f "$HOME/.config/git"
        fi
    fi
fi

# Read host /etc/gitconfig via etc-gitconfig plug if GIT_CONFIG_SYSTEM is not explicitly set
if [ -z "${GIT_CONFIG_SYSTEM:-}" ] && [ -r "/var/lib/snapd/hostfs/etc/gitconfig" ]; then
    export GIT_CONFIG_SYSTEM="/var/lib/snapd/hostfs/etc/gitconfig"
fi

emit_dot_gnupg_warning() {
    cat >&2 <<'EOF'
[gitu snap] warning: gpg-related operation failed and dot-gnupg is not connected.
[gitu snap] warning: run `snap connections gitu` and then `snap connect gitu:dot-gnupg`.
EOF
}

emit_dot_gitconfig_warning() {
    cat >&2 <<'EOF'
[gitu snap] warning: committer identity unknown and dot-gitconfig is not connected.
[gitu snap] warning: run `snap connections gitu` and then `snap connect gitu:dot-gitconfig`.
EOF
}

emit_gitconfig_identity_note() {
    cat >&2 <<'EOF'
[gitu snap] note: committer identity not found in ~/.gitconfig or ~/.config/git/config.
[gitu snap] note: configure your identity with `git config --global user.name "..."` and `git config --global user.email "..."`.
EOF
}

emit_gitconfig_include_warning() {
    cat >&2 <<'EOF'
[gitu snap] warning: git could not access a configuration file due to permission denied.
[gitu snap] warning: strict snap confinement restricts git configuration to ~/.gitconfig and ~/.config/git/.
[gitu snap] warning: if using include.path, move included config files into ~/.config/git/ (e.g. ~/.config/git/work).
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

# Inspect failure causes and provide remediation advice
if [ "$rc" -ne 0 ]; then
    # GPG operation failed
    if grep -Eiq '(gpg|signing failed|no secret key|gpg-agent|inappropriate ioctl for device|failed to sign)' "$err_file"; then
        if command -v snapctl >/dev/null 2>&1; then
            snapctl is-connected dot-gnupg >/dev/null 2>&1
            snapctl_rc=$?
            if [ "$snapctl_rc" -eq 1 ]; then
                emit_dot_gnupg_warning
            fi
        fi
    fi

    # Committer identity unknown
    if grep -Eiq '(committer identity unknown|unable to auto-detect email|empty ident name|no name was given and auto-detection is disabled)' "$err_file"; then
        if command -v snapctl >/dev/null 2>&1; then
            snapctl is-connected dot-gitconfig >/dev/null 2>&1
            snapctl_rc=$?
            if [ "$snapctl_rc" -eq 1 ]; then
                emit_dot_gitconfig_warning
            else
                emit_gitconfig_identity_note
            fi
        else
            emit_gitconfig_identity_note
        fi
    fi

    # Unreadable config file (e.g. include outside confinement)
    if grep -Eiq 'unable to (access|read config file).*(Permission denied|EACCES)' "$err_file"; then
        emit_gitconfig_include_warning
    fi
fi

exit "$rc"

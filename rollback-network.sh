#!/bin/sh
# Internal rollback helper; runs under Bash on the host and BusyBox ash in Alpine.
# SCRIPT_VERSION=4BACD833-A585-23BA-6CBB-9AA4E08E0006
set -eu
set -o pipefail

network_error() {
    echo "[rollback] Network: $*" >&2
    return 1
}

network_files() (
    cd "$1" || exit 1
    case "$2" in
    networkd) set -- etc/systemd/network/*.network etc/systemd/network/*.network.d/*.conf ;;
    netplan) set -- etc/netplan/*.yaml ;;
    NetworkManager) set -- etc/NetworkManager/system-connections/*.nmconnection ;;
    ifupdown) set -- etc/network/interfaces etc/network/interfaces.d/* ;;
    *) exit 1 ;;
    esac
    for file; do
        [ -f "$file" ] || [ -L "$file" ] || continue
        # Leave VPN, Wi-Fi and other unrelated connection profiles alone.
        if [ "${file##*.}" = nmconnection ] &&
            ! grep -Eq '^type=(ethernet|802-3-ethernet)[[:space:]]*$' "$file"; then
            continue
        fi
        printf '%s\n' "$file"
    done
)

network_backend() {
    local root=$1 backend= kind files
    for kind in networkd netplan NetworkManager ifupdown; do
        files=$(network_files "$root" "$kind") || return 1
        [ -n "$files" ] || continue
        if [ "$kind" = ifupdown ] && ! (
            while IFS= read -r file; do
                grep -Eq '^[[:space:]]*iface[[:space:]]+[^[:space:]]+[[:space:]]+inet6?[[:space:]]' "$root/$file" &&
                    grep -Eq '^[[:space:]]*iface[[:space:]]+[^[:space:]]+[[:space:]]+inet6?[[:space:]]+(dhcp|static|auto)' "$root/$file" && exit 0
            done <<EOF
$files
EOF
            exit 1
        ); then
            continue
        fi
        [ -z "$backend" ] || {
            network_error "multiple network configuration backends in $root"
            return 1
        }
        backend=$kind
    done
    [ -n "$backend" ] || {
        network_error "no supported network configuration in $root"
        return 1
    }
    echo "$backend"
}

network_paths() {
    local root=${1%/} file
    network_files "${root:-/}" "$2" || return 1
    for file in "$root"/etc/resolv.conf "$root"/etc/systemd/resolved.conf \
        "$root"/etc/systemd/resolved.conf.d/*.conf "$root"/etc/udev/rules.d/70-persistent-net.rules \
        "$root"/etc/systemd/network/*.link "$root"/etc/systemd/network/*.link.d/*.conf; do
        [ -f "$file" ] || [ -L "$file" ] || continue
        printf '%s\n' "${file#"$root/"}"
    done
}

network_safe_path() {
    local root=$1 path=$2
    while [ "${path%/*}" != "$path" ]; do
        path=${path%/*}
        [ ! -L "$root/$path" ] || {
            network_error "symlinked configuration directory: $path"
            return 1
        }
    done
}

network_fingerprint() {
    (
        local root=${1%/} backend=$2 files file
        files=$(network_paths "$root" "$backend") || exit 1
        while IFS= read -r file; do
            network_safe_path "$root" "$file" || exit 1
            printf '%s\n' "$file"
            if [ -L "$root/$file" ]; then
                readlink "$root/$file" || exit 1
            else
                # Keep YAML indentation and ordering; ignore comments, blank lines and trailing spaces.
                awk '!/^[[:space:]]*([#;]|$)/ { sub(/[[:space:]]+$/, ""); print }' "$root/$file" || exit 1
            fi
        done <<EOF
$files
EOF
    ) | sha256sum
}

network_service() {
    local root=$1 backend=$2 file renderer= value
    case "$backend" in
    networkd) echo systemd-networkd ;;
    NetworkManager) echo NetworkManager ;;
    ifupdown) echo networking ;;
    netplan)
        for file in "$root"/etc/netplan/*.yaml; do
            value=$(awk '/^[[:space:]]*renderer:/ { gsub(/["\047]/, "", $2); print $2 }' "$file" | sort -u)
            [ -z "$value" ] || [ -z "$renderer" ] || [ "$value" = "$renderer" ] || return 1
            [ -z "$value" ] || renderer=$value
        done
        case "${renderer:-networkd}" in
        networkd) echo systemd-networkd ;;
        NetworkManager) echo NetworkManager ;;
        *)
            network_error 'unsupported or mixed netplan renderers'
            return 1
            ;;
        esac
        ;;
    esac
}

network_interface() {
    ip -o link | awk -v mac="$1" '
        tolower($0) ~ "link/ether " tolower(mac) " " && $0 !~ / master / {
            name=$2; sub(/:$/, "", name); sub(/@.*/, "", name); count++
        }
        END { if (count == 1) print name; else exit 1 }
    '
}

network_chroot() (
    root=$1
    shift
    network_safe_path "$root" dev/null || exit 1
    # A snapshot does not contain the running system's devtmpfs. Python/netplan needs /dev/null.
    if [ ! -c "$root/dev/null" ]; then
        mkdir -p "$root/dev" || exit 1
        mount -o bind /dev "$root/dev" || exit 1
        trap 'umount "$root/dev" || exit 1' EXIT
    fi
    chroot "$root" "$@"
)

prepare_rollback_network() {
    local current=$1 snapshot=$2 state=$3 backend files file path paths eth mac current_hash snapshot_hash service snapshot_service
    backend=$(network_backend "$current") || return 1
    [ "$(network_backend "$snapshot")" = "$backend" ] || {
        network_error "restoring between different network backends is unsupported"
        return 1
    }
    # The minimal adapter handles a single Ethernet uplink, not virtual network topologies.
    for file in "$current"/etc/systemd/network/*.netdev "$snapshot"/etc/systemd/network/*.netdev; do
        [ ! -e "$file" ] || {
            network_error "virtual network devices require manual adaptation"
            return 1
        }
    done
    files=$(network_paths "$current" "$backend") || return 1
    for file in "$current" "$snapshot"; do
        paths=$(network_files "$file" "$backend") || return 1
        while IFS= read -r path; do
            if grep -Eq '^[[:space:]]*((bridges|bonds|vlans|wifis|tunnels):|(Bridge|Bond|VLAN)=|bridge_ports[[:space:]])' "$file/$path"; then
                network_error "complex network topology requires manual adaptation"
                return 1
            fi
        done <<EOF
$paths
EOF
    done
    service=$(network_service "$current" "$backend") || return 1
    snapshot_service=$(network_service "$snapshot" "$backend") || return 1
    [ "$service" = "$snapshot_service" ] || {
        network_error 'network service differs between current system and snapshot'
        return 1
    }
    [ -d "$snapshot/etc/systemd/system" ] || {
        network_error 'first-boot adaptation requires systemd'
        return 1
    }
    network_safe_path "$snapshot" etc/systemd/system/reinstall-rollback-network.service || return 1
    eth=$({
        ip -o route show default
        ip -o -6 route show default
    } |
        awk '{ for (i=1; i<NF; i++) if ($i=="dev") print $(i+1) }' | sort -u)
    case "$eth" in '' | *[!a-zA-Z0-9_.:-]*)
        network_error "cannot identify one Ethernet uplink"
        return 1
        ;;
    esac
    mac=$(ip -o link show dev "$eth" | awk '{ for (i=1; i<NF; i++) if ($i=="link/ether") print $(i+1) }')
    printf '%s\n' "$mac" | grep -Eq '^([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}$' || return 1
    [ "$(network_interface "$mac")" = "$eth" ] || {
        network_error "cannot identify uplink MAC"
        return 1
    }
    mkdir -p "$state/current" || return 1
    printf '%s\n' "$backend" >"$state/backend"
    printf '%s\n' "$mac" >"$state/mac"
    printf '%s\n' "$eth" >"$state/ifname"
    while IFS= read -r file; do
        network_safe_path "$current" "$file" || return 1
        mkdir -p "$state/current/$(dirname "$file")" || return 1
        cp -a "$current/$file" "$state/current/$file" || return 1
    done <<EOF
$files
EOF
    current_hash=$(network_fingerprint "$state/current" "$backend") || return 1
    snapshot_hash=$(network_fingerprint "$snapshot" "$backend") || return 1
    if [ "$current_hash" = "$snapshot_hash" ]; then
        echo '[rollback] Network configuration matches; no replacement needed.'
    else
        echo '[rollback] Network configuration differs; preserve the current VPS network.'
    fi
}

rename_rollback_interface() {
    local state=$1 root=$2 backend mac old eth pattern files file
    read -r backend <"$state/backend"
    read -r mac <"$state/mac"
    read -r old <"$state/ifname"
    eth=$(network_interface "$mac") || {
        network_error "saved uplink MAC is missing or ambiguous"
        return 1
    }
    [ "$old" != "$eth" ] || return 0
    pattern=$(printf '%s' "$old" | sed 's/[][\\.^$*]/\\&/g')
    files=$(network_files "$root" "$backend") || return 1
    while IFS= read -r file; do
        network_safe_path "$root" "$file" || return 1
        if [ -L "$root/$file" ]; then
            [ "$(readlink "$root/$file")" = /dev/null ] && continue
            network_error "cannot rename an interface in a symlinked profile"
            return 1
        fi
        case "$backend" in
        networkd) sed -i -E "/^[[:space:]]*(Name|OriginalName|BindCarrier)=/s/\\b$pattern\\b/$eth/g" "$root/$file" ;;
        NetworkManager) sed -i -E "/^interface-name=/s/\\b$pattern\\b/$eth/g" "$root/$file" ;;
        netplan) sed -i -E "/^[[:space:]]*([\"']?$pattern[\"']?:|name:|set-name:)/s/\\b$pattern\\b/$eth/g" "$root/$file" ;;
        ifupdown)
            sed -i -E "/^[[:space:]]*(auto|allow-[^[:space:]]+|iface|mapping)[[:space:]]/s/\\b$pattern\\b/$eth/g; s/([[:space:]]dev[[:space:]]+)$pattern([[:space:]]|$)/\\1$eth\\2/g" "$root/$file"
            ;;
        esac || return 1
    done <<EOF
$files
EOF
    printf '%s\n' "$eth" >"$state/ifname"
    if [ "$backend" = netplan ]; then
        network_chroot "$root" netplan generate || return 1
        [ "$root" != / ] || systemctl daemon-reload || return 1
    fi
}

restore_rollback_network() {
    local state=$1 root=$2 backend files file saved service original current_hash snapshot_hash
    read -r backend <"$state/backend"
    network_interface "$(head -n 1 "$state/mac")" >/dev/null || {
        network_error "uplink MAC changed since preparation"
        return 1
    }
    [ "$(network_backend "$root")" = "$backend" ] || return 1
    current_hash=$(network_fingerprint "$state/current" "$backend") || return 1
    snapshot_hash=$(network_fingerprint "$root" "$backend") || return 1
    saved="$root/var/lib/reinstall-rollback-network"
    network_safe_path "$root" var/lib/reinstall-rollback-network/backend || return 1
    mkdir -p "$saved" || return 1
    if [ "$current_hash" != "$snapshot_hash" ]; then
        original=$(mktemp -d "$saved/original.XXXXXX") || return 1
        files=$(network_paths "$root" "$backend") || return 1
        while IFS= read -r file; do
            network_safe_path "$root" "$file" || return 1
            mkdir -p "$original/$(dirname "$file")" || return 1
            mv "$root/$file" "$original/$file" || return 1
        done <<EOF
$files
EOF
        files=$(network_paths "$state/current" "$backend") || return 1
        while IFS= read -r file; do
            network_safe_path "$root" "$file" || return 1
            mkdir -p "$root/$(dirname "$file")" || return 1
            cp -a "$state/current/$file" "$root/$file" || return 1
        done <<EOF
$files
EOF
        # Retain cloud-init's other functionality while preventing it from replacing this network.
        if [ -d "$root/etc/cloud" ]; then
            network_safe_path "$root" etc/cloud/cloud.cfg.d/99-reinstall-rollback-network.cfg || return 1
            mkdir -p "$root/etc/cloud/cloud.cfg.d" || return 1
            [ ! -L "$root/etc/cloud/cloud.cfg.d/99-reinstall-rollback-network.cfg" ] || return 1
            printf 'network:\n  config: disabled\ndisable_network_activation: true\n' \
                >"$root/etc/cloud/cloud.cfg.d/99-reinstall-rollback-network.cfg" || return 1
        fi
    fi
    for file in backend mac ifname; do
        [ ! -L "$saved/$file" ] || return 1
        cp "$state/$file" "$saved/$file" || return 1
    done
    service=$(network_service "$root" "$backend") || return 1
    [ "$backend" != netplan ] || network_chroot "$root" netplan generate || return 1
    if [ -d "$root/etc/systemd/system" ]; then
        network_safe_path "$root" etc/systemd/system/reinstall-rollback-network.service || return 1
        network_chroot "$root" systemctl --root=/ enable "$service" || return 1
        if [ -L "$root/etc/resolv.conf" ]; then
            case "$(readlink "$root/etc/resolv.conf")" in
            *systemd/resolve/*) network_chroot "$root" systemctl --root=/ enable systemd-resolved || return 1 ;;
            esac
        fi
        network_safe_path "$root" usr/local/lib/reinstall-rollback-network.sh || return 1
        mkdir -p "$root/usr/local/lib" || return 1
        [ ! -L "$root/usr/local/lib/reinstall-rollback-network.sh" ] || return 1
        cp "$state/helper.sh" "$root/usr/local/lib/reinstall-rollback-network.sh" || return 1
        [ ! -L "$root/etc/systemd/system/reinstall-rollback-network.service" ] || return 1
        cat >"$root/etc/systemd/system/reinstall-rollback-network.service" <<EOF
[Unit]
Description=Match restored network configuration to the current uplink
After=systemd-udev-settle.service
Wants=systemd-udev-settle.service
Before=network-pre.target systemd-networkd.service NetworkManager.service networking.service
[Service]
Type=oneshot
ExecStart=/usr/bin/env bash /usr/local/lib/reinstall-rollback-network.sh rename /var/lib/reinstall-rollback-network /
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
RequiredBy=$service.service
EOF
        network_chroot "$root" bash -n /usr/local/lib/reinstall-rollback-network.sh || return 1
        network_chroot "$root" systemctl --root=/ enable reinstall-rollback-network.service || return 1
    else
        network_error "first-boot network adaptation requires systemd"
        return 1
    fi
    echo '[rollback] Applied the current VPS network to the candidate system.'
}

# Internal entry point.
case "${1:-}" in
prepare) prepare_rollback_network "$2" "$3" "$4" ;;
restore) restore_rollback_network "$2" "$3" ;;
rename) rename_rollback_interface "$2" "$3" ;;
*) network_error 'expected prepare, restore or rename' ;;
esac

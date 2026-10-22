#!/bin/sh
# Run with bash, or TEST_BUSYBOX=/path/to/busybox bash tests/rollback-network.sh.
if [ -n "${TEST_BUSYBOX:-}" ] && [ "${1:-}" != ash ]; then
    exec "$TEST_BUSYBOX" ash "$0" ash
fi
set -eu
set -o pipefail

repo=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
sed '/^# Internal entry point/,$d' "$repo/rollback-network.sh" >"$work/helper.sh"
. "$work/helper.sh"

ip() {
    case "$*" in
    '-o route show default')
        echo 'default via 192.0.2.1 dev eth0'
        [ "${multi:-0}" = 0 ] || echo 'default via 192.0.2.2 dev eth1'
        ;;
    '-o -6 route show default') ;;
    *) echo "2: ${ifname:-eth0}: <UP> mtu 1400 link/ether 02:00:00:00:00:01 brd ff:ff:ff:ff:ff:ff" ;;
    esac
}
# Exercise file preparation without mounting or running commands in a real system.
network_chroot() { [ "${chroot_fail:-0}" = 0 ]; }

fixture() {
    mkdir -p "$1/etc/systemd/system" "$(dirname "$1/$profile")" "$1/etc/cloud/cloud.cfg.d"
    printf '%s\n' "$2" >"$1/$profile"
    echo 'nameserver 192.0.2.53' >"$1/etc/resolv.conf"
}

reject() {
    if "$@"; then
        echo "FAIL: expected rejection: $*" >&2
        exit 1
    fi
}

count=0
for backend in networkd netplan NetworkManager ifupdown; do
    case "$backend" in
    networkd)
        profile=etc/systemd/network/10-uplink.network
        config='[Match]
Name=eth0
MACAddress=02:00:00:00:00:01
[Network]
Address=192.0.2.10/24
Gateway=192.0.2.1
MTUBytes=1400'
        ;;
    netplan)
        profile=etc/netplan/10-uplink.yaml
        config='network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      mtu: 1400'
        ;;
    NetworkManager)
        profile=etc/NetworkManager/system-connections/uplink.nmconnection
        config='[connection]
type=ethernet
interface-name=eth0
[ipv4]
method=manual
address1=192.0.2.10/24,192.0.2.1'
        ;;
    ifupdown)
        profile=etc/network/interfaces
        config='auto eth0
iface eth0 inet static
    address 192.0.2.10/24
    gateway 192.0.2.1
    mtu 1400'
        ;;
    esac
    current=$work/$backend/current
    snapshot=$work/$backend/snapshot
    state=$work/$backend/state
    fixture "$current" "$config"
    fixture "$snapshot" "$config"
    printf '\n# ignored comment\n; another comment\n' >>"$snapshot/$profile"
    sed -i 's/$/  /' "$snapshot/$profile"
    [ "$(network_fingerprint "$current" "$backend")" = "$(network_fingerprint "$snapshot" "$backend")" ]
    printf '%s\n' "$config" >"$snapshot/$profile"
    prepare_rollback_network "$current" "$snapshot" "$state"
    cp "$repo/rollback-network.sh" "$state/helper.sh"
    restore_rollback_network "$state" "$snapshot"
    [ ! -f "$snapshot/etc/cloud/cloud.cfg.d/99-reinstall-rollback-network.cfg" ]
    printf '\n# extra comment\n' >>"$current/$profile"
    sed -i 's/192.0.2.10/198.51.100.10/g; s/dhcp4: true/dhcp4: false/' "$snapshot/$profile"
    prepare_rollback_network "$current" "$snapshot" "$state"
    cp "$repo/rollback-network.sh" "$state/helper.sh"
    restore_rollback_network "$state" "$snapshot"
    cmp "$current/$profile" "$snapshot/$profile"
    cmp "$current/etc/resolv.conf" "$snapshot/etc/resolv.conf"
    [ -f "$snapshot/etc/cloud/cloud.cfg.d/99-reinstall-rollback-network.cfg" ]
    [ -f "$snapshot/etc/systemd/system/reinstall-rollback-network.service" ]
    ifname=ens3
    rename_rollback_interface "$snapshot/var/lib/reinstall-rollback-network" "$snapshot"
    grep -q ens3 "$snapshot/$profile"
    ifname=eth0
    multi=1
    reject prepare_rollback_network "$current" "$snapshot" "$state"
    multi=0
    count=$((count + 1))
    echo "PASS: $backend preserves current configuration, renames uplink, rejects multiple uplinks"
done

profile=etc/systemd/network/10-uplink.network
current=$work/networkd/current
snapshot=$work/networkd/snapshot
reject prepare_rollback_network "$current" "$work/netplan/snapshot" "$work/mixed"
touch "$current/etc/systemd/network/10-bridge.netdev"
reject prepare_rollback_network "$current" "$snapshot" "$work/bridge"
rm "$current/etc/systemd/network/10-bridge.netdev"
mkdir -p "$current/etc/netplan"
echo 'network: {}' >"$current/etc/netplan/test.yaml"
reject network_backend "$current"
rm "$current/etc/netplan/test.yaml"
mv "$current/etc/systemd/network" "$work/network-config"
ln -s "$work/network-config" "$current/etc/systemd/network"
reject network_fingerprint "$current" networkd
count=$((count + 4))
echo "PASS: backend mismatch, virtual topology, mixed backends and symlinked directories rejected"
echo "$count groups passed"

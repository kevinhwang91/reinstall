#!/bin/bash
# Real Btrfs/Snapper checks on disposable loop devices, in a private mount namespace.
set -euo pipefail

if [ "${1:-}" != --isolated ]; then
    if [ "$(id -u)" = 0 ]; then
        exec unshare --mount --propagation private bash "$0" --isolated
    fi
    exec sudo -n unshare --mount --propagation private bash "$0" --isolated
fi

repo=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
for function in mkfs_linux_os_part setup_arch_snapper rollback_btrfs_from_snapshot; do
    eval "$(sed -n "/^$function() {/,/^}/p" "$repo/trans.sh")"
done
for function in shell_quote receive_ssh_btrfs_snapshot; do
    eval "$(sed -n "/^$function() {/,/^}/p" "$repo/reinstall.sh")"
done
work=$(mktemp -d /var/tmp/reinstall-btrfs-test.XXXXXX)
loops=()
cleanup() {
    set +e
    local failed=0
    while IFS= read -r point; do
        case "$point" in "$work/"*) umount "$point" || failed=1 ;; esac
    done < <(findmnt -rn -o TARGET | sort -r)
    if [ "$failed" != 0 ]; then
        echo "Failed to unmount test filesystems; retained $work" >&2
        return 1
    fi
    for device in "${loops[@]}"; do losetup -d "$device" || return 1; done
    rm -rf "$work"
}
trap cleanup EXIT

# Run the real Snapper in chroot; never invoke the host's systemctl.
chroot() {
    local root=$1
    shift
    case "$1" in
    snapper)
        shift
        mkdir -p "$root/dev" "$root/proc" "$root/usr"
        test -L "$root/etc/mtab" || ln -s /proc/self/mounts "$root/etc/mtab"
        test -L "$root/lib" || ln -s usr/lib "$root/lib"
        test -L "$root/lib64" || ln -s usr/lib "$root/lib64"
        mount --bind /usr "$root/usr"
        mount -o remount,bind,ro "$root/usr"
        mount --bind /dev "$root/dev"
        mount -t proc proc "$root/proc"
        local result=0
        command chroot "$root" snapper --logger-type none "$@" || result=$?
        umount "$root/proc" "$root/dev" "$root/usr"
        return "$result"
        ;;
    systemctl) printf '%s\n' "$*" >"$root/timer-command" ;;
    *) return 99 ;;
    esac
}
make_system() {
    local name=$1 layout=$2
    truncate -s 512M "$work/$name.img"
    device=$(losetup --find --show "$work/$name.img")
    loops+=("$device")
    distro=arch
    mkfs_linux_os_part "$device" >/dev/null
    mkdir -p "$work/$name/top" "$work/$name/root"
    mount -o subvolid=5 "$device" "$work/$name/top"
    mount -o subvol=@ "$device" "$work/$name/root"
    local root=$work/$name/root
    mkdir -p "$root/etc/snapper/configs" "$root/etc/conf.d" "$root/etc/sysconfig" \
        "$root/usr/share/snapper/config-templates" "$root/swap"
    printf 'SNAPPER_CONFIGS=""\n' | tee "$root/etc/conf.d/snapper" >"$root/etc/sysconfig/snapper"
    cp /usr/share/snapper/config-templates/default "$root/usr/share/snapper/config-templates/default"
    mount -o subvol=@swap "$device" "$root/swap"
    if [ "$layout" = top ]; then
        setup_arch_snapper "$root" "$device" "$work/$name/setup-top"
        test "$(findmnt -n -o FSROOT --mountpoint "$root/.snapshots")" = /@snapshots
        test "$(cat "$root/timer-command")" = 'systemctl disable snapper-timeline.timer'
        ! btrfs subvolume show "$work/$name/top/@/.snapshots" >/dev/null 2>&1
    else
        chroot "$root" snapper --no-dbus -c root create-config /
    fi
    genfstab -U "$root" >"$root/etc/fstab"
    printf '%s\n' "$name" >"$root/identity"
    chroot "$root" snapper --no-dbus -c root create --description "$name-history" --print-number
}
snapshot_number() {
    btrfs subvolume show "$1" | awk '/Subvolume ID:/ { print $NF }'
}
unmount_root() {
    if mountpoint -q "$1/.snapshots"; then umount "$1/.snapshots"; fi
    umount "$1/swap"
    umount "$1"
}
check_restored() {
    local name=$1 root=$work/$1/root
    mount -a -T "$work/$name/top/@/etc/fstab" --target-prefix "$root" -t btrfs
    test "$(cat "$root/identity")" = source
    test "$(findmnt -n -o FSROOT --mountpoint "$root/.snapshots")" = /@snapshots
    test "$(awk '$2 == "/.snapshots" { n++ } END { print n+0 }' "$root/etc/fstab")" = 1
    test -d "$root/.snapshots/1/snapshot"
    test "$(cat "$root/.snapshots/1/snapshot/identity")" = "$name"
    chroot "$root" snapper --no-dbus -c root list
    chroot "$root" snapper --no-dbus -c root create --description after-restore --print-number
    unmount_root "$root"
}

apk() { :; }
modprobe() { :; }
ash() { touch "$4/network-applied"; }
error_and_exit() { echo "$*" >&2; exit 1; }
is_in_windows() { return 1; }
is_os_in_btrfs() { return 0; }
is_have_cmd() { return 0; }
install_pkg() { :; }
get_mount_block_dev() { echo "$device"; }
info() { echo "$*"; }
# Only replace the SSH transport; the sender and receiver use real Btrfs tools.
ssh() { command bash -c "$2"; }
fail_activate=0
mv() {
    case "$1" in
    */@rollback-restore-*)
        if [ "${2##*/}" = @ ] && [ "$fail_activate" = 1 ]; then
            test "$(snapshot_number "$work/legacy/top/@snapshots")" = "$legacy_id" || return 99
            touch "$work/migration-before-activation"
            return 1
        fi
        ;;
    esac
    command mv "$@"
}
mkdir "$work/network"
touch "$work/network/helper.sh"
rollback_delete_backup=0

make_system source top
source_snapshot_uuid=$(btrfs subvolume show "$work/source/root/.snapshots/1/snapshot" | awk '$1 == "UUID:" { print $2 }')
make_system target top
target_dev=$device
top_id=$(snapshot_number "$work/target/top/@snapshots")
target_root_id=$(snapshot_number "$work/target/top/@")
btrfs subvolume snapshot -r "$work/target/top/@snapshots/1/snapshot" "$work/target/top/@snapshots/snapshot"
existing_snapshot_id=$(snapshot_number "$work/target/top/@snapshots/snapshot")
tmp=$work/target
snapshot_source="root@backup:$work/source/root/.snapshots/1/snapshot"
snapshot=
snapshot_path=
receive_ssh_btrfs_snapshot
target_remote_name=${snapshot_path##*/}
case "$target_remote_name" in remote-snapshot-*) ;; *) exit 1 ;; esac
[ "$(dirname "$snapshot_path")" = "$tmp/reinstall-btrfs-root/@snapshots" ]
snapshot_id=$(snapshot_number "$snapshot_path")
target_remote_id=$snapshot_id
test "$(btrfs property get -ts "$snapshot_path" ro)" = ro=true
test "$(btrfs subvolume show "$snapshot_path" | awk '$1 == "Received" && $2 == "UUID:" { print $3 }')" = "$source_snapshot_uuid"
test "$(cat "$snapshot_path/identity")" = source
test "$(snapshot_number "$work/target/top/@snapshots/snapshot")" = "$existing_snapshot_id"
test -z "$(find "$work/target/top/@snapshots" -maxdepth 1 -name '.reinstall-rollback-receive-*' -print)"
snapshot_uuid=$(blkid -s UUID -o value "$target_dev")
unmount_root "$work/target/root"
mkdir "$work/target/restore"
rollback_btrfs_from_snapshot "$work/target/restore" "$work/network"
test "$(snapshot_number "$work/target/top/@snapshots")" = "$top_id"
for target_backup in "$work/target/top/@snapshots/"rollback-backup-*; do
    test "$(cat "$target_backup/identity")" = target
    test "$(snapshot_number "$target_backup")" = "$target_root_id"
done
test -z "$(find "$work/target/top" -maxdepth 1 -name '@rollback-backup-*' -print)"
check_restored target
echo 'PASS: installation, SSH receive naming, restore and backup inside @snapshots'

sleep 1
snapshot_id=$(snapshot_number "$work/target/top/@snapshots/2/snapshot")
rollback_delete_backup=1
umount "$work/target/restore"
rollback_btrfs_from_snapshot "$work/target/restore" "$work/network"
test "$(snapshot_number "$work/target/top/@snapshots")" = "$top_id"
test -d "$work/target/top/@snapshots/2/snapshot"
test "$(cat "$target_backup/identity")" = target
test "$(find "$work/target/top/@snapshots" -maxdepth 1 -name 'rollback-backup-*' | wc -l)" = 1
test "$(snapshot_number "$work/target/top/@snapshots/$target_remote_name")" = "$target_remote_id"
check_restored target
echo 'PASS: local rollback and old-root deletion retain top-level snapshots'

make_system legacy nested
legacy_dev=$device
legacy_id=$(snapshot_number "$work/legacy/top/@/.snapshots")
mkdir "$work/legacy/restore"
tmp=$work/legacy
snapshot_path=
receive_ssh_btrfs_snapshot
legacy_remote_name=${snapshot_path##*/}
test ! -e "$work/legacy/top/@snapshots"
test "$(dirname "$snapshot_path")" = "$tmp/reinstall-btrfs-root/@/.snapshots"
snapshot_id=$(snapshot_number "$snapshot_path")
legacy_remote_id=$snapshot_id
snapshot_uuid=$(blkid -s UUID -o value "$legacy_dev")
unmount_root "$work/legacy/root"
rollback_delete_backup=0
fail_activate=1
if rollback_btrfs_from_snapshot "$work/legacy/restore" "$work/network"; then
    echo 'FAIL: activation failure was ignored' >&2
    exit 1
fi
test -f "$work/migration-before-activation"
test ! -e "$work/legacy/top/@snapshots"
test "$(snapshot_number "$work/legacy/top/@/.snapshots")" = "$legacy_id"
test "$(cat "$work/legacy/top/@/identity")" = legacy
test "$(snapshot_number "$work/legacy/top/@/.snapshots/$legacy_remote_name")" = "$legacy_remote_id"
echo 'PASS: failed activation restores the original nested subvolume'

sleep 1
fail_activate=0
rollback_delete_backup=1
umount "$work/legacy/restore"
rollback_btrfs_from_snapshot "$work/legacy/restore" "$work/network"
test "$(snapshot_number "$work/legacy/top/@snapshots")" = "$legacy_id"
test "$(snapshot_number "$work/legacy/top/@snapshots/$legacy_remote_name")" = "$legacy_remote_id"
test -z "$(find "$work/legacy/top/@snapshots" -maxdepth 1 -name 'rollback-backup-*' -print)"
check_restored legacy
echo 'PASS: legacy migration preserves the subvolume ID and complete snapshot history'

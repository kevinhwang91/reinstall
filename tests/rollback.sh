#!/bin/sh
# Simulate rollback in temporary directories; never mount or modify real devices.
if [ -n "${TEST_BUSYBOX:-}" ] && [ "${1:-}" != ash ]; then
    exec "$TEST_BUSYBOX" ash "$0" ash
fi
set -eu
set -o pipefail

repo=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
eval "$(sed -n '/^rollback_btrfs_from_snapshot() {/,/^}/p' "$repo/trans.sh")"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

apk() { [ "$mode" != packages ]; }
modprobe() { [ "$mode" != module ]; }
blkid() { [ "$mode" != device ] && echo /dev/test; }
mount() { [ "$mode" != mount ]; }
ash() {
    case "$mode" in network | snapper-migrate-network) return 1 ;; esac
    touch "$4/network-applied"
}
sed() {
    [ "$mode" != uuid ] || return 1
    command sed "$@"
}
mv() {
    case "$mode" in backup | snapper-migrate-backup) [ "$1" != "$case_dir/mnt/@" ] || return 1 ;; esac
    case "$1" in
    */@rollback-restore-*)
        if [ "$2" = "$case_dir/mnt/@" ]; then
            case "$mode" in
            activate | snapper-migrate-activate | snapper-existing-activate)
                if [ "$mode" = snapper-migrate-activate ]; then
                    [ "$(cat "$case_dir/mnt/@snapshots/history")" = existing-history ] || return 99
                    touch "$case_dir/migration-before-activation"
                fi
                return 1
                ;;
            esac
        fi
        ;;
    */.snapshots) [ "$mode" != snapper-migrate-fail ] || return 1 ;;
    esac
    command mv "$@"
}
chmod() {
    [ "$mode" != snapper-permissions ] || return 1
    command chmod "$@"
}
btrfs() {
    case "$1 $2" in
    'inspect-internal subvolid-resolve')
        [ "$mode" != resolve ] || return 1
        echo 'snapshot with spaces'
        ;;
    'subvolume snapshot')
        [ "$mode" != snapshot ] || return 1
        cp -a "$3" "$4"
        ;;
    'subvolume create')
        [ "$mode" != snapper-create ] || return 1
        mkdir "$3" || return 1
        touch "$case_dir/created-subvolume"
        ;;
    'subvolume show')
        case "$3" in
        */@snapshots)
            [ -d "$3" ] || return 1
            case "$mode" in snapper-invalid) return 1 ;; esac
            ;;
        */@/.snapshots)
            case "$mode" in snapper-migrate*) [ -d "$3" ] ;; *) return 1 ;; esac
            ;;
        *) return 99 ;;
        esac
        ;;
    'subvolume delete')
        case "$3" in "$work/"*) rm -rf "$3" ;; *) return 99 ;; esac
        ;;
    *) return 99 ;;
    esac
}

snapshot_id=123
snapshot_uuid=22222222-2222-2222-2222-222222222222
for mode in success delete efi boot-efi snapper snapper-placeholder snapper-existing snapper-fstab snapper-migrate snapper-migrate-delete snapper-migrate-fail snapper-migrate-network snapper-migrate-backup snapper-migrate-activate snapper-existing-activate snapper-invalid snapper-nonempty snapper-create snapper-permissions packages module device mount resolve snapshot uuid network backup activate missing-helper; do
    case_dir=$work/$mode
    source_dir="$case_dir/mnt/snapshot with spaces"
    mkdir -p "$source_dir/etc" "$source_dir/boot/grub" "$case_dir/mnt/@/etc" "$case_dir/mnt/@/.snapshots" "$case_dir/network"
    echo original >"$case_dir/mnt/@/identity"
    echo existing-history >"$case_dir/mnt/@/.snapshots/history"
    echo restored >"$source_dir/identity"
    echo 'UUID=11111111-1111-1111-1111-111111111111 / btrfs subvol=@ 0 0' >"$source_dir/etc/fstab"
    efi_mount=/efi
    [ "$mode" != boot-efi ] || efi_mount=/boot/efi
    echo "UUID=source-efi $efi_mount vfat defaults 0 2" >>"$source_dir/etc/fstab"
    echo 'UUID=unrelated /data ext4 defaults 0 0' >>"$source_dir/etc/fstab"
    case "$mode" in
    efi | boot-efi) echo "UUID=target-efi $efi_mount vfat defaults 0 2" >"$case_dir/mnt/@/etc/fstab" ;;
    esac
    case "$mode" in
    snapper*)
        mkdir -p "$source_dir/etc/snapper/configs"
        echo 'SUBVOLUME="/"' >"$source_dir/etc/snapper/configs/root"
        ;;
    esac
    case "$mode" in
    snapper-placeholder | snapper-nonempty) mkdir "$source_dir/.snapshots" ;;
    esac
    [ "$mode" != snapper-nonempty ] || echo source-history >"$source_dir/.snapshots/history"
    case "$mode" in
    snapper-existing* | snapper-fstab | snapper-invalid)
        mkdir "$case_dir/mnt/@snapshots"
        chmod 755 "$case_dir/mnt/@snapshots"
        echo top-level-history >"$case_dir/mnt/@snapshots/history"
        ;;
    esac
    if [ "$mode" = snapper-fstab ]; then
        echo 'UUID=source /.snapshots btrfs subvolid=999,subvol=/@/.snapshots 0 0' >>"$source_dir/etc/fstab"
        echo 'LABEL=source /.snapshots btrfs defaults 0 0' >>"$source_dir/etc/fstab"
    fi
    echo 'root=UUID=11111111-1111-1111-1111-111111111111' >"$source_dir/boot/grub/grub.cfg"
    [ "$mode" = missing-helper ] || touch "$case_dir/network/helper.sh"
    rollback_delete_backup=0
    case "$mode" in delete | snapper-migrate-delete) rollback_delete_backup=1 ;; esac
    if rollback_btrfs_from_snapshot "$case_dir/mnt" "$case_dir/network"; then
        case "$mode" in success | delete | efi | boot-efi | snapper | snapper-placeholder | snapper-existing | snapper-fstab | snapper-migrate | snapper-migrate-delete) ;; *) echo "FAIL: $mode did not stop" >&2; exit 1 ;; esac
        [ "$(cat "$case_dir/mnt/@/identity")" = restored ]
        [ -f "$case_dir/mnt/@/network-applied" ]
        grep -q "UUID=$snapshot_uuid / " "$case_dir/mnt/@/etc/fstab"
        grep -q "root=UUID=$snapshot_uuid" "$case_dir/mnt/@/boot/grub/grub.cfg"
        grep -q 'UUID=unrelated /data' "$case_dir/mnt/@/etc/fstab"
        case "$mode" in
        efi | boot-efi) grep -q "UUID=target-efi $efi_mount " "$case_dir/mnt/@/etc/fstab" ;;
        *) grep -q "UUID=source-efi $efi_mount " "$case_dir/mnt/@/etc/fstab" ;;
        esac
        case "$mode" in
        snapper*)
            [ -d "$case_dir/mnt/@/.snapshots" ]
            [ -z "$(ls -A "$case_dir/mnt/@/.snapshots")" ]
            [ -d "$case_dir/mnt/@snapshots" ]
            [ "$(awk '$2 == "/.snapshots" { n++ } END { print n+0 }' "$case_dir/mnt/@/etc/fstab")" = 1 ]
            grep -q "^UUID=$snapshot_uuid /.snapshots btrfs .*subvol=/@snapshots " "$case_dir/mnt/@/etc/fstab"
            case "$mode" in
            snapper | snapper-placeholder)
                [ -f "$case_dir/created-subvolume" ]
                [ ! -e "$case_dir/mnt/@snapshots/history" ]
                [ "$(stat -c %a "$case_dir/mnt/@snapshots")" = 750 ]
                ;;
            snapper-existing | snapper-fstab)
                [ ! -e "$case_dir/created-subvolume" ]
                [ "$(cat "$case_dir/mnt/@snapshots/history")" = top-level-history ]
                [ "$(stat -c %a "$case_dir/mnt/@snapshots")" = 755 ]
                ;;
            snapper-migrate | snapper-migrate-delete)
                [ ! -e "$case_dir/created-subvolume" ]
                [ "$(cat "$case_dir/mnt/@snapshots/history")" = existing-history ]
                ;;
            esac
            ;;
        *) [ -f "$case_dir/created-subvolume" ] ;;
        esac
        for old_backup in "$case_dir/mnt/"@rollback-backup-*; do [ ! -e "$old_backup" ]; done
        for backup in "$case_dir/mnt/@snapshots/"rollback-backup-*; do
            if [ "$rollback_delete_backup" = 1 ]; then
                [ ! -e "$backup" ]
            else
                [ "$(cat "$backup/identity")" = original ]
                if [ "$mode" = snapper-migrate ]; then
                    [ ! -e "$backup/.snapshots" ]
                else
                    [ "$(cat "$backup/.snapshots/history")" = existing-history ]
                fi
            fi
        done
    else
        case "$mode" in success | delete | efi | boot-efi | snapper | snapper-placeholder | snapper-existing | snapper-fstab | snapper-migrate | snapper-migrate-delete) echo "FAIL: $mode failed" >&2; exit 1 ;; esac
        [ "$(cat "$case_dir/mnt/@/identity")" = original ]
        [ "$(cat "$case_dir/mnt/@/.snapshots/history")" = existing-history ]
        if [ "$mode" = snapper-migrate-activate ]; then
            [ -f "$case_dir/migration-before-activation" ]
            [ ! -e "$case_dir/mnt/@snapshots" ]
        fi
        case "$mode" in snapper-migrate-backup | snapper-migrate-fail) [ ! -e "$case_dir/mnt/@snapshots" ] ;; esac
        if [ "$mode" = snapper-existing-activate ]; then
            [ "$(cat "$case_dir/mnt/@snapshots/history")" = top-level-history ]
            for backup in "$case_dir/mnt/@snapshots/"rollback-backup-*; do [ ! -e "$backup" ]; done
        fi
        [ "$mode" != snapper-nonempty ] || [ "$(cat "$source_dir/.snapshots/history")" = source-history ]
    fi
    echo "PASS: $mode"
done
echo '30 rollback scenarios passed'

# Host-side preparation uses Bash; a failed verification must never produce an install entry.
if [ -n "${BASH_VERSION:-}" ]; then
    (
        eval "$(command sed -n '/^build_extra_cmdline() {/,/^}/p' "$repo/reinstall.sh")"
        is_need_quote() { return 1; }
        is_grub_dir_linked() { return 1; }
        info() { :; }
        error_and_exit() { exit 1; }
        get_btrfs_snapshot_info() { return 1; }
        snapshot_path=$work
        # Upstream initializes these by parsing arguments, without nounset.
        set +u
        if (build_extra_cmdline); then
            echo 'FAIL: snapshot verification failure was ignored' >&2
            exit 1
        fi
        get_btrfs_snapshot_info() { echo '123 test-uuid'; }
        finalos_cmdline=
        rollback_delete_backup=0
        build_extra_cmdline >/dev/null
        [ "$finalos_cmdline" = ' finalos_snapshot_id=123 finalos_snapshot_uuid=test-uuid' ]
        eval "$(command sed -n '/^get_btrfs_snapshot_info() {/,/^}/p' "$repo/reinstall.sh")"
        is_have_cmd() { :; }
        btrfs() { echo 'Subvolume ID: 123'; return 1; }
        findmnt() { echo test-uuid; }
        if (get_btrfs_snapshot_info "$work"); then
            echo 'FAIL: btrfs command failure was ignored' >&2
            exit 1
        fi
        echo 'PASS: host snapshot validation and boot arguments'
    )
fi

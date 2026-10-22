#!/bin/bash
# Exercise SSH receive paths without contacting a server or mounting a filesystem.
set -euo pipefail

repo=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
for function in shell_quote receive_ssh_btrfs_snapshot; do
    eval "$(sed -n "/^$function() {/,/^}/p" "$repo/reinstall.sh")"
done

# Exercise the real getopt block without running installation preparation.
parse_ssh_options() (
    eval "$(sed -n '/^# 整理参数/,/^eval set -- /p' "$repo/reinstall.sh")"
    [ "$#" = 4 ] && [ "$1" = --ssh ] &&
        [ "$2" = "root@backup:/backup/arch base's snapshot" ] &&
        [ "$3" = -- ] && [ "$4" = rollback ]
)
parse_ssh_options rollback --ssh "root@backup:/backup/arch base's snapshot"
parse_ssh_options --ssh "root@backup:/backup/arch base's snapshot" rollback
if parse_ssh_options rollback -ssh "root@backup:/backup/arch base's snapshot" >/dev/null 2>&1; then
    echo 'FAIL: legacy -ssh spelling accepted' >&2
    exit 1
fi
if parse_ssh_options rollback --ssh >/dev/null 2>&1; then
    echo 'FAIL: --ssh without a source accepted' >&2
    exit 1
fi
echo 'PASS: standard --ssh parsing and invalid arguments'

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

error_and_exit() { echo "$*" >&2; exit 1; }
is_in_windows() { return 1; }
is_os_in_btrfs() { return 0; }
is_have_cmd() { return 0; }
install_pkg() { :; }
get_mount_block_dev() { echo /dev/test; }
mount() { :; }
info() { :; }
ssh() {
    printf '%s\n' "$1" "$2" >"$case_dir/ssh-command"
    bash -n <<<"$2"
    [ "$mode" != send-fail ] || return 1
    echo stream
}
btrfs() {
    case "$1 $2" in
    'subvolume show')
        [ -f "$3/subvolume" ]
        ;;
    'subvolume create')
        mkdir "$3"
        touch "$3/subvolume"
        ;;
    'receive '*)
        cat >/dev/null
        [ "$mode" != receive-fail ] || return 1
        [ "$mode" != missing-received ] || return 0
        mkdir "$2/$received_name"
        touch "$2/$received_name/subvolume"
        ;;
    'subvolume snapshot')
        [ "$3" = -r ] || return 99
        [ "$mode" != snapshot-fail ] || return 1
        cp -a "$4" "$5"
        touch "$case_dir/readonly-clone"
        ;;
    'subvolume delete')
        [ "$mode" != delete-fail ] || return 1
        case "$3" in "$root/"*) rm -rf "$3" ;; *) return 99 ;; esac
        ;;
    *) return 99 ;;
    esac
}
rmdir() {
    [ "$mode" != cleanup-fail ] || return 1
    command rmdir "$@"
}
count=0
for mode in existing create legacy collision fallback send-fail receive-fail missing-received snapshot-fail delete-fail cleanup-fail invalid; do
    (
        case_dir=$work/$mode
        tmp=$case_dir/tmp
        root=$tmp/reinstall-btrfs-root
        mkdir -p "$root/@/.snapshots"
        echo old-root >"$root/@/identity"
        case "$mode" in
        create) ;;
        legacy)
            touch "$root/@/.snapshots/subvolume"
            echo legacy-history >"$root/@/.snapshots/history"
            ;;
        *)
            mkdir "$root/@snapshots"
            [ "$mode" = invalid ] || touch "$root/@snapshots/subvolume"
            echo target-history >"$root/@snapshots/history"
            ;;
        esac
        snapshot_source="root@backup:/backup/arch base's snapshot"
        received_name="arch base's snapshot"
        [ "$mode" != collision ] || mkdir "$root/@snapshots/$received_name"
        [ "$mode" != fallback ] || received_name=snapshot
        snapshot=
        snapshot_path=
        distro=rollback
        expected_root=$root/@snapshots
        [ "$mode" != legacy ] || expected_root=$root/@/.snapshots
        if (
            receive_ssh_btrfs_snapshot
            printf '%s\n' "$snapshot_path" >"$case_dir/received-path"
        ); then
            case "$mode" in existing | create | legacy | collision | fallback) ;; *) exit 1 ;; esac
            received_path=$(cat "$case_dir/received-path")
            case "$received_path" in "$expected_root/remote-arch base's snapshot-"*) ;; *) exit 1 ;; esac
            [ "$(dirname "$received_path")" = "$expected_root" ]
            [ -f "$received_path/subvolume" ]
            [ -f "$case_dir/readonly-clone" ]
            [ -z "$(find "$expected_root" -maxdepth 1 -name '.reinstall-rollback-receive-*' -print)" ]
            [ -z "$(find "$root" -maxdepth 1 -name '.reinstall-rollback-receive-*' -print)" ]
        else
            case "$mode" in send-fail | receive-fail | missing-received | snapshot-fail | delete-fail | cleanup-fail | invalid) ;; *) exit 1 ;; esac
            [ ! -e "$case_dir/received-path" ]
            case "$mode" in
            snapshot-fail | delete-fail)
                for staging in "$expected_root/".reinstall-rollback-receive-*; do
                    [ -f "$staging/$received_name/subvolume" ]
                done
                ;;
            cleanup-fail)
                [ -f "$case_dir/readonly-clone" ]
                for staging in "$expected_root/".reinstall-rollback-receive-*; do
                    [ -d "$staging" ]
                    [ -z "$(ls -A "$staging")" ]
                done
                ;;
            esac
        fi
        [ "$(cat "$root/@/identity")" = old-root ]
        [ "$mode" != collision ] || [ -d "$root/@snapshots/$received_name" ]
        case "$mode" in
        legacy)
            [ ! -e "$root/@snapshots" ]
            [ "$(cat "$expected_root/history")" = legacy-history ]
            ;;
        create) [ "$(stat -c %a "$expected_root")" = 750 ] ;;
        *) [ "$(cat "$root/@snapshots/history")" = target-history ] ;;
        esac
        echo "PASS: SSH $mode"
    )
    count=$((count + 1))
done
echo "$count SSH receive scenarios passed"

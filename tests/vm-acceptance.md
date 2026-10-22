# 本地双虚拟机验收（2026-10-22）

这是旧版嵌套 `@/.snapshots` 布局的历史记录。2026-10-23 改为顶层 `@snapshots` 并保留本机历史，新的真实文件系统验收见 [存储布局验收记录](btrfs-layout.md)；该变更尚未重新进行虚拟机启动和 SSH 验收。

测试代码：`kevin` 分支 `1f4befc`，加上本次 Snapper 子卷修复。没有恢复已删除的自动卸载改动。

## 环境

宿主机使用 libvirt/QEMU/KVM，两个新建虚拟机均为 x86_64、UEFI、2 vCPU、2 GiB 内存、16 GiB 系统盘和 virtio 网卡。

| 虚拟机 | 用途 | 地址 | MAC |
| --- | --- | --- | --- |
| `reinstall-snapshot` | SSH 快照服务器 | `192.168.123.10` | `52:54:00:12:23:10` |
| `reinstall-target` | 安装及恢复目标 | `192.168.123.20` | `52:54:00:12:23:20` |

两机位于独立的 `reinstall-lab` NAT 网络。宿主机原有虚拟机和磁盘未修改。

初始系统使用 [Arch 官方 cloud image](https://geo.mirror.pkgbuild.com/images/latest/)，下载后核对 SHA256。通过 NoCloud 注入测试公钥。测试脚本由宿主机 `192.168.123.1:18080` 提供，只有测试副本的 `confhome` 改为该地址；安装、传输、恢复代码均来自当前仓库。

## 实际执行与结果

1. 在两台虚拟机中分别执行 Arch 安装，再重启进入安装后的系统：

   ```sh
   bash /root/reinstall-lab.sh arch --username root --ssh-key /root/lab.pub \
       --user-init-url http://192.168.123.1:18080/lab-user-init.sh
   ```

   两机均启动 `6.18.57-2-lts`，根文件系统为 Btrfs `@`，`@swap` 挂载到 `/swap`，EFI 挂载到 `/efi`。Snapper 的 `root` 配置存在，timeline 关闭。`LANG=en_US.UTF-8`、`GRUB_TIMEOUT=1` 均生效；首次启动脚本写入测试标记并删除自身服务。宿主机 SSH 登录两机成功。

2. 在快照服务器创建只读根快照 `/mnt/snapshot-store/remote baseline`，其中包含标记 `remote-snapshot-payload`。该路径含空格。测试快照移除了私有 SSH 主机密钥，恢复后由系统重新生成。目标机事先写入 `target-before-rollback` 标记。

3. 在目标机通过 SSH 接收并恢复该快照：

   ```sh
   bash /root/reinstall-lab.sh rollback \
       --ssh 'root@192.168.123.10:/mnt/snapshot-store/remote baseline' \
       --username root --ssh-key /root/lab.pub
   ```

   第一次实测发现：根 UUID 和目标 MAC 已正确替换，但 `fstab` 仍引用来源机器的 EFI UUID `3B47-30A8`，目标机实际为 `3B46-031A`。离线启动日志确认 `efi.mount` 和 `local-fs.target` 失败，导致无法正常启动和 SSH 登录。

4. 先增加 `/efi`、`/boot/efi` 两个回归场景，确认原代码失败，再修改恢复流程：从切换前目标系统的 `fstab` 继承相同挂载点的 vfat 设备。保留首次失败的根子卷，并从旧系统备份恢复后，重新执行完整 SSH 接收、恢复和重启。

   第二次实测通过：

   - 宿主机 SSH 登录 `192.168.123.20` 成功，恢复了源快照数据，当前根中没有目标机恢复前的标记。
   - 根 UUID 保持目标值 `f32a6fbc-a11c-41f9-933f-7af9b2b9c9cd`，EFI UUID 保持目标值 `3B46-031A`。
   - `enp1s0` 使用目标 MAC 和 IP，网络适配服务结果为 `success`。
   - `sshd`、`systemd-networkd`、`systemd-resolved`、`local-fs.target` 均 active；无失败单元，本次启动没有 error 级别日志。
   - 旧系统保存在 `@rollback-backup-*`，原标记和准备阶段成功状态仍可读取。

5. 继续检查发现，跨机接收的根快照不包含嵌套的 `/.snapshots` 子卷，Snapper 创建快照报错 `open failed path://.snapshots errno:2`。此时旧子卷仍在备份中，尚无历史快照。按“恢复后新建空子卷”的方案修复：候选系统存在 Snapper `root` 配置时，替换空占位目录、创建 `.snapshots` 子卷并设置 `750` 权限；这些步骤在切换 `@` 前完成，失败则保留当前系统。

   在目标机补建测试用 `.snapshots`，实际创建旧快照 `1`（描述为 `old-target-history-before-fix`），随后用新代码重新完成远端接收、恢复和重启。验证通过：

   - 恢复后的 `/.snapshots` 是新的、空的 Btrfs 子卷，权限为 `750 root:root`。
   - 原快照 `1/snapshot` 仍位于 `@rollback-backup-20261022-140202-2384/.snapshots`，其中的恢复前标记可读取；新系统中没有该标记。
   - Snapper 成功创建并删除新的快照 `1`，删除后列表不再显示该快照，实际快照子卷已不存在。
   - 目标 IP、根 UUID、EFI UUID 正确，SSH 和网络服务正常，没有失败单元或启动错误日志。

6. 再在目标机创建本地 Snapper 快照 `2`，快照后增加测试标记，然后执行本地恢复：

   ```sh
   bash /root/reinstall-lab.sh rollback --snapshot latest \
       --username root --ssh-key /root/lab.pub
   ```

   本地快照中 `.snapshots` 是 inode 为 `2` 的空占位目录，覆盖了与远端接收时目录缺失不同的情况。完整恢复及重启通过：恢复了快照中的数据，快照后的标记消失；新的 `/.snapshots` 是空的 Btrfs 子卷，权限为 `750`。原快照 `2/snapshot` 保留在 `@rollback-backup-20261022-140424-2383/.snapshots`。再次创建和删除新快照成功，IP、根 UUID、EFI UUID 及服务状态均正常。

## 自动检查

```sh
bash tests/rollback.sh
TEST_BUSYBOX=/usr/lib/initcpio/busybox bash tests/rollback.sh
bash tests/rollback-network.sh
TEST_BUSYBOX=/usr/lib/initcpio/busybox bash tests/rollback-network.sh
bash -n trans.sh
bash -n tests/rollback.sh
/usr/lib/initcpio/busybox ash -n trans.sh
/usr/lib/initcpio/busybox ash -n tests/rollback.sh
shfmt -ln bash trans.sh >/dev/null
shfmt -ln bash tests/rollback.sh >/dev/null
git diff --check
```

全部通过：恢复测试 20 个场景，网络测试 8 组。新增场景覆盖 Snapper 子卷缺失、空占位目录、非空目录、创建失败和设置权限失败，并检查旧快照历史保留。BusyBox 路径为本宿主机路径，其他环境需相应调整。

## 验收边界

本次真实虚拟机验证仅覆盖 x86_64、UEFI、Arch、Btrfs、systemd-networkd 和 DHCP。Netplan、NetworkManager、ifupdown、静态地址等仅经过模拟测试；没有实测 BIOS、ARM 或真实公网 VPS。

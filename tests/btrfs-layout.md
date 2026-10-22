# 顶层快照子卷验收（2026-10-23）

目标布局为 Btrfs 顶层 `@`、`@swap`、`@snapshots`，分别挂载到 `/`、`/swap`、`/.snapshots`。回滚沿用目标磁盘的 `@snapshots`，保留本机历史；没有顶层子卷时，将旧版 `@/.snapshots` 整体迁移到顶层。

旧根备份存放在 `@snapshots/rollback-backup-*`；远端只读子卷直接存放在 `@snapshots/remote-原名-时间戳-进程号`。它们与 Snapper 的数字目录并存，只有数字目录参与 `--snapshot latest` 选择。

## 真实文件系统检查

```sh
bash tests/btrfs-layout.sh
```

脚本需要 Btrfs 内核支持、btrfs-progs、util-linux、arch-install-scripts（`genfstab`）、Snapper，以及 root 或免密 sudo。它在私有挂载命名空间中创建三个 512 MiB 稀疏镜像和 loop 设备。实际调用 `trans.sh` 的格式化、Snapper 初始化和恢复函数，以及 `reinstall.sh` 的 SSH 接收函数；SSH 传输替换为本地执行发送命令，发送、接收和 Snapper 使用真实工具。验证以下四组场景：

1. 新安装和远端接收：Snapper 创建的子卷通过同一顶层挂载点移动到 `@snapshots`，生成的 `fstab` 正确挂载该子卷。跨文件系统接收后，在 `@snapshots` 下创建一级 `remote-*` 只读子卷；内容正确、`received_uuid` 与源子卷 UUID 一致，同名本机快照不被覆盖，临时接收目录已删除。恢复后，旧根在 `@snapshots/rollback-backup-*` 中，子卷 ID 不变；快照历史可列出，仍可创建新快照。
2. 本地回滚：恢复新建的本地快照并删除本次旧 `@`，较早的旧根备份、远端接收快照和本机历史全部保留，`@snapshots` 子卷 ID 不变，仍可创建新快照。
3. 失败恢复：旧布局先将远端快照接收到嵌套 `.snapshots`。模拟迁移后的 `@` 切换失败，原 `@`、嵌套 `.snapshots` 和接收快照返回原位置，数据和子卷 ID 不变。
4. 旧布局迁移和删除：恢复远端根快照时，先将本机嵌套 `.snapshots` 整体移为顶层 `@snapshots`，再将旧根移入其中并按删除策略删除。本机历史和接收快照全部保留，按修正后的 `fstab` 挂载，Snapper 能列出历史并创建新快照。

四组均通过。安装步骤中的跨挂载点 `mv` 曾被该测试检出：它会复制出普通目录，因此源和目标必须使用同一个顶层挂载点。

远端条目使用一级路径：只读接收子卷跨父目录移动会返回 `Read-only file system`，因此先接收到独立临时目录，再通过 `btrfs subvolume snapshot -r` 创建最终的一级子卷，删除临时接收子卷并移除空目录。最终子卷拥有新的本地 UUID；本机实测其只读属性和 `received_uuid` 保留，数据与来源一致。创建或清理失败会停止准备流程，保留当前系统。[内核目录移动权限检查](https://github.com/torvalds/linux/blob/v6.18/fs/namei.c)与 [Btrfs 只读语义](https://btrfs.readthedocs.io/en/latest/Subvolumes.html)说明了相关限制。

测试不运行宿主机 `systemctl`；网络适配调用使用替身，实际网络逻辑由下述独立回归测试覆盖。退出时卸载测试挂载、解除 loop 设备并删除临时镜像；若卸载失败，会停止清理并报告保留位置，避免遍历仍然挂载的目录。

## 自动回归

```sh
bash tests/rollback.sh
TEST_BUSYBOX=/usr/lib/initcpio/busybox bash tests/rollback.sh
bash tests/rollback-network.sh
TEST_BUSYBOX=/usr/lib/initcpio/busybox bash tests/rollback-network.sh
bash tests/rollback-ssh.sh
bash -n reinstall.sh trans.sh tests/rollback.sh tests/rollback-ssh.sh tests/btrfs-layout.sh
/usr/lib/initcpio/busybox ash -n trans.sh
/usr/lib/initcpio/busybox ash -n tests/rollback.sh
shfmt -ln bash trans.sh >/dev/null
shfmt -ln bash reinstall.sh >/dev/null
shfmt -ln bash tests/rollback.sh >/dev/null
shfmt -ln bash tests/rollback-ssh.sh >/dev/null
shfmt -ln bash tests/btrfs-layout.sh >/dev/null
git diff --check
```

恢复测试 30 个场景，网络测试 8 组，Bash 和 BusyBox ash 均通过。恢复场景新增旧布局迁移后旧根移动失败的撤销、已有顶层历史下切换失败还原，以及迁移后删除旧根。SSH 接收测试使用 Bash，12 个场景覆盖已有顶层布局、新建存储子卷、旧嵌套布局、同名快照、来源名称回退、发送失败、接收失败、接收结果缺失、一级只读快照创建失败、临时子卷删除失败、临时目录删除失败和错误类型的存储路径。语法和差异检查通过。BusyBox 路径为本机路径，其他环境需调整。

## 验收边界与进度

实现、真实存储验证及自动回归已完成。本次没有新建或启动虚拟机，没有在 `ali.hk2` 或 `mhy.hk` 执行修改。现有服务器不会随代码修改自动迁移；历史版本留下的 `@rollback-backup-*` 中的嵌套子卷也不会被自动搬出。

该布局尚未重新验证完整安装、引导、网络和外部 SSH。之前的 [双虚拟机验收](vm-acceptance.md) 覆盖旧嵌套布局，只能作为当时版本的历史记录。

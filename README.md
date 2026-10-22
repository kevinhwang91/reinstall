<!-- markdownlint-disable MD028 MD033 MD045 -->

# reinstall

[![Codacy](https://img.shields.io/codacy/grade/dc679a17751448628fe6d8ac35e26eed?logo=Codacy&label=Codacy&style=flat-square)](https://app.codacy.com/gh/bin456789/reinstall/dashboard)
[![CodeFactor](https://img.shields.io/codefactor/grade/github/bin456789/reinstall?logo=CodeFactor&logoColor=white&label=CodeFactor&style=flat-square)](https://www.codefactor.io/repository/github/bin456789/reinstall)
[![Lines of Code](https://aschey.tech/tokei/github/bin456789/reinstall?category=code&label=Lines%20of%20Code&style=flat-square)](https://github.com/aschey/vercel-tokei)
<!-- [![Lines of Code](https://tokei.rs/b1/github/bin456789/reinstall?category=code&label=Lines%20of%20Code&style=flat-square)](https://github.com/XAMPPRocky/tokei_rs) -->

<a href="https://trendshift.io/repositories/14732"><img src="https://trendshift.io/api/badge/repositories/14732" alt="bin456789%2Freinstall | Trendshift" width="250" height="55"/></a>

一键 VPS 系统重装脚本 [English](README.en.md)

## 介绍

- 一键重装到 Linux，支持 20 种常见发行版
- 一键重装到 Windows，使用官方原版 ISO 而非自制镜像，支持自动查找 ISO 链接、自动安装 `VirtIO` 等公有云驱动
- 支持任意方向重装，即 `Linux to Linux`、`Linux to Windows`、`Windows to Windows`、`Windows to Linux`
- 自动设置 IP，智能设置动静态，支持 `/32`、`/128`、`网关不在子网范围内`、`纯 IPv6`、`IPv4/IPv6 在不同网卡`
- 专门适配低配小鸡，比官方 netboot 需要更少的内存
- 全程用分区表 ID 识别硬盘，确保不会写错硬盘
- 支持 BIOS、EFI 引导，支持 ARM 服务器
- 不含自制包，所有资源均实时从镜像源获得

请我喝奶茶：
[![Donate](https://img.shields.io/badge/Donate-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/bin456789)

[![Sponsors](https://raw.githubusercontent.com/bin456789/sponsors/refs/heads/master/sponsors.svg)](https://github.com/sponsors/bin456789)

### 反馈

[![GitHub Issues](https://img.shields.io/badge/GitHub-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/bin456789/reinstall/issues)
[![Telegram Group](https://img.shields.io/badge/Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/reinstall_os)

## 快速开始

- [下载](#下载当前系统是--linux)
- [功能 1. 一键重装到 Linux](#功能-1-安装--linux)
- [功能 2. 一键 DD Raw 镜像到硬盘](#功能-2-dd-raw-镜像到硬盘)
- [功能 3. 一键引导到 Alpine Live OS 内存系统](#功能-3-重启到--alpine-live-os内存系统)
- [功能 4. 一键引导到 netboot.xyz](#功能-4-重启到--netbootxyz)
- [功能 5. 一键重装到 Windows](#功能-5-安装--windows-iso)
- [取消重装](#取消重装)

## 系统要求

原系统可以是表格中的任意系统

目标系统的配置要求如下：

| 系统                                                                                                                                                                                                                                                                                                                                                                   | 版本                                  | 内存      | 硬盘         |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- | --------- | ------------ |
| <img width="16" height="16" src="https://www.alpinelinux.org/alpine-logo.ico" /> Alpine                                                                                                                                                                                                                                                                                | 3.21, 3.22, 3.23, 3.24                | 256 MB    | 1 GB         |
| <img width="16" height="16" src="https://www.debian.org/favicon.ico" /> Debian                                                                                                                                                                                                                                                                                         | 9 ELTS - 11 ELTS, 12, 13              | 256 MB    | 1 ~ 1.5 GB ^ |
| <img width="16" height="16" src="https://github.com/bin456789/reinstall/assets/7548515/f74b3d5b-085f-4df3-bcc9-8a9bd80bb16d" /> Kali                                                                                                                                                                                                                                   | Last-Snapshot, Rolling (滚动)         | 256 MB    | 1 ~ 1.5 GB ^ |
| <img width="16" height="16" src="https://documentation.ubuntu.com/server/_static/favicon.png" /> Ubuntu                                                                                                                                                                                                                                                                | 18.04 LTS - 26.04 LTS, 26.10          | 512 MB \* | 2 GB         |
| <img width="16" height="16" src="https://img.alicdn.com/imgextra/i1/O1CN01oJnJZg1yK4RzI4Rx2_!!6000000006559-2-tps-118-118.png" /> Anolis                                                                                                                                                                                                                               | 7, 8, 23                              | 512 MB \* | 5 GB         |
| <img width="16" height="16" src="https://www.redhat.com/favicon.ico" /> RHEL &nbsp;<img width="16" height="16" src="https://almalinux.org/fav/favicon.ico" /> AlmaLinux &nbsp;<img width="16" height="16" src="https://rockylinux.org/favicon.png" /> Rocky &nbsp;<img width="16" height="16" src="https://www.oracle.com/asset/web/favicons/favicon-32.png" /> Oracle | 8, 9, 10                              | 512 MB \* | 5 GB         |
| <img width="16" height="16" src="https://opencloudos.org/qq.ico" /> OpenCloudOS                                                                                                                                                                                                                                                                                        | 8, 9, Stream 23                       | 512 MB \* | 5 GB         |
| <img width="16" height="16" src="https://www.centos.org/assets/icons/favicon.svg" /> CentOS Stream                                                                                                                                                                                                                                                                     | 9, 10                                 | 512 MB \* | 5 GB         |
| <img width="16" height="16" src="https://fedoraproject.org/favicon.ico" /> Fedora                                                                                                                                                                                                                                                                                      | 43, 44                                | 512 MB \* | 5 GB         |
| <img width="16" height="16" src="https://www.openeuler.org/favicon.ico" /> openEuler                                                                                                                                                                                                                                                                                   | 20.03 LTS - 24.03 LTS, 26.09          | 512 MB \* | 5 GB         |
| <img width="16" height="16" src="https://static.opensuse.org/favicon.ico" /> openSUSE                                                                                                                                                                                                                                                                                  | Leap 16.0, Tumbleweed (滚动)          | 512 MB \* | 5 GB         |
| <img width="16" height="16" src="https://nixos.org/favicon.svg" /> NixOS                                                                                                                                                                                                                                                                                               | 26.05                                 | 512 MB    | 5 GB         |
| <img width="16" height="16" src="https://archlinux.org/static/favicon.png" /> Arch Linux / Arch Linux ARM                                                                                                                                                                                                                                                              | 滚动                                  | 512 MB    | 5 GB         |
| <img width="16" height="16" src="https://www.gentoo.org/assets/img/logo/gentoo-g.png" /> Gentoo                                                                                                                                                                                                                                                                        | 滚动                                  | 512 MB    | 5 GB         |
| <img width="16" height="16" src="https://aosc.io/distros/aosc-os.svg" /> 安同 OS                                                                                                                                                                                                                                                                                       | 滚动                                  | 512 MB    | 5 GB         |
| <img width="16" height="16" src="https://www.fnnas.com/favicon.ico" /> 飞牛 fnOS &nbsp;<img width="16" height="16" src="https://fygonas.com/favicon.ico" /> FygoOS                                                                                                                                                                                                     | 1                                     | 512 MB    | 10 GB        |
| <img width="16" height="16" src="https://blogs.windows.com/wp-content/uploads/prod/2022/09/cropped-Windows11IconTransparent512-32x32.png" /> Windows (DD)                                                                                                                                                                                                              | 任何                                  | 512 MB    | 取决于镜像   |
| <img width="16" height="16" src="https://blogs.windows.com/wp-content/uploads/prod/2022/09/cropped-Windows11IconTransparent512-32x32.png" /> Windows (ISO)                                                                                                                                                                                                             | Vista, 7, 8.x (Server 2008 - 2012 R2) | 512 MB    | 25 GB        |
| <img width="16" height="16" src="https://blogs.windows.com/wp-content/uploads/prod/2022/09/cropped-Windows11IconTransparent512-32x32.png" /> Windows (ISO)                                                                                                                                                                                                             | 10, 11 (Server 2016 - 2025)           | 1 GB      | 25 GB        |

\* 表示使用云镜像安装，非传统网络安装

^ 表示需要 256 MB 内存 + 1.5 GB 硬盘，或 512 MB 内存 + 1 GB 硬盘

> [!WARNING]
>
> 本脚本理论上支持独服和 PC
>
> 但如果能使用 IPMI 或 U 盘，则不建议使用本脚本

> [!WARNING]
>
> ❌ 本脚本不支持 OpenVZ、LXC 虚拟机
>
> 请改用 <https://github.com/LloydAsp/OsMutation>

## 下载（当前系统是 <img width="20" height="20" src="https://www.kernel.org/theme/images/logos/favicon.png" /> Linux）

国外服务器：

```bash
curl -O https://raw.githubusercontent.com/kevinhwang91/reinstall/main/reinstall.sh || wget -O ${_##*/} $_
```

国内服务器：

```bash
curl -O https://raw.githubusercontent.com/kevinhwang91/reinstall/main/reinstall.sh || wget -O ${_##*/} $_
```

## 下载（当前系统是 <img width="20" height="20" src="https://blogs.windows.com/wp-content/uploads/prod/2022/09/cropped-Windows11IconTransparent512-32x32.png" /> Windows）

> [!IMPORTANT]
> 请先关闭 `Windows Defender` 的 `实时保护` 功能。该功能会阻止 `certutil` 下载任何文件。

<details>

<summary>解决 Windows 7 下无法下载脚本</summary>

由于不支持 TLS 1.2、SHA-256、根证书没有更新等原因，Vista，7 和 Server 2008 (R2) 可能无法自动下载脚本，因此需要手动下载，具体操作如下：

用 IE 下载 (先在 IE 高级设置里启用 TLS 1.2)，或者通过远程桌面，将这两个文件保存到同一个目录

- <https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.bat>

- <https://www.cygwin.com/setup-x86.exe>

使用时运行下载的 `reinstall.bat`

</details>

国外服务器：

```batch
certutil -urlcache -f -split https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.bat
```

国内服务器：

```batch
certutil -urlcache -f -split https://cnb.cool/bin456789/reinstall/-/git/raw/main/reinstall.bat
```

## 使用

**所有功能** 都可在 Linux / Windows 下运行

- Linux 下运行 `bash reinstall.sh ...`
- Windows 下先运行 `cmd`，再运行 `reinstall.bat ...`
  - 如果参数中的链接包含特殊字符，要用 `""` 将链接包裹起来，不能用 `''`

### 功能 1: 安装 <img width="16" height="16" src="https://www.kernel.org/theme/images/logos/favicon.png" /> Linux

> [!CAUTION]
>
> 此功能会清除当前系统**整个硬盘**的全部数据（包含其它分区）！
>
> 如果不小心运行了脚本，可以在重启前运行 `bash reinstall.sh reset` 取消重装

- 脚本会提示输入用户名和密码，不输入则使用 `root` 和随机密码
- 不输入版本号则安装最新版
- 最大化利用磁盘空间：不含 boot 和 swap 分区
- 自动根据机器类型和商家安装优化内核
- 安装 Red Hat 时需填写 <https://access.redhat.com/downloads/content/rhel> 得到的 `qcow2` 镜像链接，也可以安装其它类 RHEL 系统的 `qcow2`，例如 `Alibaba Cloud Linux` 和 `TencentOS Server`
- 重装后如需修改 SSH 端口或者改成密钥登录，注意还要修改 `/etc/ssh/sshd_config.d/` 里面的文件
- 为了快速安装，重装时不会对新系统进行更新，请在重装后自行更新
- Arch 默认使用 Btrfs（顶层子卷 `@` 挂载到 `/`、`@swap` 挂载到 `/swap`、`@snapshots` 挂载到 `/.snapshots`）、Snapper 和 LTS 内核，语言为 `en_US.UTF-8`，GRUB 等待 1 秒。
- 安装飞牛 fnOS/FygoOS 时设置的用户名、密码、密钥仅用于安装期间登录 SSH 查看日志，不会应用到新系统。系统安装后需到后台面板 <http://IP:5666> 创建用户和开启 SSH

```bash
bash reinstall.sh anolis      7|8|23
                  rocky       8|9|10
                  oracle      8|9|10
                  almalinux   8|9|10
                  opencloudos 8|9|23
                  centos      9|10
                  fnos        1
                  fygoos      1
                  nixos       26.05
                  fedora      43|44
                  debian      9|10|11|12|13
                  opensuse    16.0|tumbleweed
                  alpine      3.21|3.22|3.23|3.24
                  kali        last-snapshot|rolling
                  openeuler   20.03|22.03|24.03|26.09
                  ubuntu      18.04|20.04|22.04|24.04|26.04|26.10 [--minimal]
                  arch
                  gentoo
                  aosc
                  redhat      --img="http://access.cdn.redhat.com/xxx.qcow2"
```

#### 可选参数

- `--username USERNAME` 设置用户名
- `--password PASSWORD` 设置密码
- `--ssh-key KEY` 设置 SSH 登录公钥，[格式如下](#--ssh-key)。当使用公钥时，密码为空
- `--ssh-port PORT` 修改 SSH 端口
- `--web-port PORT` 修改 Web 端口（安装期间观察日志用）
- `--frpc-config PATH` 添加 frpc 内网穿透，参数填配置文件的本地路径或 HTTP 链接
- `--no-cloud-kernel` 不使用云内核，避免部分机器黑屏/花屏，适用于 Debian、Ubuntu、Alpine、openSUSE
- `--user-init-url URL` 添加用户自定义 VPS 初始化脚本，支持 systemd Linux，首次启动执行，输出查看 `journalctl -u reinstall-user-init.service`，执行后自动清理脚本和服务
- `--hold 1` 仅重启到安装环境，不运行安装，用于 SSH 登录验证网络连通性
- `--hold 2` 安装结束后不重启，用于 SSH 登录修改系统内容，Debian/Kali 会挂载在 `/target`，其它系统会挂载在 `/os`

> [!TIP]
>
> 可通过多种方式（SSH、HTTP 80 端口、商家后台 VNC、串行控制台）查看安装进度。
>
> 即使安装过程出错，也能连接 SSH 手动救砖。
>
> 目标系统非 Debian/Kali 时，可以运行 `/trans.sh alpine` 自动救砖成 Alpine 系统。

<details>

<summary>已弃用的功能</summary>

云镜像安装 Debian

- 适合于 CPU 较慢的机器

```bash
bash reinstall.sh debian --ci
```

ISO 安装 CentOS, AlmaLinux, Rocky, Fedora

- 仅支持内存大于 2G 且为动态 IP 的机器
- 用户名 `root`，密码 `123@@@`，SSH 端口 `22`，不支持用参数修改

```bash
bash reinstall.sh centos --installer
bash reinstall.sh almalinux --installer
bash reinstall.sh rocky --installer
bash reinstall.sh fedora --installer
```

ISO 安装 Ubuntu

- 仅支持内存大于 1G 且为动态 IP 的机器
- 用户名 `root`，密码 `123@@@`，SSH 端口 `22`，不支持用参数修改

```bash
bash reinstall.sh ubuntu --installer
```

</details>

### 功能 2: DD RAW 镜像到硬盘

> [!CAUTION]
>
> 此功能会清除当前系统**整个硬盘**的全部数据（包含其它分区）！
>
> 如果不小心运行了脚本，可以在重启前运行 `bash reinstall.sh reset` 取消重装

- 支持 `raw` 和固定大小的 `vhd` 镜像。未压缩或者压缩成 `.gz` `.xz` `.zst` `.tar` `.tar.gz` `.tar.xz` `.tar.zst`
- DD Windows 镜像时，会自动扩展系统盘，静态 IP 的机器会配置好 IP，可能首次开机几分钟后才生效
- DD Linux 镜像时，**不会**修改镜像的任何内容
- 脚本会提示输入用户名和密码，用于安装时 SSH 登录观察日志，不输入则使用 `root` 和随机密码

```bash
bash reinstall.sh dd --img "https://example.com/xxx.xz"
```

#### 可选参数

- `--username USERNAME` 设置用户名（安装期间观察日志用）
- `--password PASSWORD` 设置密码（安装期间观察日志用）
- `--ssh-key KEY` 设置 SSH 登录公钥（安装期间观察日志用），[格式如下](#--ssh-key)。当使用公钥时，密码为空
- `--ssh-port PORT` 修改 SSH 端口（安装期间观察日志用）
- `--rdp-port PORT` 修改 RDP 端口（仅限 DD Windows）
- `--web-port PORT` 修改 Web 端口（安装期间观察日志用）
- `--allow-ping` 设置 Windows 防火墙允许被 Ping（仅限 DD Windows）
- `--frpc-config PATH` 添加 frpc 内网穿透（仅限 DD Windows），参数填配置文件的本地路径或 HTTP 链接
- `--cloud-data PATH_OR_URL` 为 DD Linux 镜像注入 cloud-init NoCloud 配置（仅限 DD Linux）
- `--hold 1` 仅重启到安装环境，不运行安装，用于 SSH 登录验证网络连通性
- `--hold 2` DD 结束后不重启，用于 SSH 登录修改系统内容，Windows 系统会挂载在 `/os`，Linux 系统**不会**自动挂载

> [!TIP]
>
> `--cloud-data` 参数为本地目录或 HTTP 基础 URL，目录须包含 `user-data` 文件，`meta-data`、`network-config` 可选：
>
> ```bash
> seed/
> ├── user-data      # 必须
> ├── meta-data      # 可选
> └── network-config # 可选
> ```
>
> ```bash
> # 使用本地目录
> bash reinstall.sh dd --img "https://example.com/xxx.xz" --cloud-data /path/to/seed/
> # 使用 HTTP 目录
> bash reinstall.sh dd --img "https://example.com/xxx.xz" --cloud-data "https://example.com/seed/"
> ```

> [!TIP]
>
> 可通过多种方式（SSH、HTTP 80 端口、商家后台 VNC、串行控制台）查看安装进度。
>
> 即使安装过程出错，也能连接 SSH 手动救砖
>
> 也可以运行 `/trans.sh alpine` 自动救砖成 Alpine 系统。

### 功能 3: 重启到 <img width="16" height="16" src="https://www.alpinelinux.org/alpine-logo.ico" /> Alpine Live OS（内存系统）

- 可用 ssh 连接，进行备份/恢复硬盘、手动 DD、修改分区、手动安装 Alpine 等操作
- 脚本会提示输入用户名和密码，不输入则使用 `root` 和随机密码

> [!TIP]
>
> 虽然运行的脚本叫 `reinstall`，但是此功能**不会**删除任何数据和进行自动重装，而是要用户手动操作
>
> 如果用户手动操作没有破坏原系统，再次重启将回到原系统

```bash
bash reinstall.sh alpine --hold 1
```

#### 可选参数

- `--username USERNAME` 设置用户名
- `--password PASSWORD` 设置密码
- `--ssh-key KEY` 设置 SSH 登录公钥，[格式如下](#--ssh-key)。当使用公钥时，密码为空
- `--ssh-port PORT` 修改 SSH 端口
- `--frpc-config PATH` 添加 frpc 内网穿透，参数填配置文件的本地路径或 HTTP 链接

#### Btrfs 快照恢复

```bash
bash reinstall.sh rollback --snapshot latest
bash reinstall.sh rollback --ssh root@backup-host:/.snapshots/123/snapshot
```

恢复前自动比较当前系统与快照的网络配置；有差异时保留当前 VPS 的配置，包括 MAC 绑定、DHCP/SLAAC、静态地址、路由、DNS 和 MTU。忽略整行注释、空行和行尾空白，不复制 DHCP 租约。恢复后首次启动会按当前 MAC 校正网卡名。

跨磁盘恢复会更新根分区 UUID，并沿用目标系统 `fstab` 中相同挂载点（`/efi` 或 `/boot/efi`）的 EFI 分区设备，避免引用快照来源机器的 EFI 分区。

远端快照直接保存在 `@snapshots/remote-原名-时间戳-进程号`，启动后可从 `/.snapshots/remote-*` 访问。每次先接收到独立临时目录，再创建一级只读快照并删除临时接收子卷和目录，避免覆盖本机同名快照；这些远端条目不加入 Snapper 的编号历史。旧嵌套布局会先保存到原有 `.snapshots` 中，再随恢复整体迁移到顶层。

如果恢复的系统已有 Snapper 的 `root` 配置，会沿用目标磁盘的顶层 `@snapshots`，并更新 `fstab`，将其挂载到 `/.snapshots`。本机快照历史独立于 `@`，回滚或删除旧系统不会删除这些历史。若尚无顶层 `@snapshots`，会将旧布局中的 `@/.snapshots` 连同完整历史迁移到顶层；两者均不存在时才创建空子卷。候选系统的挂载目录非空或子卷准备失败时会停止恢复；迁移或切换失败时会还原旧布局。

支持使用相同网络管理方式的 systemd 系统：networkd、Netplan、NetworkManager（以太网配置）和 ifupdown。跨管理器、多个公网出口或 bridge/bond/VLAN 等复杂拓扑会在准备阶段停止。当前根文件系统须为 Btrfs；候选系统的网络适配完成后才切换 `@`，默认将旧根子卷保留在 `@snapshots/rollback-backup-*`，启动后可通过 `/.snapshots/rollback-backup-*` 访问。这些备份独立于 Snapper 的编号快照。`--rollback-delete-backup` 只在切换完成后删除本次旧根备份，保留其余快照和备份；它并不代表已验证恢复后的 SSH 可达性。

开发验证：`bash tests/rollback.sh`、`bash tests/rollback-network.sh` 和 `bash tests/rollback-ssh.sh`；前两组也可设置 `TEST_BUSYBOX`，用 BusyBox ash 运行。`bash tests/btrfs-layout.sh` 使用临时 loop 设备验证真实 Btrfs 和 Snapper，需要 root 或免密 sudo 及相应工具，结束后自动清理。[存储布局验收记录](tests/btrfs-layout.md)。真实恢复后的网络和外部 SSH 访问需另外验收。

### 功能 4: 重启到 <img width="16" height="16" src="https://netboot.xyz/img/favicon.ico" /> netboot.xyz

- 可使用商家后台 VNC 手动安装 [更多系统](https://github.com/netbootxyz/netboot.xyz?tab=readme-ov-file#what-operating-systems-are-currently-available-on-netbootxyz)

> [!TIP]
>
> 虽然运行的脚本叫 `reinstall`，但是此功能**不会**删除任何数据和进行自动重装，而是要用户手动操作
>
> 如果用户手动操作没有破坏原系统，再次重启将回到原系统

```bash
bash reinstall.sh netboot.xyz
```

![netboot.xyz](https://netboot.xyz/images/netboot.xyz.gif)

### 功能 5: 安装 <img width="16" height="16" src="https://blogs.windows.com/wp-content/uploads/prod/2022/09/cropped-Windows11IconTransparent512-32x32.png" /> Windows ISO

![Windows 安装界面](https://github.com/bin456789/reinstall/assets/7548515/07c1aea2-1ce3-4967-904f-aaf9d6eec3f7)

> [!CAUTION]
>
> 此功能会清除当前系统**整个硬盘**的全部数据（包含其它分区）！
>
> 如果不小心运行了脚本，可以在重启前运行 `bash reinstall.sh reset` 取消重装

- 脚本会提示输入用户名和密码，不输入则使用 `administrator` 和随机密码
- 如果远程登录失败，请尝试在用户名前添加 `.\`，例如 `.\administrator`
- 少数语言的系统管理员账号不是 `administrator` [详情](https://learn.microsoft.com/archive/technet-wiki/13813.localized-names-for-administrator-account-in-windows#list-of-languages-that-localize-the-administrator-account-name)
- 静态机器会自动配置好 IP，可能首次开机几分钟后才生效
- 支持任意语言的 ISO
- 自动绕过 Windows 11 硬件限制

#### 支持的系统

- Windows (Vista ~ 11)
- Windows Server (2008 ~ 2025)
  - Windows Server Essentials
  - Windows Server (Semi) Annual Channel
  - Hyper-V Server
  - Azure Local (Azure Stack HCI)

#### 方法 1: 让脚本自动查找 ISO

- 脚本会从 <https://ntriver.org/download-windows-office> 查找 ISO，该网站专门收集官方 ISO 镜像
- 默认查找 64 位系统镜像，除非指定了 `--bit 32`

```bash
bash reinstall.sh windows \
     --image-name "Windows 11 Enterprise LTSC 2024" \
     --lang zh-cn
```

<details>
<summary>--image-name 列表</summary>

以下版本支持自动查找，其它版本请用方法 2 手动指定 ISO 链接安装

```text
Windows Vista Starter
Windows Vista HomeBasic
Windows Vista HomePremium
Windows Vista Business
Windows Vista Ultimate
Windows Vista Enterprise

Windows 7 Starter
Windows 7 HomeBasic
Windows 7 HomePremium
Windows 7 Professional
Windows 7 Ultimate
Windows 7 Enterprise

Windows 8
Windows 8 Pro
Windows 8 Enterprise

Windows 8.1
Windows 8.1 Pro
Windows 8.1 Enterprise

Windows 10 Home
Windows 10 Home Single Language
Windows 10 Pro
Windows 10 Pro Education
Windows 10 Pro for Workstations
Windows 10 Education
Windows 10 Enterprise
Windows 10 Enterprise 2015 LTSB
Windows 10 Enterprise 2016 LTSB
Windows 10 Enterprise LTSC 2019
Windows 10 Enterprise LTSC 2021
Windows 10 IoT Enterprise
Windows 10 IoT Enterprise 2015 LTSB
Windows 10 IoT Enterprise 2016 LTSB
Windows 10 IoT Enterprise LTSC 2019
Windows 10 IoT Enterprise LTSC 2021

Windows 11 Home
Windows 11 Home Single Language
Windows 11 Pro
Windows 11 Pro Education
Windows 11 Pro for Workstations
Windows 11 Education
Windows 11 Enterprise
Windows 11 Enterprise LTSC 2024
Windows 11 IoT Enterprise
Windows 11 IoT Enterprise LTSC 2024
Windows 11 IoT Enterprise Subscription
Windows 11 IoT Enterprise Subscription LTSC 2024

Windows Longhorn ServerWeb
Windows Longhorn ServerWebCore
Windows Longhorn ServerStandard
Windows Longhorn ServerStandardCore
Windows Longhorn ServerEnterprise
Windows Longhorn ServerEnterpriseCore
Windows Longhorn ServerDatacenter
Windows Longhorn ServerDatacenterCore

Windows Server 2008 R2 ServerWeb
Windows Server 2008 R2 ServerWebCore
Windows Server 2008 R2 ServerStandard
Windows Server 2008 R2 ServerStandardCore
Windows Server 2008 R2 ServerEnterprise
Windows Server 2008 R2 ServerEnterpriseCore
Windows Server 2008 R2 ServerDatacenter
Windows Server 2008 R2 ServerDatacenterCore

Windows Server 2012 ServerStandard
Windows Server 2012 ServerStandardCore
Windows Server 2012 ServerDatacenter
Windows Server 2012 ServerDatacenterCore

Windows Server 2012 R2 ServerStandard
Windows Server 2012 R2 ServerStandardCore
Windows Server 2012 R2 ServerDatacenter
Windows Server 2012 R2 ServerDatacenterCore

Windows Server 2016 ServerStandard
Windows Server 2016 ServerStandardCore
Windows Server 2016 ServerDatacenter
Windows Server 2016 ServerDatacenterCore

Windows Server 2019 ServerStandard
Windows Server 2019 ServerStandardCore
Windows Server 2019 ServerDatacenter
Windows Server 2019 ServerDatacenterCore

Windows Server 2022 ServerStandard
Windows Server 2022 ServerStandardCore
Windows Server 2022 ServerDatacenter
Windows Server 2022 ServerDatacenterCore

Windows Server 2025 ServerStandard
Windows Server 2025 ServerStandardCore
Windows Server 2025 ServerDatacenter
Windows Server 2025 ServerDatacenterCore
```

</details>

<details>
<summary>--lang 列表</summary>

支持这三种语言代码格式，不区分大小写

| CC 格式 | CC-CC 格式 | 语言 |
| - | - | - |
| ar | ar-sa | Arabic |
| bg | bg-bg | Bulgarian |
| cs | cs-cz | Czech |
| da | da-dk | Danish |
| de | de-de | German |
| el | el-gr | Greek |
| gb | en-gb | Eng_Intl |
| en | en-us | English |
| es | es-es | Spanish |
| mx | es-mx | Spanish_Latam |
| et | et-ee | Estonian |
| fi | fi-fi | Finnish |
| | fr-ca | FrenchCanadian |
| fr | fr-fr | French |
| he | he-il | Hebrew |
| hr | hr-hr | Croatian |
| hu | hu-hu | Hungarian |
| it | it-it | Italian |
| ja | ja-jp | Japanese |
| ko | ko-kr | Korean |
| lt | lt-lt | Lithuanian |
| lv | lv-lv | Latvian |
| no | nb-no | Norwegian |
| nl | nl-nl | Dutch |
| pl | pl-pl | Polish |
| pp | pt-pt | Portuguese |
| pt | pt-br | Brazilian |
| ro | ro-ro | Romanian |
| ru | ru-ru | Russian |
| sk | sk-sk | Slovak |
| sl | sl-si | Slovenian |
| sr | sr-latn / sr-latn-rs | Serbian_Latin |
| sv | sv-se | Swedish |
| th | th-th | Thai |
| tr | tr-tr | Turkish |
| uk | uk-ua | Ukrainian |
| cn | zh-cn | ChnSimp |
| tw | zh-tw | ChnTrad |
| hk | zh-hk | ChnTrad_Hong_Kong |

</details>

#### 方法 2: 自行指定 ISO 连接

- 如果不知道 `--image-name`，可以随便填，在重启后连接 SSH，根据错误提示重新输入正确的值

```bash
bash reinstall.sh windows \
     --image-name "Windows 11 Enterprise LTSC 2024 Evaluation" \
     --iso "https://go.microsoft.com/fwlink/?linkid=2289029"
```

或者磁力链接

```bash
bash reinstall.sh windows \
     --image-name "Windows 11 Enterprise LTSC 2024" \
     --iso "magnet:?xt=urn:btih:7352bd2db48c3381dffa783763dc75aa4a6f1cff"
```

<details>

<summary>以下网站可找到 ISO 链接</summary>

- 正式版
  - <https://ntriver.org/download-windows-office> (推荐，ISO 是最新版)
  - <https://massgrave.dev/genuine-installation-media> (推荐，ISO 是最新版)
  - <https://next.itellyou.cn>
  - <https://www.xitongku.com>
  - <https://www.microsoft.com/software-download/windows10> (需用非 Windows User-Agent 打开)
  - <https://www.microsoft.com/software-download/windows11>
  - <https://www.microsoft.com/software-download/windows11arm64>
- 评估版
  - <https://www.microsoft.com/evalcenter/download-windows-11-enterprise>
  - <https://www.microsoft.com/evalcenter/download-windows-11-iot-enterprise-ltsc-eval>
  - <https://www.microsoft.com/evalcenter/download-windows-server-2012-r2>
  - <https://www.microsoft.com/evalcenter/download-windows-server-2016>
  - <https://www.microsoft.com/evalcenter/download-windows-server-2019>
  - <https://www.microsoft.com/evalcenter/download-windows-server-2022>
  - <https://www.microsoft.com/evalcenter/download-windows-server-2025>
- Insider 预览版
  - <https://www.microsoft.com/en-us/software-download/windowsinsiderpreviewiso>
  - <https://www.microsoft.com/en-us/software-download/windowsinsiderpreviewserver>

</details>

#### 可选参数

- `--username USERNAME` 设置用户名
- `--password PASSWORD` 设置密码
- `--rdp-port PORT` 修改 RDP 端口
- `--ssh-port PORT` 修改 SSH 端口（安装期间观察日志用）
- `--web-port PORT` 修改 Web 端口（安装期间观察日志用）
- `--allow-ping` 设置 Windows 防火墙允许被 Ping
- `--add-driver INF_OR_DIR` 添加额外驱动，填写 .inf 路径，或者 .inf 所在的文件夹
  - 需先下载驱动到当前系统
  - 可多次设置该参数以添加不同的驱动
- `--no-auto-drivers` 禁止脚本自动下载驱动，你需要用 `--add-driver` 补全驱动
- `--frpc-config PATH` 添加 frpc 内网穿透，参数填配置文件的本地路径或 HTTP 链接
- `--hold 1` 仅重启到安装环境，不运行安装，用于 SSH 登录验证网络连通性
- `--hold 2` 用于在进入 Windows 官方安装程序之前，SSH 登录修改 `boot.wim`、`install.wim` 或者其它内容，硬盘挂载在 `/os`

#### 以下驱动会自动按需下载安装，使用 `--no-auto-drivers` 可禁止此功能

- VirtIO ([社区版][virtio-virtio], [阿里云][virtio-aliyun], [腾讯云][virtio-qcloud], [GCP][virtio-gcp], [GCP (Win7/2008 SHA-1)][virtio-gcp-win6.1sha1])
- XEN ([~~社区版~~][xen-xen] (未签名), [Citrix][xen-citrix], [AWS][xen-aws])
- AWS ([ENA 网卡][aws-ena], [NVMe 存储控制器][aws-nvme], [VMClock 虚拟时钟][aws-vmclock], [PCI 串口][aws-pciserial])
- GCP ([gVNIC 网卡][gcp-gvnic], [GGA 显卡][gcp-gga])
- Azure ([MANA 网卡][azure-mana])
- Intel (VMD 存储控制器: [11代酷睿][intel-vmd-gen11], [12-15代酷睿][intel-vmd-gen12-to-gen15], [酷睿 Ultra 3][intel-vmd-ultra3], 网卡: [7][intel-nic-7], [8.x][intel-nic-8.1], [10][intel-nic-10], [11][intel-nic-11], [2008 R2][intel-nic-7], [2012][intel-nic-2012], [2012 R2][intel-nic-2012-r2], [2016][intel-nic-2016], [2019][intel-nic-2019], [2022][intel-nic-2022], [2025][intel-nic-2025])

[virtio-virtio]: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/
[virtio-aliyun]: https://www.alibabacloud.com/help/ecs/user-guide/install-the-virtio-driver-1
[virtio-qcloud]: https://cloud.tencent.com/document/product/213/17815#b84b2032-752c-43c4-a509-73530b8f82ff
[virtio-gcp]: https://packages.cloud.google.com/yuck/repos/google-compute-engine-stable/index
[virtio-gcp-win6.1sha1]: https://console.cloud.google.com/storage/browser/gce-windows-drivers-public/win6.1sha1
[xen-xen]: https://xenbits.xenproject.org/pvdrivers/win/
[xen-aws]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/xen-drivers-overview.html
[xen-citrix]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Upgrading_PV_drivers.html#win2008-citrix-upgrade
[aws-ena]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ena-driver-releases-windows.html
[aws-nvme]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nvme-driver-version-history.html
[aws-vmclock]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/other-windows-device-drivers.html
[aws-pciserial]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/migrating-latest-types.html#install-serial-port-bare-metal
[gcp-gvnic]: https://packages.cloud.google.com/yuck/repos/google-compute-engine-driver-gvnic-stable/index
[gcp-gga]: https://packages.cloud.google.com/yuck/repos/google-compute-engine-driver-gga-stable/index
[azure-mana]: https://learn.microsoft.com/azure/virtual-network/accelerated-networking-mana-windows
[intel-vmd-gen11]: https://www.intel.com/content/www/us/en/download/849933/intel-rapid-storage-technology-driver-installation-software-with-intel-optane-memory-12th-to-13th-gen-platforms.html
[intel-vmd-gen12-to-gen15]: https://www.intel.com/content/www/us/en/download/849936/intel-rapid-storage-technology-driver-installation-software-with-intel-optane-memory-12th-to-15th-gen-platforms.html
[intel-vmd-ultra3]: https://www.intel.com/content/www/us/en/download/920456/intel-rapid-storage-technology-driver-installation-software-for-intel-core-ultra-series-3-platforms.html
[intel-nic-7]: https://www.intel.com/content/www/us/en/download/15590/intel-network-adapter-driver-for-windows-7-final-release.html
[intel-nic-8.1]: https://www.intel.com/content/www/us/en/download/17479/intel-network-adapter-driver-for-windows-8-1.html
[intel-nic-10]: https://www.intel.com/content/www/us/en/download/18293/intel-network-adapter-driver-for-windows-10.html
[intel-nic-11]: https://www.intel.com/content/www/us/en/download/727998/intel-network-adapter-driver-for-microsoft-windows-11.html
[intel-nic-2012]: https://www.intel.com/content/www/us/en/download/16789/intel-network-adapter-driver-for-windows-server-2012.html
[intel-nic-2012-r2]: https://www.intel.com/content/www/us/en/download/17480/intel-network-adapter-driver-for-windows-server-2012-r2.html
[intel-nic-2016]: https://www.intel.com/content/www/us/en/download/18737/intel-network-adapter-driver-for-windows-server-2016.html
[intel-nic-2019]: https://www.intel.com/content/www/us/en/download/19372/intel-network-adapter-driver-for-windows-server-2019.html
[intel-nic-2022]: https://www.intel.com/content/www/us/en/download/706171/intel-network-adapter-driver-for-windows-server-2022.html
[intel-nic-2025]: https://www.intel.com/content/www/us/en/download/838943/intel-network-adapter-driver-for-windows-server-2025.html

#### 如何填写映像名称 `--image-name`

一个 ISO 通常包含多个系统版本，例如家庭版、专业版。因此需要用 `--image-name` 指定要安装的系统版本（映像名称），不区分大小写

可以用 DISM、DISM++、Wimlib 等工具查询 ISO 包含的映像名称

#### 如何用 [DISM++](https://github.com/Chuyu-Team/Dism-Multi-language/releases) 查询 ISO 包含的映像名称

打开文件菜单 > 打开映像文件，选择要安装的 iso，即可得到映像名称，所有映像名称都可以安装

![image-name](https://github.com/bin456789/reinstall/assets/7548515/5aae0a9b-61e2-4f66-bb98-d470a6beaac2)

> [!WARNING]
> Vista、Server 2008 和 32 位系统可能会缺少驱动

> [!WARNING]
>
> 安装 Vista、7、Server 2008、Server 2008 R2 时
>
> 1. EFI 引导的机器要开启 CSM
>
> 2. Hyper-V / Azure 需选择第 1 代虚拟机

> [!WARNING]
>
> Windows 10 LTSC 2021 中文版镜像 `zh-cn_windows_10_enterprise_ltsc_2021_x64_dvd_033b7312.iso` 的 `wsappx` 进程会长期占用 CPU
>
> 解决方法是更新系统补丁，或者手动安装 `VCLibs` 库 <https://www.google.com/search?q=ltsc+wsappx>

> [!WARNING]
>
> 在 GCP 上安装 `2022年5月` 和之后发布的 Windows ISO，在引导 Windows 安装界面 (PE) 时会不断反复重启。解决方法如下，二选一
>
> 1. 添加 `--force-boot-mode bios` 参数，脚本将以 `BIOS 引导 + MBR 分区表` 方式安装 Windows
>
>    (可选) 安装完成后用 `MBR2GPT /convert /allowFullOS` 命令转为 `EFI 引导 + GPT 分区表`
>
> 2. 自制 RAW 镜像并通过 DD 安装

#### ARM 安装 Windows 的注意事项

大部分 ARM 云服务器支持安装 Windows 11

安装过程可能会黑屏，串行控制台可能会显示 `ConvertPages: failed to find range`，均不影响正常安装

| 兼容性 | 云服务商 | 实例类型                | 问题                                       |
| ------ | -------- | ----------------------- | ------------------------------------------ |
| ✔️     | Azure    | B2pts_v2                |                                            |
| ✔️     | AWS      | T4g                     |                                            |
| ✔️     | Scaleway | COPARM1                 |                                            |
| ✔️     | Gcore    |                         |                                            |
| ❔     | 阿里云   | g6r, c6r, g8y, c8y, r8y | 有几率重启时卡开机 Logo，强制重启即可      |
| ❔     | 甲骨文云 | A1.Flex                 | 不一定能安装成功，越新创建的实例越容易成功 |
| ❌     | 谷歌云   | t2a                     | 缺少网卡驱动                               |

### 取消重装

- 如果不小心运行了脚本，可以运行以下命令取消重装
- 需要在重启前运行

```bash
bash reinstall.sh reset
```

## 参数格式

### --ssh-key

- `--ssh-key "ssh-rsa ..."`
- `--ssh-key "ssh-ed25519 ..."`
- `--ssh-key "ecdsa-sha2-nistp256/384/521 ..."`
- `--ssh-key http://path/to/public_key`
- `--ssh-key github:your_username` 或 `--ssh-key gh:your_username`
- `--ssh-key gitlab:your_username` 或 `--ssh-key gl:your_username`
- `--ssh-key /path/to/public_key`
- `--ssh-key C:\path\to\public_key`

## 如何使用旧版本

根据 Bug 守恒定律，修复旧 Bug 的同时会引入新的 Bug

如果脚本出现问题，可以试下旧版本是否正常

从 <https://github.com/bin456789/reinstall/commits/main> 右侧找到旧版本的 `commit_id`

将下面脚本的 `xxxxxxxx` 替换成旧版本的 `commit_id` 并运行脚本

```bash
commit_id=xxxxxxxx
curl -O https://raw.githubusercontent.com/bin456789/reinstall/$commit_id/reinstall.sh || wget -O ${_##*/} $_
sed -i "/^confhome.*main$/s/main/$commit_id/" reinstall.sh
bash reinstall.sh ...
```

## 如何修改脚本自用

1. Fork 本仓库
2. 修改 `reinstall.sh` 和 `reinstall.bat` 开头的 `confhome` 和 `confhome_cn`
3. 修改其它代码
4. 下载并运行你的 `reinstall.sh` 或 `reinstall.bat`

## 本分支维护说明

本分支是在上游 `bin456789/reinstall` 基础上维护的个人修改。`main` 是上游基线，`kevin` 保留功能提交；2026-10-23 核对的基线为 `2252ca7615cd672dc1d9e67c52243db4ac859151`。在功能完整、行为正确的前提下，优先保持相对 `main` 的修改足够小，沿用上游入口和调用链，避免无关重构或格式调整。

以下按功能记录修改意图、执行逻辑、必要性和验证边界，各节随对应功能提交维护。同步上游后应重新核对这些依据；协作规则见 [AGENTS.md](AGENTS.md)。

### 脚本来源与版本一致性

对应提交：`chore(fork): use kevin reinstall source`。

**问题与意图。** 上游入口从 `bin456789/reinstall` 下载安装阶段脚本和资源。如果仅替换本地入口，后续仍下载上游资源，个人分支的功能就不能完整进入安装环境。此修改让入口与配套资源使用同一个个人维护来源。

**执行逻辑。** `reinstall.sh` 的 `confhome` 指向 `kevinhwang91/reinstall/main`，`confhome_cn` 复用该值；中英文 README 的 Linux 下载示例同步指向个人入口。继续使用上游已有的资源下载调用链，不逐个改写安装脚本的下载点，也不改动各发行版的系统镜像地址。

**为何保持这个范围。** 复用上游的来源变量比另建下载机制更小；国内来源统一是为了版本一致，不代表增加镜像加速。Windows 引导下载示例未在此功能中统一迁移，因此不能据此声称所有入口都已切换。`kevin` 是本地开发分支，而默认下载地址仍是个人仓库的 `main`；本地提交或 rebase 不会自动发布到该地址，测试未发布版本应使用匹配提交或受控资源来源。

**验证和维护依据。** 执行 `bash -n reinstall.sh`，并在本轮历史整理后比较重写前后的运行文件。同步上游时核对来源变量、`--commit` 处理和配套脚本版本校验仍一致；语法和差异检查不能证明公网资源已经发布或所有网络位置都能连接。

### 根设备和父磁盘识别

对应提交：`fix(core): resolve root disk from mountinfo`。

**问题与意图。** 上游从 `mount` 显示结果取根设备并交给 `lsblk`，但部分系统显示的 `/dev/root` 并不存在。修改仅补全挂载点到真实块设备的解析，不改变后续分区策略，也不猜测第一块磁盘。

**执行逻辑。** `reinstall.sh` 和独立的 `deprecated/resize.sh` 使用同样的两个小函数：

1. `get_mount_block_dev TARGET` 先从 `/proc/mounts` 取来源；路径存在时用 `readlink -f` 返回，保留普通设备、符号链接和 device-mapper 的成功路径。
2. 来源路径不存在时，从 `/proc/self/mountinfo` 读取该挂载点的 `major:minor`，再用 `lsblk -rpn -o NAME,MAJ:MIN` 对应到真实设备；找不到就失败。
3. `get_disks_by_block_dev DEV` 用 `lsblk --inverse` 沿父设备查找，按 `TYPE == disk` 取磁盘并去重。指定输出列，避免依赖默认表头或树形绘制。

主脚本的 `find_main_disk` 显式拒绝空结果，后续多磁盘处理沿用原流程；`get_disk_by_part` 也复用父磁盘查询。扩容脚本要求恰好一个父磁盘，零个或多个均退出，避免未经确定就操作磁盘。

**为何保留少量重复。** 旧版扩容脚本是独立入口，直接导入主脚本会触发其入口。保留两份小函数比新增运行时下载依赖更小；改算法时必须核对两份实现。SSH 快照接收复用 `get_mount_block_dev /`，此函数不能混入挂载、格式化或分区操作。

**边界与验证。** 回退要求挂载设备号能由 `lsblk` 对应到块设备，没有新增 overlay、网络根或任意复杂堆叠存储支持。本轮执行 `bash -n reinstall.sh deprecated/resize.sh` 并逐项比较重写前后的函数。现有接收测试使用设备路径替身，不能证明 `/dev/root` 的真实反查；当前没有针对该特殊挂载形式的新虚拟机验收。后续改动应验证有效路径、设备号回退、无结果和多个父磁盘四种情况。

### Arch 安装、子卷布局和默认值

对应提交：`feat(arch): install with btrfs and snapper`。

**相对上游的意图。** 上游通用分区使用 ext4，Arch 默认安装普通内核。这里为 Arch 建立可恢复的根子卷和独立快照历史，并保留用户指定的语言和 GRUB 等待时间；共享安装函数中的其他发行版保持原有默认值。

**分区与挂载逻辑。** `trans.sh` 的 `create_part` 保留 EFI、BIOS 大磁盘和普通 BIOS 三条分区路径，仅在 Arch 选择 Btrfs、安装工具并加载模块。三个格式化调用使用 `mkfs_linux_os_part`：Arch 格式化 Btrfs、短暂挂载顶层并创建 `@` 和 `@swap`；其他系统仍执行原来的 ext4 命令与选项。`mount_part_basic_layout` 将 Arch 的 `@` 挂载为目标根，选项为 `noatime,compress=zstd`，其他系统继续使用 ext4。

| 顶层子卷 | 挂载点 | 保留理由 |
| --- | --- | --- |
| `@` | `/` | 根快照恢复只替换这一子卷 |
| `@swap` | `/swap` | 交换文件位置独立于根快照 |
| `@snapshots` | `/.snapshots` | 快照历史不随旧根移动或删除 |

脚本提供 `/swap` 子卷和注释形式的交换文件条目，没有自动创建并启用 `/swap/swapfile`。

**安装顺序及必要性。** Arch 包选择为 `linux-lts btrfs-progs snapper`。安装包前创建普通目录 `/var/lib/portables` 和 `/var/lib/machines`，防止 systemd tmpfiles 的 `Q` 规则将它们建立为根快照不递归包含的额外子卷；依据包括 `portables.conf`、`systemd-nspawn.conf` 的规则和历史安装子卷检查。

在生成 `fstab` 前挂载 `@swap` 并调用 `setup_arch_snapper`。没有配置时，用 `snapper --no-dbus -c root create-config /` 创建 root 配置和初始 `.snapshots`，关闭 timeline timer。随后挂载 Btrfs 顶层，在同一挂载点内将 `@/.snapshots` 移为 `@snapshots`，再挂载到目标根的 `/.snapshots`。真实测试检出跨挂载点 `mv` 会变为普通目录复制，因此必须使用同一个顶层挂载点中的源和目标路径。

沿用上游 `genfstab`。原来的 `sed '/swap/d'` 会误删 `/swap` 和 `@swap` 的有效条目，因此改为只排除第三列类型为 `swap` 的条目。拆除生成器环境后显式卸载快照和交换子卷；没有引入全局失败清理 trap。

`set_locale` 只在 Arch 启用 `en_US.UTF-8` 并写入 `locale.conf`，Gentoo/AOSC 保留 `C.UTF-8` 原流程。生成 GRUB 配置前只在 Arch 设置 `GRUB_TIMEOUT=1`。这些条件是明确作用域，不能因为安装函数共享而提升为所有发行版的默认值。

**验证与维护依据。** `bash -n trans.sh` 检查语法；最终的 `bash tests/btrfs-layout.sh` 实际调用格式化和 Snapper 初始化函数，验证真实 Btrfs、`genfstab` 和快照创建。存储测试随后半段恢复功能一起提交，因为它依赖恢复函数。历史双虚拟机测试覆盖 x86_64 UEFI、LTS、语言和 GRUB 默认值，当时采用嵌套布局；新的顶层布局尚未重新完成整套虚拟机安装和启动，也没有新增 BIOS、ARM 实机覆盖。同步上游优先核对三个格式化调用点、Snapper 与 `genfstab` 的顺序和发行版条件。

### 可选的首次启动初始化

对应提交：`feat(linux): run optional user initialization on first boot`。

**问题与意图。** 新安装的 VPS 可能需要用户自定义初始化，但安装环境与目标系统的内核、网络和服务尚不相同。此功能让用户明确提供的 Bash 脚本在目标系统第一次正常启动时运行，不在安装阶段执行这些自定义操作。

**执行链路。** `reinstall.sh` 的 `--user-init-url` 仅接受 HTTP/HTTPS，准备阶段用 `curl -fL` 下载并设置 `600` 权限；生成 initrd 时将文件复制到 `/configs/user-init.sh`。这样首次启动使用的是已下载内容，不会在启动时重新获取 URL 的最新内容。

`trans.sh` 的 `basic_init` 调用 `add_user_init_systemd_service_if_need`：没有提供脚本、目标没有 systemctl 或 Bash 时直接返回，避免增加其他安装的副作用。有条件时选择目标的 `/usr/bin/bash` 或 `/bin/bash`，复制脚本到 `/usr/local/lib/reinstall-user-init.sh`、设置 `700` 权限，并在目标 chroot 中启用 oneshot 服务。

服务排列在 `network-online.target` 之后，以系统服务默认身份执行脚本。`ExecStart` 保存脚本退出码，随后禁用并删除服务和脚本、重新加载 systemd，最后返回原退出码。无论脚本成功还是失败均清理，因此这是一次执行，不是失败后自动重试；清理失败不会故意掩盖脚本本来的退出码。

**设计取舍。** 复用已有 URL 下载、initrd 配置打包和 `basic_init` 扩展点，避免增加另一套安装后入口。`network-online.target` 只是系统服务依赖，不保证外部站点一定可达；需要网络重试时由用户脚本明确实现。没有提供 URL 时不应生成此服务；不支持 systemd/Bash 的系统也不能被文档宣称拥有该功能。

**验证依据与边界。** 本轮执行 `bash -n reinstall.sh trans.sh` 并核对重写前后实现一致。历史双虚拟机安装验证过脚本写入标记后删除自身及服务，见既有验收记录；这不证明任意用户脚本的业务逻辑或失败重试可用。本轮没有重新启动虚拟机，也没有执行线上初始化脚本。后续维护须核对 `$$` 的 systemd 转义、退出码保留和目标 Bash 路径，避免修改成安装阶段执行或失败后无条件返回成功。

### 本地与远端快照恢复

对应提交：`feat(rollback): restore snapshots with current VPS networking`。该功能依赖前面的根设备识别，并与 Arch 安装共同约定顶层 `@`、`@swap`、`@snapshots`；后续的快照历史、旧根归档和一级远端路径修复归入同一功能提交。

**需求与入口。** 恢复应替换系统内容，同时保留目标 VPS 当前可用的网络、磁盘 UUID 和本机快照历史。主脚本新增 `rollback --snapshot latest|ID`、`--snapshot-path PATH`、`--ssh USER@HOST:/PATH` 及删除本次旧根的选项；继续复用上游 Alpine initrd 启动流程，不走清盘重装路径。参数互斥和快照有效性在设置恢复入口之前检查。

参数直接交给上游原有的 getopt 流程，远端来源使用正式的 `--ssh USER@HOST:/PATH`。不维护个人修改中的旧 `-ssh` 写法，因此删除额外的参数数组重建和转换循环；无效选项及缺失参数由已有解析器拒绝，无须再增加专门的拒绝分支。缺少 SSH 客户端时，复用 `install_pkg` 按包管理器映射客户端包名，避免为远端恢复另建一套依赖安装器。

**准备阶段。** `resolve_snapper_snapshot_path` 的 latest 只选择 `/.snapshots/数字/snapshot` 中编号最大的项，既不是按日期挑选，也不会把 `remote-*` 或 `rollback-backup-*` 当成 Snapper 历史。`get_btrfs_snapshot_info` 检查真实子卷并提取子卷 ID 和所在文件系统 UUID，`build_extra_cmdline` 将这两个身份写入启动参数；重启后按身份重新解析，避免依赖安装前的临时挂载路径。验证失败必须终止，不能生成一个缺失快照身份的安装入口。

**SSH 接收和一级路径。** `receive_ssh_btrfs_snapshot` 用根设备 helper 挂载目标磁盘顶层，验证已有 `@snapshots`；旧版仅有嵌套子卷时先使用原 `.snapshots`，不在运行系统中提前移动历史；两者都没有才新建存储子卷。远端路径经 shell 引号处理，SSH 命令会将指定来源子卷设置为只读，再用完整的 `btrfs send` 传输；当前没有使用增量发送父快照。

每次流先接收到独立隐藏临时目录，避免覆盖本机同名快照。成功后用 `btrfs subvolume snapshot -r` 在 `@snapshots/remote-原名-时间戳-进程号` 创建一级只读子卷，再删除临时接收子卷和空目录；创建或清理失败均停止准备。额外只读快照利用 Btrfs 共享数据块，不走普通文件复制。它拥有新的本地 UUID；本机实测只读属性和 `received_uuid` 保留，内容正确。不能直接跨父目录移动只读接收子卷：真实测试会返回 `Read-only file system`。这个步骤是一级路径与不覆盖现有数据同时成立所需的改动。

**网络适配为什么独立。** `rollback-network.sh` 同时供宿主 Bash、Alpine BusyBox ash 和首次启动使用；集中同一实现，避免三份网络迁移逻辑漂移。脚本版本标记与入口和 `trans.sh` 一致，以阻止明显不兼容的配套资源。准备阶段保存当前网络后端、唯一以太网上行的 MAC、接口名和配置文件到 initrd，不复制 DHCP 租约。

支持 networkd、Netplan、NetworkManager 的以太网配置和 ifupdown，但要求来源和目标使用同一后端及底层服务。归一化指纹忽略整行注释、空行和行尾空白，保留 YAML 缩进、配置顺序和符号链接目标。配置相同时跳过文件替换；有差异时将候选原配置归档，再复制目标 VPS 的配置，保留地址、路由、DNS、MTU、DHCP/SLAAC 和 MAC 绑定。仅在必要时阻止 cloud-init 再次覆盖网络；只对临时 chroot 缺失的 `/dev` 做局部绑定和卸载。

恢复前检查保存的 MAC 仍能识别，必要时生成 Netplan 配置，并在目标系统启用相应网络服务。首次启动服务在网络服务之前按保存的 MAC 校正接口名，以应对恢复环境与已安装系统命名不同。不同后端、多个上行、bridge/bond/VLAN 等复杂拓扑和不安全的链接目录会提前拒绝；这是当前适配能力的边界，不能通过猜测接口名绕过。

**离线恢复的状态与顺序。** Alpine 入口在正式分区安装之前调用 `rollback_btrfs_from_snapshot`：

1. 按文件系统 UUID 定位设备、挂载顶层，按子卷 ID 找到来源，创建可写候选 `@rollback-restore-*`。来源快照保留，准备过程不修改当前根。
2. 跨磁盘时替换候选 `fstab` 和已有引导配置中的根 UUID；EFI 不在根快照中，因此从目标当前 `fstab` 沿用相同 `/efi` 或 `/boot/efi` 挂载点的设备，避免引用来源机器的 EFI 分区。
3. 验证、准备或计划迁移本机快照子卷。候选有 Snapper root 配置时，拒绝符号链接或非空的 `.snapshots` 挂载目录，并将其 `fstab` 快照条目统一为目标 UUID 的 `subvol=/@snapshots`。新布局的本地快照通常已有正确条目；统一重写保留的是处理旧布局、重复条目和陈旧 `subvolid` 的单一路径，当前不会保留该挂载点的自定义选项。
4. 网络适配完成后才修改当前布局。旧嵌套 `.snapshots` 先整体移到顶层，再将旧 `@` 移到 `@snapshots/rollback-backup-*`，最后将候选改名为 `@`。先移子卷是为了避免把旧 `@` 移入自己的后代。
5. 旧根移动失败时，把已迁移的快照子卷放回原根；候选激活失败时，先将旧根移回 `@`，再将快照子卷放回嵌套位置。还原顺序不能倒置，否则会再次遇到父子关系冲突。网络准备失败时还没有移动旧根。
6. 默认保留旧根。`--rollback-delete-backup` 只在切换后删除本次旧根备份，不删除其他历史或远端快照，也不代表已验证恢复后的 SSH 可达性。成功后显式卸载顶层并重启；失败时记录日志、卸载并退出，不自动进入候选系统。

**持久数据与失败边界。** `@snapshots` 在根快照之外，回滚到早期系统仍保留后来创建的本机历史；`rollback-backup-*` 是直接移动的旧可写根子卷，`remote-*` 是只读来源，两者均没有注册成 Snapper 编号快照。旧版本留下的顶层备份、二级远端目录及更早备份中的嵌套历史不会被自动重排。候选创建后失败可能保留候选或接收产物用于检查；没有恢复已明确删除的全局自动清理方案。根快照中没有的较新文件也不会被网络适配补回，包括之后新增的出站 SSH 授权材料，应由用户在恢复后自行处理。

**验证论据。** `bash tests/rollback.sh` 有 30 个恢复场景，`bash tests/rollback-network.sh` 有 8 组，两者也使用 `TEST_BUSYBOX=/usr/lib/initcpio/busybox` 运行；覆盖失败前保留旧根、迁移与激活的撤销、EFI/根 UUID、已有历史、挂载条目以及四种网络后端。`bash tests/rollback-ssh.sh` 有 12 个接收场景，覆盖路径、重名、缺失结果、传输失败、只读快照创建和清理失败；另抽取实际 getopt 代码验证 `--ssh` 的参数顺序和带空格路径，以及拒绝 `-ssh` 和缺失来源参数。

`bash tests/btrfs-layout.sh` 使用真实 Btrfs、Snapper、send/receive 和 `fstab` 挂载，验证 4 组新布局接收、保留历史、本地删除策略和旧布局失败/成功迁移；SSH 传输由本地执行替代，不能当作真实 SSH 验收。详细证据见现有 [存储验收](tests/btrfs-layout.md)。[历史双虚拟机记录](tests/vm-acceptance.md) 覆盖旧布局的真实启动和 SSH；当前一级路径尚未重新进行虚拟机启动、真实 SSH、BIOS、ARM 或公网 VPS 验收。维护时应先确认失败发生在接收、候选准备还是切换阶段，再针对相应回归扩展测试，不能只凭成功日志判断系统可达。

## 感谢

感谢以下商家提供白嫖机器

[![Oracle Cloud](https://github.com/bin456789/reinstall/assets/7548515/8b430ed4-8344-4f96-b4da-c2bda031cc90)](https://www.oracle.com/cloud/)
[![DartNode](https://github.com/bin456789/reinstall/assets/7548515/435d6740-bcdd-4f3a-a196-2f60ae397f17)](https://dartnode.com/)

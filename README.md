# openwrt-build

本项目用于自动化构建 OpenWrt 固件，支持多设备配置和自定义脚本执行，方便实现路由器 IP 设置、宽带拨号、IPv6 配置等功能。

---

## 目录结构

- `configs/`  
  存放不同设备的配置文件。
- `scripts/`  
  存放自动化执行的脚本，建议以数字开头排序，控制执行顺序。
- `package.config`  
  存放第三方插件仓库地址。

---

## 路由器脚本执行顺序

首次启动时，系统会自动执行 `scripts/` 目录下的所有脚本。  
建议脚本命名以数字开头，按顺序执行，例如：

- `00-setup-system.sh`
- `01-setup-network.sh`
- `10-install-packages.sh`

脚本会按数字顺序依次执行，便于流程控制。

---

## 脚本环境变量设置

在 [`scripts/00-secrets.sh`](scripts/00-secrets.sh) 文件中设置变量，所有脚本均可引用。  
**注意：** 该文件内容会直接存储在固件中，请勿泄露隐私信息。

示例：

```sh
export LAN_IP="10.0.0.1"
export LAN_NETMASK="255.255.255.0"
export PPPOE_USERNAME="your_pppoe_username"
export PPPOE_PASSWORD="your_pppoe_password"
```

---

## 第三方包使用方法

只能使用一些简单的软件包，有一些软件会与官方冲突。
建议在配置阶段（make menuconfig）中，通过配置选择要编译的包，然后通过命令自行解决冲突  [`参考`](README-BUILD.md)

1. 在 [`package.config`](package.config) 文件中添加第三方仓库地址：

    ```
    feed https://github.com/kenzok8/openwrt-packages
    ```

2. 在设备配置文件（如 [`configs/x86_64_generic.config`](configs/.x86_64_generic.config)）中添加需要的第三方包：

   ```
   # your-plugin-name 是软件名称
   CONFIG_PACKAGE_your-plugin-name=y    # 编译进固件
   # 或
   CONFIG_PACKAGE_your-plugin-name=m    # 编译为独立 ipk 包
   ```

---

## 自动化构建流程说明

- 推送或 PR 触发自动化构建，支持多配置文件矩阵编译。
- 自动检测并添加第三方包，按需集成首次启动脚本。
- 构建产物自动上传并发布 Release，支持多设备固件下载。

详细流程见 [`openwrt-build.yml`](.github/workflows/openwrt-build.yml)。

---

## 贡献指南

欢迎提交 PR 或 issue，完善更多设备支持和自动化脚本。  
建议补充设备配置文件、优化脚本流程、丰富第三方包支持。

---

## License

本项目遵循 MIT License。
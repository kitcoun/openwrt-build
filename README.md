# openwrt-build

本项目用于自动化构建 OpenWrt 固件，并支持多种设备配置和自定义脚本执行。

路由器IP、自带拨号、IPV6设置

## 目录结构

- `configs/`  
  存放不同设备的配置文件，需遵循命名约定。
- `scripts/`  
  存放自动化执行的脚本，建议以数字开头排序。

## 配置文件命名约定

为了让自动化流程正常工作，配置文件需遵循如下命名规则：

```sh
configs/{target}_{subtarget}_{profile}.config
```

例如：

- `configs/x86_64_generic.config`
- `configs/ramips_mt7621_xiaomi_mir3g.config`

可以排除不需要的配置文件，文件前加上"-"

例如：

- `-configs/x86_64_generic.config`

## 路由器脚本执行顺序

首次启动时，系统会自动执行 `scripts/` 目录下的脚本。  
建议将脚本命名为数字开头，以控制执行顺序，例如：

- `00-setup-system`
- `10-setup-network`
- `20-install-packages`

脚本会按数字顺序依次执行。

## 脚本环境变量设置

在00-secrets.sh文件中设置变量可以所有的脚本使用,注意隐私,会直接存储在固件中,

## 贡献指南

欢迎提交 PR 或 issue，完善更多设备支持和自动化脚本。

## License

本项目遵循 MIT License。
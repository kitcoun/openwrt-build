# OpenWrt 固件编译流程说明

本指南介绍如何从源码编译 OpenWrt 固件，并集成第三方软件包。适用于新手和有一定经验的用户。

---

## 1. 获取源码

建议使用稳定版本，避免开发分支带来的不确定性。

```sh
git clone https://github.com/openwrt/openwrt.git openwrt-source
cd openwrt-source
git checkout v23.05.03
```

---

## 2. 添加第三方软件源

编辑 `feeds.conf.default`，在文件开头添加第三方源。例如：

```sh
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
```

如需添加多个源，可逐行添加。

---

## 3. 导入设备配置文件（可选）

如有预设配置文件，可直接覆盖：

```sh
cp ./configs/x86_64_generic.config .config
```

也可根据实际设备选择对应配置文件。

---

## 4. 更新并安装所有软件包索引

```sh
./scripts/feeds update -a
./scripts/feeds install -a
```

---

## 5. 处理冲突包 （可选）（建议提前）

实际情况总结如下：

| 冲突类型           | menuconfig 能否自动解决 | 说明                       |
|--------------------|:----------------------:|----------------------------|
| 同名包，不同源     | ✅ 通常能               | menuconfig 一般只显示一个版本 |
| 不同名包，相同功能 | ❌ 不能                | 需手动选择或预处理           |
| 文件安装冲突       | ❌ 不能                 | 编译时才会发现               |
| 依赖版本冲突       | ❌ 不能                 | 编译时才会发现               |
| 配置冲突           | ❌ 不能                 | 运行时才会发现               |

如遇冲突，可手动删除冲突包或调整配置。

---

## 6. 配置编译选项

使用图形化菜单配置所需设备和软件包：

```sh
make menuconfig
```

如已导入 `.config` 文件，可直接跳过此步，或根据需要微调。

---

## 7. 开始编译

建议使用多线程加速编译：

```sh
make -j$(($(nproc) + 1)) || make -j1 V=s
```

如遇编译错误，可使用单线程详细输出排查问题：

```sh
make -j1 V=s
```

---

## 8. 编译产物

编译完成后，固件及相关 ipk 包会生成在 `bin/targets/` 目录下。  
可根据设备型号查找对应固件文件。

---

## 9. 常见问题与建议

- **第三方包冲突**：优先选择官方源，第三方包如有冲突需手动排查。
- **依赖问题**：遇到依赖版本冲突时，可尝试更新 feeds 或调整依赖关系。
- **配置备份**：建议在每次 menuconfig 后备份 `.config` 文件，便于复现和排查问题。
- **空间不足**：如遇固件空间不足，可精简软件包或调整编译选项。
- **编译环境**：建议使用 Ubuntu 20.04/22.04，确保依赖齐全。

---

## 参考链接

- [OpenWrt 官方文档](https://openwrt.org/docs/start)
- [第三方包仓库](https://github.com/kenzok8/openwrt-packages)
- [常见问题解答](https://openwrt.org/faq)

---
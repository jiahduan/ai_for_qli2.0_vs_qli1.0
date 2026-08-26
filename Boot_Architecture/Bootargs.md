# Boot Architecture — Bootargs

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 典型cmdline来源 | ABL运行时动态拼接(perf构建`CONSOLE_PARAM`为空字符串) | 构建期固化(`esp-qcom-image.bb`的`UKI_CMDLINE`) |
| 示例cmdline | `noinitrd rootwait ... verity=enabled`(其他机型`qcs610-odk-64.conf`) | `root=PARTLABEL=rootfs rw rootwait console=ttyMSM0,115200` |
| root=语法 | 隐式依赖A/B slot运行时确定 | 显式静态`PARTLABEL=rootfs` |
| verity/AVB参数 | 广泛出现(`verity=enabled`) | 全树零命中 |
| console参数来源 | 各机型手写字符串,格式不统一 | 标准变量`SERIAL_CONSOLES`/`KERNEL_CONSOLE`推导 |
| 额外追加机制 | 无统一机制 | `KERNEL_CMDLINE_EXTRA`(如RT内核追加isolcpus等,详见System_Architecture/RT.md) |

## 关键差异

- verity参数消失与dm-verity整套8个bbclass在QLI2.0完全消失相互印证(详见Code_Composition/Patch_Management.md关于`fstab-generator-Honor-verity-enabled-cmdline.patch`的追踪)。
- 与Boot_Architecture/Partition_Layout.md(Android安全HAL分区消失)、Boot_Architecture/systemd_.md三方证据一致。

## 影响与风险

- 若后续要为某产品线补齐dm-verity/安全启动,cmdline注入点和对应systemd逻辑均需重新设计。
- QLI1.0运行时动态cmdline意味着仅看Yocto仓库无法还原设备实际生效的完整`/proc/cmdline`。

## 待确认

- QLI2.0根文件系统完整性校验替代方案(纯ext4无校验?还是fs-verity逐文件校验?)。
- 建议实机抓取pebble的`/proc/cmdline`补全ABL运行时注入部分。

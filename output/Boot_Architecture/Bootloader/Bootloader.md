# Boot Architecture — Bootloader

## 对比范围

- **覆盖**:
  - 主Bootloader二进制身份与来源可追溯性(ABL/EDK2,`SRC_URI=file://edk2`本地打包无公开版本号 vs u-boot-qcom,`git://github.com/qualcomm-linux/u-boot.git`固定commit`PV="2026.04+2026.07-rc2+git"`/`SRCREV="5a77d4670d8084ada24a2735dda75788ed5ce925"`)
  - 签名机制(QLI1.0`SIGNING_FUNCTION="sectoolv2_sign_abl"`/`QSIGN_TARGET="pebble"`私有工具链,`qsigning.bbclass`硬编码`--signing-mode TEST`;QLI2.0`qtestsign`社区维护测试签名工具,`SRC_URI="git://github.com/msm8916-mainline/qtestsign.git"`)及两侧均止步于测试签名、量产签名靠`sectools`自带但不随BSP分发的`PLUGIN`扩展点这一结论
  - 板级配置机制(vendor DT/soc-repo定制 vs `UBOOT_CONFIG[iq-9075-evk]="qcom_lemans_defconfig"`标准u-boot defconfig)
  - EFI二级引导层存在与否(无独立第二引导层 vs systemd-boot)
  - 开放固件变体路线(`iq-9075-evk-open-fw.conf`双轨制及其与默认闭源固件路径的关系)
- **明确排除**:
  - u-boot在启动链中实际是否参与打包/何时生效(默认闭源固件路径下u-boot完全不参与启动的判定)、二级引导systemd-boot的角色定位 ——见[Boot_Flow](../Boot_Flow/Boot_Flow.md)
  - cmdline内容本身(签名/板级配置只覆盖到"谁引导""如何签名",不含cmdline取值) ——见[Bootargs](../Bootargs/Bootargs.md)
  - Android安全HAL分区、AVB/dm-verity完整性校验替代方案 ——见[Bootargs](../Bootargs/Bootargs.md)、[Partition_Layout](../Partition_Layout/Partition_Layout.md)
- **待定边界**:(无,已核实本文全部锚点——`u-boot-qcom_git.bb`的PV/SRCREV、`qcom-u-boot-common.inc`第13行、`qtestsign_git.bb`的SRC_URI、`qsigning.bbclass`的`--signing-mode`取值、`sectools`示例文件——均在QLI1.0/QLI2.0源码树内复核无误,未发现证据链不足或遗漏目录)

## 对比总览

| 维度 | QLI1.0(pebble) | QLI2.0(iq-9075-evk) |
|---|---|---|
| 主Bootloader | ABL(基于EDK2) | u-boot-qcom(基于上游u-boot) |
| 来源 | `SRC_URI=file://edk2`(随vendor代码树本地打包,无公开版本号/tag) | `git://github.com/qualcomm-linux/u-boot.git`,`PV="2026.04+2026.07-rc2+git"`,`SRCREV="5a77d4670d8084ada24a2735dda75788ed5ce925"`固定commit(`meta-qcom/recipes-bsp/u-boot/u-boot-qcom_git.bb`) |
| 签名 | `SIGNING_FUNCTION="sectoolv2_sign_abl"`,`QSIGN_TARGET="pebble"`(QTI私有签名工具链) | `qtestsign`(见`u-boot-qcom_git.bb`的`uboot_compile_config`,使用`-${config_mbn_header}`如v5/v6) |
| 板级配置 | 编译期通过vendor DT/soc-repo定制 | `UBOOT_CONFIG[iq-9075-evk]="qcom_lemans_defconfig"`(`meta-qcom/conf/machine/include/qcom-u-boot-common.inc`第13行),标准u-boot defconfig机制 |
| EFI二级引导 | 无独立第二引导层(ABL本身即UEFI shell) | systemd-boot |
| 开放固件变体 | 未发现对应机制 | `iq-9075-evk-open-fw.conf`显式`PREFERRED_PROVIDER_virtual/bootloader = "u-boot-qcom"` + `trusted-firmware-a-qcom`,存在"闭源固件"与"开放固件(TF-A+开源u-boot)"两条并行路线 |

## 关键差异

- 闭源专有vs开源社区维护:ABL/EDK2源码以`file://`本地打包方式引入,无法在本仓库外部追溯版本历史;u-boot-qcom直接指向公开GitHub仓库固定commit,版本可追溯、可复现、可提PR上游。
- QLI2.0的"开放固件"不是把闭源路径整体替换掉,而是叠加了一条新分支:默认`iq-9075-evk.conf`仍然是闭源固件路径(u-boot完全不参与启动,见Boot_Flow.md),只有显式切到`iq-9075-evk-open-fw.conf`才走开源u-boot。也就是说"Bootloader开源化"目前是可选项而非默认行为,QLI1.0侧没有对应的"可选开放路线"概念,这也意味着两条路线要各自维护一套defconfig/固件依赖/CI覆盖,不是一次性切换的简单收益。
- 签名机制表面不同(`sectoolv2_sign_abl`私有工具 vs `qtestsign`+MBN header v5/v6),但实质上两侧都只做到测试签名:QLI1.0的Yocto recipe硬编码`--signing-mode TEST`,量产签名靠sectools自带但不随BSP分发的`PLUGIN`扩展点对接HSM(见下方影响与风险的详细证据);QLI2.0则连这层TEST模式调用都没有,直接用社区维护的`qtestsign`开发签名。即无论闭源还是开源路线,本仓库范围内都看不到量产签名链路,只是QLI1.0至少有"如何接量产签名"的样板,QLI2.0目前没有对应样板。

## 影响与风险

- 切换到开源u-boot降低了对QTI专有工具链(sectool)的强依赖,有利于第三方/社区二次开发;`qtestsign`已确认是`msm8916-mainline`社区维护的测试签名工具(`meta-qcom/recipes-devtools/qtestsign/qtestsign_git.bb`,`SRC_URI="git://github.com/msm8916-mainline/qtestsign.git"`),不是QTI官方量产签名基础设施。
- 双轨制(闭源固件/开放固件)增加了BSP维护矩阵(两套defconfig、两套固件依赖),需要评估CI是否覆盖两条路径。
- 量产签名接入点已找到技术形态但不在本仓库范围内:QLI1.0侧真正的`sectools`二进制(`src/vendor/qcom/proprietary/sectools`)自带`public/example/plugin_signer_example.py`等示例,注释明确写着这是`--signing-mode PLUGIN`模式的实现样板——OEM实现自己的`sign()`函数对接HSM,`example_resources/README.md`原话:"In production, the private key should be OEM-generated and should never be present in source code or a non-secure environment. Ideally it should be secured by an HSM."即使是QLI1.0这套更接近量产的BSP,Yocto recipe(`qsigning.bbclass`里`sectoolv2_sign_abl`、`do_compose_vmimage`)里实际调用sectools时硬编码的也是`--signing-mode TEST`,量产HSM接入靠的是sectools自带但不随BSP分发的`--signing-mode PLUGIN`扩展点,而不是Yocto recipe本身。QLI2.0的`meta-qcom`里连这层TEST模式sectools调用都没有,全部是`qtestsign`开发签名,验证了"两侧仓库都只到测试签名,量产签名靠外部PLUGIN机制"这一结论。

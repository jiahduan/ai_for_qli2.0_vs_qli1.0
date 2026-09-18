# Boot Architecture — Partition Layout

> 说明:downstream(maili)默认样例构建目标为`pebble`(手机/平板类SoC,Android血统浓厚),QLI2.0默认目标为`iq-9075-evk`(基于QCS9100的机器人开发板)。下文差异既包含架构选型因素,也包含目标硬件世代/产品形态不同的因素。

## 对比范围

- **覆盖**:
  - 分区总数对比,以实际构建产物计数(downstream(maili):`build-qti-distro-camerastack-debug/tmp-glibc/deploy/images/pebble/qti-multimedia-image/rawprogram[0-9].xml`按`label=`去重,已重新计数复核仍为156个;QLI2.0:`build/tmp/deploy/images/iq-9075-evk/partitions/iq-9075-evk/ufs/rawprogram[0-9].xml`同法复核仍为66个,与本文已记录的67→66纠错一致)
  - 上游`qcom-ptool`源码`partitions.conf`条目数与实际构建产物分区数的差异说明(已在`build/downloads/git2/github.com.qualcomm-linux.qcom-ptool.git`重新核对:`platforms/iq-9075-evk/ufs/partitions.conf`72个`--partition`、`platforms/qrb5165-rb5/ufs/partitions.conf`77个,均与本文数字一致)
  - 同芯片(qrb5165-rb5)剥离机型因素后的对比基准(downstream(maili)`poky/meta-qti-bsp/conf/machine/partition/qrb5165-rb5-partition.conf`已复核仍为90个`--partition`条目)
  - 底层固件A/B分区(`xbl_a/b`/`tz_a/b`/`hyp_a/b`/`aop_a/b`/`uefi_a/b`)、OS层A/B分区存续情况、Android安全HAL分区族(keystore/secretkeeper/hwcrypto等)去向、新增分区(gearvm_a/b等)
  - A/B槎位管理组件对比(downstream(maili)`libabctl.cpp`命令行能力;QLI2.0`qbootctl`开源等价物及其在`rb1-core-kit.conf`的挂载方式,已复核`MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS += "qbootctl"`仍存在)
  - xbl_a/b等低层固件槎位fallback行为的排查过程(`trusted-firmware-a-qcom`/`meta-qcom*`范围`BOOT_ROM`关键字复核仍零命中;u-boot上游`doc/board/qualcomm/rdp.rst`作为旁证的适用范围说明)
- **明确排除**:
  - dm-verity/AVB完整性校验机制本身(cmdline verity参数、8个dm-verity相关bbclass的消失取证) ——见[Bootargs](../Bootargs/Bootargs.md)
  - meta-updater/OSTree原子部署的具体运作机制与安全性评审(本文仅点出DISTRO变体切换即可启用,不深挖) ——见[OTA_Mechanism](../../Platform_Features/OTA_Mechanism/OTA_Mechanism.md)
  - 启动链阶段划分、UKI签名机制 ——见[Boot_Flow](../Boot_Flow/Boot_Flow.md)
- **待定边界**:
  - iq-9075-evk(QCS9100)的PBL/ROM级fallback机制是否与`rdp.rst`描述的watchdog+bank切换+EDL兜底模型逐字一致——需向QCT固件团队确认,已在下文"待确认"节跟踪,暂不同步进README(尚未构成跨文档判断依赖)

## 对比总览

| 维度 | downstream(maili)(pebble) | QLI2.0(iq-9075-evk) |
|---|---|---|
| 分区总数 | 156个(来自实际构建产物`tmp-glibc/deploy/images/pebble/qti-multimedia-image/rawprogram[0-9].xml`,对`label=`去重计数,QFIL/Firehose格式) | 66个(**初步判断67个,核实后更正为66个**——来自实际构建产物`build/tmp/deploy/images/iq-9075-evk/partitions/iq-9075-evk/ufs/rawprogram[0-9].xml`,同样对`label=`去重计数;与上游`qcom-ptool`源码`platforms/iq-9075-evk/ufs/partitions.conf`里72个`--partition`条目不完全一致,原因是source配置里部分条目对应GPT/backup/占位段而非实际下发的独立分区,以实际构建产物计数为准) |
| 底层固件A/B | `xbl_a/b`、`tz_a/b`、`hyp_a/b`、`aop_a/b`、`uefi_a/b`(SoC启动ROM强制要求) | 同样保留:`xbl_a/b`、`tz_a/b`、`hyp_a/b`、`aop_a/b`、`uefi_a/b` |
| OS层A/B分区 | `boot_a/b`、`dtbo_a/b`、`system_a/b`、`userdata`,证实标准Android A/B seamless-update模型(`src/bootctrl/abctl/libabctl.cpp`硬编码`/dev/disk/by-partlabel/xbl_a`等,解析`/proc/cmdline`中`SLOT_SUFFIX`) | 无,单一`rootfs`分区(无_a/_b) |
| Android安全HAL分区 | `keystore`、`secretkeeper_a/b`、`securestorage_a/b`、`authmgr_a/b`、`hwcrypto_a/b`、`spuservice_a/b`、`frp`、`misc`、`android_esp_a/b`、`hibernation` | 均不存在,仅保留`keymaster_a/b`、`persist`、`secdata`、`softsku`、`splash`、`efi` |
| MACHINE_FEATURES标志 | `pebble.conf`: `MACHINE_FEATURES += "qti-ab-boot"` | 不适用 |
| 新增分区 | 无 | `gearvm_a/b`(与meta-virtualization呼应,提示存在Guest VM/hypervisor场景)、`recoveryinfo`、`SYSFW_VERSION`、`diag_log/gvm_log/pvm_log`(调试/日志类) |
| A/B管理组件 | `src/bootctrl/abctl`: `libabctl.cpp`提供`--set_active`、`--boot_slot`、`--set_success`、`--set_unbootable`、`--set_priority`等命令 | iq-9075-evk无对应组件(单一rootfs不需要);但meta-qcom上游已收录开源等价物`qbootctl`(`recipes-support/qbootctl/qbootctl_git.bb`,`github.com/linux-msm/qbootctl`,自述为"Qualcomm Android bootctrl HAL的musl/glibc移植"),通过`qbootctl-bless-boot.service`调用`qbootctl -m`标记当前槽位启动成功,已挂载给`rb1-core-kit.conf`等仍走ABL/Android式boot_a/b的机型(`MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS += "qbootctl"`,注释明确"boot firmware will switch to slot B and fail to boot otherwise") |

## 关键差异

- 分区精简的实质是两件相互独立的事叠在一起,不能混为一谈:一是产品形态从Android血统的手机SoC(pebble)换成了单rootfs的机器人开发板(iq-9075-evk),这部分是"选了另一种分区哲学"而非架构统一进步——剥离机型因素后同芯片对比(均为`qrb5165-rb5`)是90 vs 77(downstream(maili)`poky/meta-qti-bsp/conf/machine/partition/qrb5165-rb5-partition.conf`90个`--partition`条目;QLI2.0外部仓库`qcom-ptool`的`platforms/qrb5165-rb5/ufs/partitions.conf`77个条目,同样是Android式A/B布局,xbl_a/tz_a/hyp_a/aop_a/abl_a/boot_a/boot_b/keymaster_a/dtbo_a/vbmeta_a俱全),说明"QLI2.0"本身并不必然抹掉Android式分区。二是iq-9075-evk这个具体机型选择放弃了Android安全HAL分区族(keystore/secretkeeper/hwcrypto等)和OS层A/B,这才是真正的能力/架构差异。把这两件事分开看,"156→66"这个数字本身不能直接读成"QLI2.0比downstream(maili)精简了58%的安全/管理能力",顶多能读成"iq-9075-evk这个产品形态没有带上这些能力",能否补回来要看是否愿意挂载`qrb5165-rb5`那条Android兼容路线。
- OS层A/B消失和Android安全HAL分区消失虽然是表里两件事(前者是升级模型,后者是安全能力),但根源是同一个:iq-9075-evk走的是"单rootfs+meta-updater"这条新的OTA/安全模型,而不是延续Android AVB/Keystore那条体系。这意味着安全团队不能只关注"哪些分区没了",而要判断meta-updater/OSTree这条新路线整体上能否覆盖原来AVB+Keystore组合要解决的问题(镶像完整性+密钥硬件隔离),目前看两者都没有对应替代(详见Bootargs.md的dm-verity/AVB结论),即分区精简和安全能力缺失是同一次架构选择的两个可观察侧面,而非两个独立风险。

## 影响与风险

- 去掉userdata/system_a/b意味着OTA升级模型从"整分区A/B切换"转向依赖meta-updater(OSTree/aktualizr)的"单分区内原子部署"(详见output/Platform_Features/OTA_Mechanism/OTA_Mechanism.md),升级失败回滚机制完全不同,需重新评估回滚可靠性(单分区模型下若rootfs写坏,没有物理备用分区可切回)。当前默认`build/conf/local.conf`选的`DISTRO ??= "qcom-robotics-ros2-jazzy"`未启用sota,镶出来是普通ext4镜像,但meta-updater/OSTree机制已经在`qcom-distro-sota.inc`接线完毕,直接把`DISTRO`换成`qcom-robotics-distro-sota`或`qcom-robotics-distro-catchall`即可切换到OSTree部署树,并非能力缺失,只是构建时选的DISTRO变体不同。
- 去掉Android安全分区意味着依赖这些分区的安全服务(硬件密钥库、防重放计数器)在QLI2.0需要重新实现或改为软件方案,需确认替代方案。

## 待确认

- **xbl_a/b等低层固件槽位的A/B fallback行为**——用户态工具链问题已解决:meta-qcom上游本身收录了`qbootctl`(bootctrl HAL的开源musl/glibc移植,详见上表A/B管理组件行),iq-9075-evk若未来需要OS层A/B,直接挂载即可,当前不挂载只是因为单一rootfs不需要OS层槽位管理。xbl_a/b这层本身(SoC PBL/ROM bootloader固件)的fallback逻辑在`meta-qcom*`/`trusted-firmware-a-qcom`里确认零命中(PBL早于TF-A运行,TF-A源码里的`BOOT_ROM`只是XPU内存保护区域命名,与A/B切换无关);但在`u-boot-qcom`实际拉取的上游仓库(`git://github.com/qualcomm-linux/u-boot.git`)里找到一段非正式但明确的描述——`doc/board/qualcomm/rdp.rst`(IPQ9574/RDP机型,同一上游树,非iq-9075-evk专属但同属Qualcomm固件家族的通用行为模式):"Boards with newer software versions would automatically go the emergency download (EDL) mode if U-Boot is not functioning as expected. If its a runtime failure at Uboot, the system will get reset (due to watchdog) and XBL will try to boot from next bank and if Bank B also doesn't have a functional image and is not booting fine, then the system will enter EDL."即:watchdog复位触发XBL切到另一个bank重试,双bank都失败则进入EDL(紧急下载模式)兜底,这是目前源码层面能找到的最接近的xbl级fallback行为描述,但仅是IPQ系列文档里的个例说明,不能确认在QCS9100/iq-9075-evk上是否逐字适用,严格意义上的PBL/ROM级fallback机制仍未在QCS9100专属文档里见到。剩余缺口:向QCT固件团队确认iq-9075-evk(QCS9100)的PBL是否与该文档描述的watchdog+bank切换+EDL兜底模型一致。

# Boot Architecture — systemd

## 对比范围

- **覆盖**:
  - systemd版本本身(255.21,`systemd_255.21.bb`源`git://github.com/systemd/systemd-stable.git`branch`v255-stable` vs 259.5,`systemd_259.5.bb`源主线仓库tag`v259.5`,已复核SRC_URI/版本号一致)
  - vendor层.service定制数量与分布(QLI1.0125个,meta-qti-*系列;QLI2.0约7个,已复核meta-qcom*仅`format-tee-partition.service`1个、meta-updater层`aktualizr*`等6个)
  - 定制补丁数量与性质(QLI1.0三个功能特性接入补丁;QLI2.0一个UEFI/UKI加载器底层修复补丁,已复核`0001-boot-stub-honor-PE-SectionAlignment...patch`仍存在)
  - 三个QLI1.0补丁(`Disable-unused-mount-points.patch`/`fstab-generator-Honor-verity-enabled-cmdline.patch`/`sd-bus-Allow-extra-users-to-communicate.patch`)在QLI2.0的具体吸收/消失判定过程,含`securityfs`/`verity=enabled`、`arg_usr_verity`/`sender_uid == 1001`在实际参与构建层范围内的检索(均已复核仍为零命中,`meta-integrity`未被`build/conf/bblayers.conf`收录的判定同样复核有效)
  - 两侧systemd对应NEWS文件逐行diff及与本BSP启动路径直接相关的筛选结论(ProtectSystem/initrd写权限、TPM 1.2 PCR measurement移除、gpt-auto-generator新语义、journal默认持久化存储)
- **明确排除**:
  - UKI secure boot签名机制本身的取证与权威结论(`UKI_SB_KEY`/`UKI_SB_CERT`/`sbsign`零命中判定)——尽管本文讨论TPM/measured-boot相关NEWS变化,该结论的权威归属不在本文 ——见[Boot_Flow](../Boot_Flow/Boot_Flow.md)
  - cmdline是否含verity/AVB参数的检索结论本身(本文仅引用该零命中结果作为fstab-generator补丁"功能不再需要"判定的交叉印证,不重复取证) ——见[Bootargs](../Bootargs/Bootargs.md)
  - Android安全HAL分区消失清单 ——见[Partition_Layout](../Partition_Layout/Partition_Layout.md)
  - aktualizr等meta-updater服务的OTA机制细节(证书管理/更新服务器信任链) ——见[OTA_Mechanism](../../Platform_Features/OTA_Mechanism/OTA_Mechanism.md)
- **待定边界**:(无,已核实本文dm-verity补丁消失结论与Bootargs.md/Partition_Layout.md的三方证据链、以及UKI签名结论与Boot_Flow.md/Bootargs.md的二方证据链均已明确划清归属,不存在三篇互相打架或都遗漏的情况)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| systemd版本 | 255.21(`systemd_255.21.bb`,源`git://github.com/systemd/systemd-stable.git` branch `v255-stable`,SRCREV`70500d37`即tag`v255.21`本身) | 259.5(`systemd_259.5.bb`,源`git://github.com/systemd/systemd.git`主线仓库tag`v259.5`,同步升级systemd-boot等) |
| vendor层.service数量 | 125个,meta-qti-*系列:meta-qti-bsp 41、meta-qti-wlan(-prop) 16、meta-qti-security-prop 9、meta-qti-eva 6、meta-qti-display(-prop) 5等,覆盖WLAN、安全、显示、相机、EVA、蓝牙几乎所有硬件子系统 | 约7个,meta-qcom*系列仅1个(`format-tee-partition.service`);meta-updater层6个(`aktualizr.service`、`aktualizr-secondary.service`、`aktualizr-serialcan.service`、`slcand@.service`、`createtoken.service`、`clean-connman-symlink.service`) |
| 定制补丁数量/性质 | 3个,偏"功能特性接入":`Disable-unused-mount-points.patch`(禁用securityfs自动挂载)、`fstab-generator-Honor-verity-enabled-cmdline.patch`(dm-verity cmdline支持)、`sd-bus-Allow-extra-users-to-communicate.patch`(D-Bus特权uid放行) | 1个,偏"UEFI/UKI加载器底层修复":`0001-boot-stub-honor-PE-SectionAlignment-when-loading-inn...patch`(与`FIT_DTB_MKIMAGE_EXTRA_OPTS ?= "-E -B 8"`的UEFI 8字节对齐要求呼应) |

## systemd补丁去向追踪

| QLI1.0补丁 | 具体改动 | QLI2.0对应情况 | 吸收方式判定 |
|---|---|---|---|
| `Disable-unused-mount-points.patch` | 修改`src/shared/mount-setup.c`,把securityfs(`/sys/kernel/security`)挂载点整段注释掉 | 无对应,securityfs相关源码改动零命中 | 功能不再需要——已确认QLI2.0当前构建里没有任何功能依赖securityfs:实际参与构建的layer(`meta-security`本体、`meta-security/meta-tpm`、`meta-qcom*`、`oe-core/meta`)全仓检索`securityfs`零命中,唯一有命中的`meta-integrity`(IMA appraisal)根本没被收录进`build/conf/bblayers.conf`;`DISTRO_FEATURES`也从未追加`ima`/`smack`/`apparmor` |
| `fstab-generator-Honor-verity-enabled-cmdline.patch` | 修改`src/fstab-generator/fstab-generator.c`,识别`verity=enabled`/`avb-verity`,强制用`/dev/mapper/root`作根设备 | 全局检索`verity=enabled`、`arg_usr_verity`零匹配 | 功能不再需要——QLI1.0整套dm-verity/AVB镶像校验子系统(8个bbclass)在QLI2.0确认完全消失,详见Bootargs.md |
| `sd-bus-Allow-extra-users-to-communicate.patch` | 修改`src/libsystemd/sd-bus/bus-convenience.c`的`sd_bus_query_sender_privilege()`,硬编码放行uid 1000/1001(QTI私有radio等特权用户) | 全局检索`sender_uid == 1001`零匹配 | 功能不再需要——服务于QLI1.0特定Android风格uid体系,QLI2.0全树无该私有uid体系痕迹 |

## 关键差异

- Unit定制量断崖式下降(125→~7):更可能是层的成熟度/覆盖范围不同(meta-qcom目前主打开源机器人SDK,尚未包含QLI1.0那些垂直子系统)而非"精简架构"的结果。
- QLI2.0新增unit全部与meta-updater(aktualizr/OTA)相关,是QLI1.0完全没有的能力域。
- dm-verity相关补丁消失与Bootargs.md(cmdline无verity参数)、Partition_Layout.md(Android安全分区消失)三方互相印证,构成一致的证据链。

## 影响与风险

- 已对两侧SRCREV对应的确切NEWS文件(QLI1.0=systemd-stable仓库`v255.21`,QLI2.0=systemd主线仓库`v259.5`)做逐行diff,新增约4117行,与本BSP启动路径直接相关的确认变化:①v256引入系统级`ProtectSystem=`,在initrd中默认启用,initrd阶段代码默认不能直接写`/usr`,需要回归测试当前initrd/UKI内嵌逻辑是否有相关写操作;②v256起`systemd-stub`移除TPM 1.2 PCR measurement支持(v259起systemd-boot/systemd-stub完全去除TPM 1.2),iq-9075-evk的`MACHINE_FEATURES`含`tpm2`(`meta-qcom/conf/machine/iq-9075-evk.conf`),用的是TPM2而非TPM1.2,该项变化不影响现状;③v258起`systemd-gpt-auto-generator`新增`root=dissect`/`root=bind:`语义,但QLI2.0走的是`esp-qcom-image.bb`里`UKI_CMDLINE`静态`root=PARTLABEL=rootfs`,不经过gpt-auto-generator路径,不适用;④v259起journal默认存储模式由`auto`改为`persistent`,`meta-qcom*`未检索到任何`journald.conf`级`Storage=`覆盖,意味着升级后`/var/log/journal`会默认持久化落盘,需确认是否符合当前存储/日志策略预期。其余增量多为systemd-boot多profile UKI、ukify签名选项、Varlink IPC扩展等特性,与本BSP当前用法(单profile UKI、无dm-verity/TPM measured-boot)无直接交集。此外确认两侧`systemd/`补丁目录均只是OE通用适配补丁(musl兼容、install路径等),没有meta-qti-bsp/meta-qcom的私有改动。
- 125→7的巨大落差意味着如果QLI2.0未来要承接QLI1.0那些硬件子系统(WLAN/相机/安全等)的服务化管理,需要重新设计对应unit,不能假设可以直接照搬(基础systemd版本、启动模型、分区布局都变了)。
- `aktualizr*.service`引入意味着新的攻击面/运维面(网络更新客户端常驻服务),需要安全评审是否已覆盖(证书管理、更新服务器信任链等)。

# Boot Architecture — Boot Flow

## 对比范围

- **覆盖**:
  - 启动链各阶段角色对比:PBL→XBL/SBL→TZ/HYP(双侧相同)、主Bootloader身份(ABL/EDK2,`abl-squashfs.bb` require `edk2_git.bb` vs u-boot-qcom,`meta-qcom/recipes-bsp/u-boot/u-boot-qcom_git.bb`SRCREV`5a77d4670d8084ada24a2735dda75788ed5ce925`,`meta-qcom/conf/machine/include/qcom-u-boot-common.inc`第13行`UBOOT_CONFIG[iq-9075-evk]`)、二级引导层是否存在(无 vs systemd-boot,`meta-qcom/conf/machine/include/qcom-common.inc`第63行`EFI_PROVIDER ?= "systemd-boot"`)
  - 内核镜像封装格式(Android boot.img,`mkbootimg`/`BOOT_HEADER_VERSION="2"` vs UKI,`esp-qcom-image.bb`的`inherit uki uki-esp-image`)
  - cmdline的生成时机与所在启动阶段(ABL运行时动态拼接 vs 构建期静态烘焙进UKI这一机制本身,证据为`esp-qcom-image.bb`的`UKI_CMDLINE`变量存在;不含逐机型/逐参数的取值明细)
  - UKI secure boot签名机制取证——本条是与Bootargs.md共享的证据链的权威归属方:`oe-core/meta/classes-recipe/uki.bbclass`第85-87行`UKI_SB_KEY`/`UKI_SB_CERT`签名钩子定义,及在`meta-qcom*`/`meta-security*`/`meta-updater`/`build/conf`范围内对这两个变量及`sbsign`的全局检索结果(零命中,已复核仍为零命中);Bootargs.md仅引用本文的这一结论,不重复取证
  - initramfs/ramdisk机制的存续方式(Android式vendor_boot/ramdisk概念 vs `meta-qcom-distro/conf/distro/include/qcom-base.inc`第56行`INITRAMFS_IMAGE = "initramfs-rootfs-image"`内嵌进UKI的pivot-to-rootfs机制)
  - root挂载依据的执行主体(ABL运行时拼接+用户态`abctl`读取`/proc/cmdline` vs systemd PID1挂载`PARTLABEL=rootfs`)
- **明确排除**:
  - cmdline具体参数内容/逐机型取值(perf构建字符串本身、verity/AVB相关参数检索、`KERNEL_CMDLINE_EXTRA`逐机型追加项、console参数规范化) ——见[Bootargs](../Bootargs/Bootargs.md)
  - Bootloader自身的来源可追溯性、签名机制(sectoolv2/qtestsign)、板级defconfig矩阵、开放固件变体细节 ——见[Bootloader](../Bootloader/Bootloader.md)
  - Android安全HAL分区消失清单、分区总数对比 ——见[Partition_Layout](../Partition_Layout/Partition_Layout.md)
  - dm-verity/AVB完整性校验替代方案的产品级结论 ——见[Bootargs](../Bootargs/Bootargs.md)
  - OTA/Recovery触发路径与升级失败回滚SOP ——见[OTA_Mechanism](../../Platform_Features/OTA_Mechanism/OTA_Mechanism.md)
- **待定边界**:(无,已核实本文列出的6个锚点均在QLI2.0`/local/mnt/workspace/jiahduan/qli2.0/0817`源码树内重新检索确认,含`UKI_SB_KEY`/`UKI_SB_CERT`/`sbsign`零命中复核;与Bootargs.md的UKI签名结论归属已明确划清,不存在悬空指向)

## 对比总览

| 阶段 | downstream(maili) | QLI2.0 |
|---|---|---|
| PBL→XBL/SBL→TZ/HYP | 相同 | 相同 |
| 主Bootloader | ABL(基于EDK2定制,`abl-squashfs.bb` require `edk2_git.bb`) | UEFI(仍保留uefi_a/b分区)→u-boot(`u-boot-qcom_git.bb`,SRCREV`5a77d4670d8084ada24a2735dda75788ed5ce925`,`meta-qcom/conf/machine/include/qcom-u-boot-common.inc`第13行`UBOOT_CONFIG[iq-9075-evk]="qcom_lemans_defconfig"`,github.com/qualcomm-linux/u-boot.git)。**仅在`iq-9075-evk-open-fw.conf`(开放固件)配置下成立**——u-boot编译产物`u-boot.mbn`会被直接改名为`uefi.elf`打包进uefi_a/b分区,替换掉闭源UEFI固件;默认`iq-9075-evk.conf`走的是QTI闭源`firmware-qcom-boot-qcs9100_00130.bb`提供的`uefi.elf`,u-boot完全不参与启动(`meta-qcom/classes-recipe/image_types_qcom.bbclass`第127-136行) |
| 二级引导 | 无(ABL本身即UEFI shell) | systemd-boot(`EFI_PROVIDER ?= "systemd-boot"`) |
| 内核镜像格式 | Android boot.img(`mkbootimg`,`BOOT_HEADER_VERSION="2"`) | UKI(Unified Kernel Image,`esp-qcom-image.bb`,`inherit uki uki-esp-image`) |
| cmdline生成时机 | ABL运行时动态拼接(slot_suffix、root设备等运行时决定) | 构建期静态烘焙进UKI(`esp-qcom-image.bb`第13-14行`UKI_CMDLINE`)。**初步判断"签名后不可变",核实后更正为"当前未签名"**——`oe-core/meta/classes-recipe/uki.bbclass`第85-87行提供`UKI_SB_KEY`/`UKI_SB_CERT`两个secure boot签名钩子,但在`meta-qcom*`、`meta-security*`、`meta-updater`、`build/conf`范围内全局检索这两个变量及`sbsign`均零命中,说明当前默认构建的UKI没有做secure boot签名,cmdline连同kernel/initrd是以未签名状态静态烘焙进UKI |
| initramfs/ramdisk | 有vendor_boot/ramdisk概念(`dm-verity-initramfs*`系列bbclass) | 独立的vendor_boot/ramdisk分区概念消失,但initrd本身并未去掉:`meta-qcom-distro/conf/distro/include/qcom-base.inc`第56行`INITRAMFS_IMAGE = "initramfs-rootfs-image"`(注释"Pull in the initrd image by default"),对应`meta-qcom/recipes-kernel/images/initramfs-rootfs-image.bb`(DESCRIPTION="Ramdisk image for pivoting into rootfs")内嵌进UKI,用于pivot到rootfs,并非"无initrd启动" |
| root挂载依据 | ABL运行时拼接,用户态`abctl`读取`/proc/cmdline`中`SLOT_SUFFIX`判定当前槽位 | systemd PID1挂载单一`PARTLABEL=rootfs` |

## 关键差异

- 启动链从"专有Android Bootloader(ABL/EDK2,闭源vendor源码)+Android boot.img格式"变为"上游开源u-boot+标准UEFI/systemd-boot+UKI",这不只是格式替换,而是把"谁能改启动参数/谁能验证启动产物"这件事从"ABL vendor闭源二进制"整体搬到了"Yocto构建配置+UKI"上,可审计性和实际安全强度是两件独立的事——前者显著提升,后者需要单独确认。
- cmdline产生时机反转:downstream(maili)运行时动态拼接,灵活但审计困难,仓库里看不到最终形态;QLI2.0构建期静态嵌入UKI,理论上更贴近measured/verified boot的形态,但**当前实际未做secure boot签名**(见上表`UKI_SB_KEY`/`UKI_SB_CERT`零命中的证据),即UKI这套"能装载签名"的机制在本仓库处于"能力在场但未上岗"状态,静态化目前只带来了可复现性/审计性收益,还没有兑现签名带来的防篡改收益。
- initramfs/ramdisk层面看似"消失",实质是Android式vendor_boot/ramdisk分区概念被去掉,initrd本体(pivot-to-rootfs用)仍以`initramfs-rootfs-image`形式默认内嵌进UKI,和"root挂载依据从slot动态解析变为单一PARTLABEL"共同指向同一件事:整个OS层的运行时可变性(A/B槎位、initrd来源、cmdline)在QLI2.0里被收敛成构建期固定的单一形态。

## 影响与风险

- 启动链开源化(u-boot替代ABL/EDK2)显著提升可审计性和社区可维护性,但也失去了QTI官方对ABL长期维护安全补丁的直接支撑,需确认`qualcomm-linux/u-boot`fork的安全更新节奏。
- UKI当前未做secure boot签名(证据见上表),意味着如果后续要求"改cmdline/kernel需要重新构建并签名"的可审计收益,需要先补上`UKI_SB_KEY`/`UKI_SB_CERT`签名链路和密钥管理,这不是自动获得的能力;在此之前,cmdline静态化带来的主要是可复现性,而非防篡改。
- cmdline静态化对产线多SKU/多变体(需要在同一镜像里切换不同console/内存布局参数)的支持方式需要重新设计。
- Recovery/OTA触发路径完全不同,涉及售后维修、字段升级失败恢复流程都要重新制定SOP(详见output/Platform_Features/OTA_Mechanism/OTA_Mechanism.md)。

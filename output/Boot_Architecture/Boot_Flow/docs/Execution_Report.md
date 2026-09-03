# Boot_Flow 取证过程复盘

本文档复盘`Boot_Flow.md`当前《对比总览》表是怎么从检索动作一步步取得的,按`rules/Boot_Architecture/Boot_Flow.md`"Boot_Flow专属取证要点"逐条展开。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Boot_Flow.md`。

## 逐项取证过程

### 1. PBL→XBL/SBL→TZ/HYP
**做法**:确认这几级属于SoC芯片固化行为,两侧配置里无差异化空间,不需要逐项深挖证据。
**支撑结论**:《对比总览》表第1行"相同/相同"。

### 2. 主Bootloader身份
**做法**:QLI1.0侧读取`abl-squashfs.bb`确认其`require edk2_git.bb`,即ABL基于EDK2定制;QLI2.0侧读取`meta-qcom/recipes-bsp/u-boot/u-boot-qcom_git.bb`的`SRCREV="5a77d4670d8084ada24a2735dda75788ed5ce925"`及`meta-qcom/conf/machine/include/qcom-u-boot-common.inc`第13行`UBOOT_CONFIG[iq-9075-evk]="qcom_lemans_defconfig"`。
**关键限定条件的发现**:进一步读取`meta-qcom/classes-recipe/image_types_qcom.bbclass`第127-136行,发现u-boot编译产物`u-boot.mbn`只在`iq-9075-evk-open-fw.conf`(开放固件)配置下才被改名为`uefi.elf`打包进uefi_a/b分区;默认`iq-9075-evk.conf`走的是QTI闭源`firmware-qcom-boot-qcs9100_00130.bb`提供的`uefi.elf`,u-boot完全不参与启动。这是"注意区分默认配置与可选配置"这条Boot_Architecture专属取证指引的直接应用——如果只看recipe存在就下结论"QLI2.0默认用u-boot",会漏掉这个关键限定。
**支撑结论**:《对比总览》表第2行(含"仅在...配置下成立"的限定语)。

### 3. 二级引导层
**做法**:读取`meta-qcom/conf/machine/include/qcom-common.inc`第63行`EFI_PROVIDER ?= "systemd-boot"`。
**支撑结论**:《对比总览》表第3行。

### 4. 内核镜像封装格式
**做法**:QLI1.0侧确认`mkbootimg`工具与`BOOT_HEADER_VERSION="2"`对应Android boot.img格式;QLI2.0侧读取`esp-qcom-image.bb`的`inherit uki uki-esp-image`。
**支撑结论**:《对比总览》表第4行。

### 5. cmdline生成时机与UKI签名(本文档证据链核心,含一次纠错)
**做法**:先确认`esp-qcom-image.bb`存在`UKI_CMDLINE`变量,判定cmdline是构建期静态烘焙。
**初步判断**:构建期静态烘焙进UKI,直觉推断为"签名后不可变"。
**核实过程**:读取`oe-core/meta/classes-recipe/uki.bbclass`第85-87行,确认`UKI_SB_KEY`/`UKI_SB_CERT`是UKI机制自带的secure boot签名钩子;随后在`meta-qcom*`、`meta-security*`、`meta-updater`、`build/conf`范围内对这两个变量及`sbsign`做全局检索,结果为**零命中**。
**核实后结论**:更正为"当前未签名"——UKI这套"能装载签名"的能力钩子在场,但当前默认构建没有实际配置签名密钥/证书。
**支撑结论**:《对比总览》表第5行(含纠错标注),《关键差异》第2条,《影响与风险》第2条;该条同步进README《曾纠正过的结论》表,条目"QLI2.0 UKI是否签名(Boot_Flow/Bootargs)"。

### 6. initramfs/ramdisk机制存续方式
**做法**:读取`meta-qcom-distro/conf/distro/include/qcom-base.inc`第56行`INITRAMFS_IMAGE = "initramfs-rootfs-image"`及其注释"Pull in the initrd image by default",进一步定位对应recipe`meta-qcom/recipes-kernel/images/initramfs-rootfs-image.bb`(DESCRIPTION="Ramdisk image for pivoting into rootfs")。
**易错点排查**:若只看到"独立vendor_boot/ramdisk分区概念消失"就断言"无initrd启动",会与事实相反;实际initrd本体仍以`initramfs-rootfs-image`形式内嵌进UKI,用于pivot到rootfs。
**支撑结论**:《对比总览》表第6行,《关键差异》第3条。

### 7. root挂载依据的执行主体
**做法**:QLI1.0侧确认由ABL运行时拼接+用户态`abctl`读取`/proc/cmdline`中`SLOT_SUFFIX`判定槎位;QLI2.0侧确认由systemd PID1挂载单一`PARTLABEL=rootfs`。
**支撑结论**:《对比总览》表第7行。

## 交叉一致性说明

本文档《对比范围》"覆盖"第4条已明确写"本条是与Bootargs.md共享的证据链的权威归属方……Bootargs.md仅引用本文的这一结论,不重复取证",与`Principles.md`第3节阐述的分工原理一致,复核时应确认Bootargs.md侧确实只做引用未重新取证(已核实,见`../../Bootargs/Bootargs.md`《明确排除》第1条)。

# Bootloader 取证过程复盘

本文档复盘`Bootloader.md`当前《对比总览》表是怎么从检索动作一步步取得的,按`rules/Boot_Architecture/Bootloader.md`"Bootloader专属取证要点"逐条展开。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Bootloader.md`。

## 逐项取证过程

### 1. 主Bootloader二进制身份与来源可追溯性
**做法**:downstream(maili)侧确认ABL/EDK2的引入方式为`SRC_URI=file://edk2`(本地打包);QLI2.0侧读取`u-boot-qcom_git.bb`的`PV="2026.04+2026.07-rc2+git"`与`SRCREV="5a77d4670d8084ada24a2735dda75788ed5ce925"`,确认指向`git://github.com/qualcomm-linux/u-boot.git`的固定公开commit。
**支撑结论**:《对比总览》表"来源"行,《关键差异》第1条"闭源专有vs开源社区维护"。

### 2. 签名机制
**做法**:downstream(maili)侧确认`SIGNING_FUNCTION="sectoolv2_sign_abl"`、`QSIGN_TARGET="pebble"`;读取`qsigning.bbclass`发现`do_compose_vmimage`调用sectools时硬编码`--signing-mode TEST`。QLI2.0侧读取`meta-qcom/recipes-devtools/qtestsign/qtestsign_git.bb`的`SRC_URI="git://github.com/msm8916-mainline/qtestsign.git"`,确认是社区(msm8916-mainline)维护的测试签名工具而非QTI官方工具。
**深入验证"是否只到测试签名"这一判断**:进一步读取downstream(maili)真正的`sectools`二进制目录`src/vendor/qcom/proprietary/sectools`下`public/example/plugin_signer_example.py`及`example_resources/README.md`原文("In production, the private key should be OEM-generated...should be secured by an HSM"),确认`--signing-mode PLUGIN`是量产签名对接HSM的样板机制,但该样板不随BSP recipe分发——即使是更接近量产的downstream(maili)侧,Yocto recipe里实际调用的也只是TEST模式。
**支撑结论**:《对比总览》表"签名"行,《关键差异》第3条,《影响与风险》第3条(含sectools原文引用作为交叉验证证据,呼应规则第6条交叉验证要求)。

### 3. 板级配置机制
**做法**:读取`meta-qcom/conf/machine/include/qcom-u-boot-common.inc`第13行`UBOOT_CONFIG[iq-9075-evk]="qcom_lemans_defconfig"`,确认QLI2.0走标准u-boot defconfig机制;downstream(maili)侧确认为vendor DT/soc-repo定制方式(无对应标准defconfig变量)。
**支撑结论**:《对比总览》表"板级配置"行。

### 4. EFI二级引导层与开放固件变体
**做法**:确认downstream(maili)无独立第二引导层(ABL本身即UEFI shell);QLI2.0侧读取`iq-9075-evk-open-fw.conf`的`PREFERRED_PROVIDER_virtual/bootloader = "u-boot-qcom"`+`trusted-firmware-a-qcom`,确认存在"闭源固件"与"开放固件"两条并行路线。
**支撑结论**:《对比总览》表相应行,《关键差异》第2条"开放固件是叠加而非替换"。

## 关于"无纠错记录"的说明

`rules/Boot_Architecture/Bootloader.md`"已知易错点/纠错记录"一节明确写"暂无本文档内部的初步判断→核实后结论纠错记录",README《曾纠正过的结论》表亦未收录Bootloader相关条目。本文档不据此编造一次不存在的纠正过程,如实记录为:Bootloader主题取证过程中没有出现"先判断错、后改正"的情形,只有一条需要辨析、但不构成纠错的易读错点——签名机制表面是私有工具vs社区工具的对立,实质两侧都止步于测试签名,不应误读为"downstream(maili)已具备完整量产签名能力而QLI2.0退步"(已在`Bootloader.md`《关键差异》第3条辨析)。

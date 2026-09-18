# Kernel_Build 规则执行逻辑细节报告

本文档记录`Kernel_Build.md`当前结论的取证过程,重点复盘两处纠错(补丁统计口径、9域缺口收窄)——按`rules/Build_Architecture/Kernel_Build.md`"专属取证要点"逐条展开。原理性背景见同目录`Principles.md`,具体差异结论见`../Kernel_Build.md`。

## 逐条取证过程

### 1. ko编译框架与vendor驱动recipe覆盖面统计纠正
**最初判断**:仅扫`meta-qti-bsp*`层,得到8个使用`inherit linux-kernel-base`的recipe,容易低估downstream(maili) vendor驱动的实际规模。
**核实过程**:改用全树`grep -rl "inherit linux-kernel-base"`(不限`meta-qti-bsp*`),命中59处文件、分布在15个`meta-qti-*`层。
**修正结论**:真实规模是至少15个层、40+个recipe,远超仅扫`meta-qti-bsp*`得到的8个;覆盖mmrm/video/dsp-adsprpc/wlan/bt/display/touch/camera/security-TEE/gfx/eva/audio/synx等功能域。
**落到结论**:对比总览表"抽样vendor驱动recipe数"行。

### 2. 补丁统计口径纠正
**最初判断**:`kernel_platform`目录下`find`统计到5080个`*.patch`文件,若不加分类容易被误读为"5080个都是QTI内核定制补丁"。
**核实过程**:按目录精确复核这5080个文件的来源——`bazelbuild-bazel-central-registry`(4890个)、`external`目录下其余第三方vendored内容(rust 156、zlib 19、其余12,合计187)、`u-boot/tools/patman/test`(3个),4890+187+3=5080,与最初总数完全吻合但性质完全不同。
**修正结论**:真正的QTI Yocto层内核补丁只有6个,位于`poky/meta-qti-bsp/recipes-kernel/`,内容为dtc编译/lk指令集扩展/ALSA uapi重复include修复等杂项;其余5074个全部是Bazel模块注册表、u-boot patman测试fixture等第三方vendored噪声,与Qualcomm内核驱动定制无关。
**落到结论**:文档内独立小节《补丁统计口径纠正》,并与`output/Code_Composition/Patch_Management/Patch_Management.md`互相印证。

### 3. 9个功能域缺口范围纠正
**最初判断**:mmrm/dsp-adsprpc/wlan/bt/display/touch/security-TEE/eva/audio/synx共9个功能域在QLI2.0`meta-qcom*`全树没有对应`-dlkm`recipe,若止步于此容易得出"9个功能域全部是迁移缺口"的结论。
**核实过程**:对9个域逐一在QLI2.0内核配置片段(`meta-qcom/recipes-kernel/linux/linux-yocto-6.18/bsp/qcom-armv8a/qcom.cfg`)及各层recipe目录做定向grep,而非停在"没有-dlkm recipe"就下结论。
**修正结论**:
- wlan(`CONFIG_CFG80211=m`/`CONFIG_MAC80211=m`)、bt(`CONFIG_BT_HCIUART_QCA=y`)、display(`CONFIG_DRM_MSM*`)、audio(`CONFIG_SND_SOC_QCOM`+`meta-audioreach`独立层)、dsp-adsprpc(`CONFIG_QCOM_FASTRPC=m`)共5个域走标准内核配置内建/mainline驱动路径,天然不需要`-dlkm`recipe,不算缺口。
- security-TEE有真实但受限的对应物:`meta-qcom/dynamic-layers/meta-arm/recipes-security/optee/`+`minkipc_1.2.8.bb`,但仅挂在`rb3gen2-core-kit-open-fw.conf`/`iq-9075-evk-open-fw.conf`两个"open firmware"机型变体,已重新grep确认无其他机型引用。
- touch(全树`CONFIG_TOUCHSCREEN`零命中)、synx、mmrm三个域在kernel config、recipe、层目录里确认零命中,是真正意义上"完全没有对应物"的功能域。

真正需要架构师排期决策的缺口从"9个"收窄为"touch/synx/mmrm三个域+security-TEE是否扩展到默认机型"。
**落到结论**:《关键差异》第三条,对比总览表"抽样vendor驱动recipe数"行说明文字。

### 4. dts/dtb编译机制与迁移指南交叉核实
**做法**:按规则6交叉核实`reference/System_Architecture/Yocto/Migration notes for 6.0 (wrynose)`及whinlatter(5.3)存档页面。
**证据**:whinlatter release移除了`kernel-fitimage.bbclass`,替换为`kernel-fit-image`类并要求创建独立recipe构建FIT image;`dtb-fit-image.bbclass`挂独立task正是遵循该强制变更,不是meta-qcom自创组织形式。
**落到结论**:对比总览表"dts/dtb编译"行。

### 5. kernel provider双轨判定与动态变量解析交叉验证
**做法**:用`bitbake -e linux-qcom`(iq-9075-evk实际kernel provider)dump effective变量,交叉验证静态grep结论。
**证据**:`KERNEL_MODULE_PROBECONF`完整变量历史里只有documentation.conf的文档说明行,最终生效值仍是空,与静态grep结论一致,排除"间接赋值未被grep到"的可能性。
**落到结论**:《影响与风险》"静态审计+动态变量解析两条独立路径都收敛到同一结论"一段。

## 纠错记录汇总

本主题共两处纠错,均已写入产出文档正文(补丁统计口径纠正独立成节,9域收窄写入《关键差异》),不是静默覆盖:①补丁总量5080个≠QTI定制补丁数,真实只有6个;②9个功能域缺口收窄为3个真正缺口+1个受限对应物。

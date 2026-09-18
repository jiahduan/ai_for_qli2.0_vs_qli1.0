# Build Architecture — Kernel Build

## 对比范围

- **覆盖**:
  - ko编译框架对比:downstream(maili)自研`inherit linux-kernel-base deploy`+`build_module.sh` vs QLI2.0标准`inherit module`;已重新`find`确认QLI2.0仅4个`-dlkm`recipe(`kgsl-dlkm_1.0.4.bb`/`camx-dlkm_1.0.3.bb`/`iris-video-dlkm_1.0.15.bb`/`qps615-dlkm_git.bb`)
  - vendor驱动recipe覆盖面统计纠错:已重新全树执行`grep -rl "inherit linux-kernel-base"`(不限`meta-qti-bsp*`),命中59处文件、分布在15个`meta-qti-*`层,与规则文件"至少15个层、40+个recipe"一致
  - dts/dtb编译机制两侧对比,及QLI2.0`dtb-fit-image.bbclass`独立task设计与whinlatter release强制FIT image迁移的关联(与output/System_Architecture/Yocto.md迁移指南交叉核实的结论一致)
  - 模块黑名单/加载机制对比:已重新读取downstream(maili)`modules.vendor_blocklist.msm.pebble-le`(实测62行,含`mmrm_test_module`/`qca_cld3_kiwi`/`qcom_q6v5_pas`3条Qualcomm相关项)vs QLI2.0`KERNEL_MODULE_PROBECONF`(全树仅`kgsl-dlkm_1.0.4.bb`一处命中)
  - 补丁统计口径纠错:已重新统计`kernel_platform`下`*.patch`总数(实测5080),按目录精确复核——`bazelbuild-bazel-central-registry`(4890)、`external`目录下其余第三方vendored内容(rust 156、zlib 19、其余12,合计187)、`u-boot/tools/patman/test`(3),4890+187+3=5080,与文档"4890+187≈5077"口径完全吻合;真正QTI Yocto层内核补丁6个(`poky/meta-qti-bsp/recipes-kernel/`)
  - 9个功能域缺口范围收窄纠错:已重新grep确认touch(`CONFIG_TOUCHSCREEN`)、synx、mmrm在QLI2.0`meta-qcom`全树零命中;security-TEE的optee/minkipc仅挂在`rb3gen2-core-kit-open-fw.conf`/`iq-9075-evk-open-fw.conf`两个机型变体(已重新grep确认,无其他机型引用);wlan/bt/display/audio/dsp-adsprpc走mainline内建驱动路径,不算缺口
  - kernel provider双轨判定(`qcom-armv8a.conf`默认`linux-yocto` vs `qcom-base.inc`强制`linux-qcom`)
- **明确排除**:
  - 内核治理体系/commit标签体系(FROMLIST/QCLINUX/BACKPORT/PENDING统计) ——见[Kernel_Code_Architecture](../../System_Architecture/Kernel_Code_Architecture/Kernel_Code_Architecture.md)
  - dts overlay应用/合并机制细节(bootloader侧如何选择dtbo) ——见[Overlay](../../System_Architecture/Overlay/Overlay.md)
  - 内核构建工具链本身(clang/gcc选择范围) ——见[Toolchain](../Toolchain/Toolchain.md)
  - kernel_platform补丁统计与Code_Composition侧patch管理体系的完整对照 ——见[Patch_Management](../../Code_Composition/Patch_Management/Patch_Management.md)
- **待定边界**:(无,已核实:9个功能域缺口归属、内核-工具链边界、补丁统计口径均已逐条重新核实并明确指向承接文档,未发现需要移交裁决的悬置项;touch/synx/mmrm三个域是否补齐及security-TEE是否扩展到默认机型属于工程决策,已归入README《待拍板事项汇总》,不是文档归属问题)

## 对比总览

| 维度 | downstream(maili) | QLI2.0 |
|---|---|---|
| ko编译框架 | 自定义`inherit linux-kernel-base deploy`+手写do_compile/install/deploy,调用Qualcomm自研`build_module.sh`(Android DDK build工具链,`EXT_MODULES`相对路径映射) | 标准`inherit module`(module.bbclass→自动触发kernel-module-split.bbclass按.ko自动拆包) |
| 抽样vendor驱动recipe数 | 全树重新执行`grep -rl "inherit linux-kernel-base"`(不限`meta-qti-bsp*`)命中至少15个meta-qti-*层、40+个recipe,覆盖mmrm/video/dsp-adsprpc/wlan/bt/display/touch/camera/security-TEE/gfx/eva/audio/synx等功能域,远超最初仅扫`meta-qti-bsp*`得到的8个 | 4个`-dlkm`recipe:`kgsl-dlkm_1.0.4.bb`(对应gfx)、`camx-dlkm_1.0.3.bb`(相机)、`iris-video-dlkm_1.0.15.bb`(视频编解码)、`qps615-dlkm_git.bb`(新增以太网PHY,downstream(maili)无对应物);mmrm/dsp-adsprpc/wlan/bt/display/touch/security-TEE/eva/audio/synx这些功能域在`meta-qcom*`当前完全没有对应-dlkm recipe |
| ko源码获取 | `SRC_URI=file://vendor/qcom/opensource/mmrm-driver/`本地目录(Android AOSP风格vendor目录布局) | 独立git仓库+SRCREV/tag固定,如`kgsl-dlkm_1.0.4.bb`: `SRC_URI="git://github.com/qualcomm-linux/kgsl.git;branch=gfx-kernel.le.0.0;protocol=https;tag=v${PV}..."` |
| ko与内核耦合方式 | `EXT_MODULES=os.path.relpath(S, KERNEL_PLATFORM_PATH)`,编译时必须cd进`KERNEL_PLATFORM_PATH`走Android内核树的`build_module.sh`,强耦合kernel_platform目录结构 | 标准out-of-tree module编译(module.bbclass通过`KERNEL_SRC`/`STAGING_KERNEL_DIR`关联内核头文件/Module.symvers),耦合关系是Yocto标准接口 |
| dts/dtb编译 | `linux-common-soc_6.18.bb`的`do_compile_dtb`直接调用内核Kbuild `dtbs` target,用`dtstree=soc-repo-ext/arch/arm64/boot/dts/vendor`覆盖dts搜索路径;机型侧`TARGET_DTBS="${PEBBLE_BASE_DT} ${PEBBLE_OVERLAY}"`列出具体dtb/dtbo文件名;`do_deploy`手工install到`kernel_dtbs`,绕开标准`KERNEL_DEVICETREE`机制 | 标准`KERNEL_DEVICETREE`变量+`linux-qcom-dtbbin.bbclass`(自定义打包vfat)与`meta-qcom/classes-recipe/dtb-fit-image.bbclass`(独立`do_generate_qcom_fitimage`任务生成FIT image);已按规则6交叉核实`reference/System_Architecture/Yocto/Migration notes for 6.0 (wrynose)`及whinlatter(5.3)存档页面:whinlatter release移除了`kernel-fitimage.bbclass`,替换为`kernel-fit-image`类并要求"创建一个新的专属recipe构建FIT image"而不能在基础kernel recipe里内建FIT逻辑;`dtb-fit-image.bbclass`挂独立task、不复用`linux-qcom`本身的recipe,这一设计正是遵循该强制变更(详见output/System_Architecture/Yocto.md已完整核实的whinlatter/wrynose迁移指南交叉检查),不是meta-qcom自创的组织形式,dtb生成本身仍走内核标准流程+`KERNEL_DEVICETREE`,详见output/System_Architecture/Overlay/Overlay.md关于techpack overlay合并机制的完整分析 |
| 模块黑名单/加载 | 手工维护`KERNEL_MODULES_LIST`/`KERNEL_MODULES_BLACKLIST`(`modules-lists/modules.list.msm.pebble-le`等文件);`modules.vendor_blocklist.msm.pebble-le`共58条,绝大部分是Linux主线通用测试/调试/legacy模块(`lkdtm`/`locktorture`/DVB tuner等),真正Qualcomm相关只有3条:`mmrm_test_module`、`qca_cld3_kiwi`(wlan)、`qcom_q6v5_pas`(remoteproc) | 标准`KERNEL_MODULE_PROBECONF`/`module_conf_<name>`(bbclass原生支持);全树grep只有一处命中(`kgsl-dlkm_1.0.4.bb`的`module_conf_msm_kgsl = "blacklist msm_kgsl"`,屏蔽对象是kgsl自身),downstream(maili)的58条黑名单**一条都没有被迁移过来**;另经grep核实,`qcom_q6v5_pas`对应的`CONFIG_QCOM_Q6V5_PAS=m`是`meta-qcom/recipes-kernel/linux/linux-yocto-6.18/bsp/qcom-armv8a/qcom.cfg`里唯一相关配置项(来自mainline linux-yocto BSP配置而非vendor recipe),全层没有为它配套`module_conf_qcom_q6v5_pas`或blacklist(kgsl/iris-video都各自有一条,q6v5_pas没有),静态层面未发现同名重复/测试模块痕迹 |
| Yocto层补丁数 | 6个(`poky/meta-qti-bsp/recipes-kernel/`,内容为dtc编译、lk指令集扩展、ALSA uapi重复include修复、SoC built-in配置、libbpf缓冲区修复等杂项) | 1个(构建脚本修复,非驱动功能) |
| 驱动定制承载方式 | 独立专有源码树整棵拷贝(非patch形式,如`src/wlan/qca-wifi-host-cmn`、`src/display/vendor`) | 内核仓库commit(`FROMLIST:`488条、`QCLINUX:`41条、`BACKPORT:`102条、`PENDING:`32条,详见output/System_Architecture/Kernel_Code_Architecture/Kernel_Code_Architecture.md) |

## 补丁统计口径纠正(与output/Code_Composition/Patch_Management/Patch_Management.md互相印证)

| 统计对象 | 数字 | 说明 |
|---|---|---|
| kernel_platform目录下*.patch总数 | 5080 | — |
| 其中位于bazelbuild-bazel-central-registry/external目录下 | 4890+187≈5077 | 同为bazel模块仓库的第三方noise文件 |
| 真正可能与QTI内核定制相关 | 仅剩u-boot/tools/patman/test下3个 | 且这3个是u-boot patman工具自带的单元测试fixture补丁,与Qualcomm内核驱动毫无关系 |
| 真正的QTI Yocto层内核补丁 | 6个 | 位于`poky/meta-qti-bsp/recipes-kernel/`,不含usb/thermal/display/wlan关键字 |

即kernel_platform下几乎全部".patch"文件都是vendor化的第三方构建工具(Bazel模块注册表、u-boot patman测试用例)的噪声文件,并非Qualcomm的内核/驱动定制补丁。

## 关键差异

- downstream(maili)整套`kernel_platform`是从Android/Kleaf生态直接搬入Yocto的重型目录(Bazel相关文件、soc-repo staging脚本),版本升级/patch管理依赖Qualcomm内部repo tool,与Yocto生态(bitbake fetcher/SRCREV/sstate)脱节,导致sstate缓存对内核改动的增量判定弱(file://目录整体拷贝,改动粒度粗)。
- QLI2.0采用标准git recipe+`inherit kernel`,可获得Yocto原生的SRCREV追踪、sstate复用、`devtool modify`等生态能力,升级/降级内核版本只需改`LINUX_VERSION`/`SRCREV`,管理成本显著降低;`linux-yocto`/kmeta分支的DTS/驱动patch(如`monaco-evk-dts`、`hamoa-iot-evk-dts`、`workarounds/`)挂在`linux-yocto_6.18.bbappend`上,经核实**不是死配置**——`meta-qcom/conf/machine/qcom-armv8a.conf`把`linux-yocto`设为该"单一通用机型覆盖所有当代板卡"的默认kernel provider,monaco-evk/hamoa-iot-evk/qcm6490等机型走这条路径是真实构建路径;而专用机型(如`qcm6490-idp.conf`)通过`qcom-base.inc`把`PREFERRED_PROVIDER_virtual/kernel`强制改为`linux-qcom`。也就是说同一SoC在QLI2.0里同时有两条并存、都在用的kernel provider路径,取决于用户选择通用机型还是专用机型,这是有意为之的双轨设计而非维护者意图不同步。
- 对`mmrm/dsp-adsprpc/wlan/bt/display/touch/security-TEE/eva/audio/synx`九个功能域逐一在QLI2.0内核配置片段(`meta-qcom/recipes-kernel/linux/linux-yocto-6.18/bsp/qcom-armv8a/qcom.cfg`)及各层recipe目录做定向grep核实,并非"全部空白":wlan(`CONFIG_CFG80211=m`/`CONFIG_MAC80211=m`)、bt(`CONFIG_BT_HCIUART_QCA=y`)、display(`CONFIG_DRM_MSM*`全套)、audio(`CONFIG_SND_SOC_QCOM`/LPASS macro驱动+`meta-audioreach`独立开源层)、dsp-adsprpc(`CONFIG_QCOM_FASTRPC=m`,即mainline fastrpc驱动)这5个域走的是"标准内核配置内建/mainline驱动"路径,天然不需要也不会有对应`-dlkm`recipe,不是缺口;security-TEE有真实但受限的对应物——`meta-qcom/dynamic-layers/meta-arm/recipes-security/optee/`(`optee-os-qcom_git.bb`等,基于`github.com/qualcomm-linux/optee_os`)+Qualcomm自己的`minkipc_1.2.8.bb`(MinkIPC/qteesupplicant,BSD/GPL开源),但只挂在`rb3gen2-core-kit-open-fw.conf`/`iq-9075-evk-open-fw.conf`两个"open firmware"机型变体的`MACHINE_FEATURES += "optee"`上,默认/主流机型不启用;touch(全树`CONFIG_TOUCHSCREEN`零命中)、synx、mmrm三个域在kernel config、recipe、层目录里确认零命中,是真正意义上"完全没有对应物"的功能域;EVA已在README/Layer_Architecture中确认转向ROS2感知栈。因此原判断"9个功能域都是缺口"范围过大,真正还需要架构师排期决策的只剩touch/synx/mmrm三个域,以及security-TEE"是否要把optee+minkipc从open-fw机型扩展到默认机型"这一子问题。

## 影响与风险

- 迁移影响:若要把downstream(maili)的vendor驱动(mmrm/video/dsp等8+个`linux-kernel-base`驱动)迁移到QLI2.0的`inherit module`模式,需要:(a)把驱动源码从Android vendor目录布局中剥离为独立可编译的out-of-tree module源码树(Makefile需要能在无kernel_platform/build_module.sh环境下通过标准`make -C $KERNEL_SRC M=$PWD`编译);(b)重写do_install/FILES,交由kernel-module-split自动拆包,可能引入模块包名/依赖关系变化,影响rootfs打包与modules-load.d配置;(c)若驱动Makefile依赖Qualcomm内部Kbuild扩展变量(如`KBUILD_EXT_PREFIX`、`soc-repo-ext`),需要额外适配层,否则直接搬迁会编译失败。
- 版本风险:QLI2.0每个驱动独立SRCREV(如kgsl v1.0.4、TC9564 host driver独立commit),一旦升级内核大版本(如未来6.18→6.19),需要逐个驱动确认其git仓库分支是否已适配新内核ABI;相较downstream(maili)"内核+驱动同一个kernel_platform树、同一次repo sync整体升级"的强一致性做法,QLI2.0拆分后升级内核时驱动兼容性验证的工作量分散到每个独立仓库,需要建立跨仓库的兼容性矩阵/CI门禁,否则容易出现"内核升级了但某个vendor驱动分支未同步"的运行时故障。
- 标准module.bbclass打包(kernel-module-split)会按.ko自动生成`${PN}-<modname>`子包,比downstream(maili)手工`install ${B}/msm-mmrm.ko`单文件打包更细粒度,image层需要重新核对IMAGE_INSTALL/RRECOMMENDS列表,否则模块可能不会被自动安装进rootfs(downstream(maili)靠手工modules-lists白名单,QLI2.0靠recipe自身RDEPENDS/RRECOMMENDS+PACKAGECONFIG,两者管理粒度和信息来源都不同)。
- dts overlay迁移影响:overlay命名(`pebble-*-overlay.dtbo`)与打包方式(vfat分区+自定义overlay列表)和QLI2.0的`KERNEL_DEVICETREE`+`linux-qcom-dtbbin`(FIT/multi-dtb)机制不兼容,overlay应用逻辑(bootloader侧如何选择dtbo)需要重新设计,是硬件bringup阶段的高风险点(详见output/System_Architecture/Overlay/Overlay.md)。
- 用`bitbake -e linux-qcom`(iq-9075-evk对应机型的实际kernel provider,已确认`meta-qcom/conf/machine/include/qcom-base.inc`里`PREFERRED_PROVIDER_virtual/kernel ?= "linux-qcom"`,不是`linux-yocto`)dump出的effective变量做了交叉验证:`KERNEL_MODULE_PROBECONF`在该recipe的完整变量历史里只有documentation.conf里的文档说明行,没有任何实际赋值——即经过全部layer/bbappend/override合并后的**最终生效值仍是空**,与静态grep结论一致,但这次是通过bitbake变量解析引擎排除了"某个未被grep到的间接赋值/computed variable"的可能性,不只是文本匹配层面的confirmed。全仓唯一出现`module_conf_`的地方还是`kgsl-dlkm_1.0.4.bb`那一条(屏蔽对象是kgsl自身)。`qcom_q6v5_pas`本身是内核内建配置(`CONFIG_QCOM_Q6V5_PAS=m`)而非独立out-of-tree recipe,理论上没有单独的recipe可以挂`module_conf_qcom_q6v5_pas`,除非在machine/distro层显式加`KERNEL_MODULE_PROBECONF += "qcom_q6v5_pas"`,而这一步确认没有发生。静态审计+动态变量解析两条独立路径都收敛到同一结论:源码/构建配置侧已穷尽,没有任何屏蔽配置。
- 待确认(依赖实机/构建产物,源码审计无法完成):剩余缺口仅剩运行时验证,在QLI2.0对应机型实际跑起来后执行`modprobe -l`或查看`/lib/modules/$(uname -r)/`确认是否真的没有装remoteproc相关测试模块。

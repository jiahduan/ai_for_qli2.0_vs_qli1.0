# Build Architecture — Toolchain (GCC/LLVM/glibc)

## 对比范围

- **覆盖**:
  - 用户态C/C++工具链版本与选择逻辑:`tcmode-default.inc`(GCC`13.%`)、`binutils_2.42.bb`/`_2.46.bb`、`glibc_2.39.bb`/`_2.43.bb`、Rust `1.75`/`1.94.1`,distro层二次锁定对照(`qti-distro-base.inc`的`GCCVERSION`锁定 vs `qcom-base.inc`未锁定)
  - TCLIBC可选项扩展:QLI1.0(baremetal/glibc/musl/newlib)vs QLI2.0新增picolibc(面向裸机/RTOS场景);已重新确认QLI2.0`oe-core/meta/recipes-core/picolibc/`(`picolibc_git.bb`/`picolibc.inc`/`picolibc-helloworld_git.bb`)及自测用例`oeqa/selftest/cases/picolibc.py`存在
  - `TC_CXX_RUNTIME`唯一赋值点及全层override扫描:本次已重新grep确认QLI2.0全树仅`bitbake.conf`一处弱赋值`??= "gnu"`,其余命中处均为`bb.utils.contains("TC_CXX_RUNTIME", ...)`条件表达式;`PREFERRED_TOOLCHAIN`已重新grep全部machine/distro层(meta-qcom系列+meta-security/meta-updater/meta-virtualization/meta-selinux/meta-audioreach/meta-ros/meta-lts-mixins),零override命中
  - meta-clang层组织形式变化:已重新核对`oe-core/meta/recipes-devtools/clang/`recipe清单(`clang_git.bb`/`llvm_git.bb`等)与`toolchain/clang.bbclass`,和QLI1.0`meta-clang`层同名recipe对照
  - 内核构建强制clang范围纠错:已重新grep`KERNEL_CC.*clang`,命中QLI1.0`linux-msm_5.4.bb`(`KERNEL_CC = ${STAGING_BINDIR_NATIVE}/clang...`)、`linux-msm_5.10.bb`、`linux-common-soc_6.18.bb`等9个recipe文件,与规则文件所列机型清单一致;`kernel-toolchain_*.bb`(provider,AOSP预编译clang,与meta-clang层无关)
  - QLI2.0仅两处recipe级`TOOLCHAIN="clang"`override:已重新grep确认`meta-openembedded/meta-oe/.../perfetto.bb`、`meta-ros/.../ogre-next_2.2.7.bb`仍存在,且`ogre-next`真实选中版本核实为不带override的`_2.3.3.bb`
  - 安全加固基线对比:已重新`find -iname security_flags.inc`确认QLI1.0侧存在5份(`meta-qti-distro`/`meta-qti-internal`/`meta-qti-bsp-prop`/`meta-qti-cta-internal`/poky默认),QLI2.0仅`oe-core/meta/conf/distro/include/security_flags.inc`一份;已重新grep确认QLI1.0清单里的专有组件名(npu/audiohal/gps-utils/loc-hal/loc-core/bt-app/libbt-vendor/qmmf-sdk)在QLI2.0全树零命中
- **明确排除**:
  - Yocto版本跳跃本身的逐release迁移指南交叉核实(scarthgap→wrynose完整breaking change清单) ——见[Yocto](../System_Architecture/Yocto.md)
  - 内核构建体系本身(module.bbclass/dlkm recipe/dts-dtb编译/模块黑名单) ——见[Kernel_Build](Kernel_Build.md)
- **待定边界**:(无,已核实:clang在用户态可选项与内核构建强制两个层面的覆盖范围已逐一重新取证,未发现第三个遗漏的使用场景)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| GCC | `13.%`(tcmode-default.inc) | `15.%` |
| binutils | `2.42%`(`binutils_2.42.bb`) | `binutils_2.46.bb` |
| glibc | `2.39%`(`glibc_2.39.bb`) | `2.43%`(`glibc_2.43.bb`) |
| Rust | `1.75%` | `1.94.1%` |
| distro层GCC二次锁定 | `qti-distro-base.inc`二次锁定`GCCVERSION="13.4%"` | `qcom-base.inc`未二次锁定,继承oe-core默认 |
| TCLIBC可选项 | baremetal/glibc/musl/newlib | +**picolibc**(新增,面向裸机/RTOS场景) |
| meta-clang独立层 | 存在(`poky/meta-clang`,`LLVMVERSION="18.1.6"`,已纳入至少一个构建变体的bblayers.conf) | 不存在,但功能已合并进oe-core主干(见下) |
| meta-clang默认生效范围 | `TC_CXX_RUNTIME ??= "gnu"`,默认仍是GCC,clang只是按recipe/机器override切换的可选项 | 不适用 |

## 用户态C/C++工具链纠正——内核构建实际强制使用clang

| 项 | QLI1.0 | QLI2.0 |
|---|---|---|
| `TC_CXX_RUNTIME`全树赋值 | 全文件类型限定搜索命中9处,除唯一赋值(`bitbake.conf: TC_CXX_RUNTIME ??= "gnu"`)外全部是条件判断,全树没有任何machine/distro conf把它设为llvm或android | 同样保持默认gnu,`PREFERRED_TOOLCHAIN_TARGET/NATIVE/SDK ??= "gcc"`;已用`grep -rn PREFERRED_TOOLCHAIN`扫描`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`/`meta-security`/`meta-updater`/`meta-virtualization`/`meta-selinux`/`meta-audioreach`/`meta-ros`/`meta-lts-mixins`全部machine/distro层,零命中override,确认不是仅凭"没搜到就下结论",是真实做过override扫描的空结果 |
| 内核构建工具链(按内核版本recipe) | `linux-msm_5.4.bb`(sa410m、sa515m):`KERNEL_CC=.../clang`,显式`TOOLCHAIN="clang"`,`RUNTIME="llvm"`;`linux-msm_5.10/5.15.bb`(neo/cinder/kalama/qrb5165/qcm2290-mtp)、`linux-msm_6.%.bb`/`linux-common_6.12.bb`/`linux-common-soc_6.18.bb`(trustedvm系列/mdm9607/pineapple/kera/sun/seraph/pebble):`KERNEL_CC=.../clang/bin/clang`,**无条件** | `meta-qcom/recipes-kernel/`与相关classes/全文件搜索无任何clang/llvm关键字,内核构建默认走标准gcc |
| 主流机型clang来源 | `virtual/kernel-toolchain-native`,provider是`kernel-toolchain_{5.10,5.15,6.%}.bb`,只是把`kernel_platform/prebuilts/clang/host/linux-x86/`下的谷歌AOSP预编译clang二进制原样打包安装(`do_compile[noexec]=1`),**与meta-clang层完全无关**,不依赖LLVM 18.1.6源码构建 | 不适用,无对应机制 |
| meta-clang真实触发范围 | 全树仅`sa410m`、`sa515m`两个边缘机型的内核构建真正触碰meta-clang层,`DEPENDS`带`clang-native`解析到`meta-clang/recipes-devtools/clang/clang_git.bb` | 不适用 |
| meta-clang组织形式变化 | — | `oe-core/meta/recipes-devtools/clang/{clang_git.bb, llvm_git.bb, libcxx_git.bb, compiler-rt_git.bb, compiler-rt-sanitizers_git.bb, lld_git.bb, lldb_git.bb, clang-crosssdk_git.bb, clang-cross_git.bb, libclc_git.bb}`与QLI1.0`meta-clang/recipes-devtools/clang/`几乎同一套recipe名字;`oe-core/meta/classes/toolchain/clang.bbclass`与QLI1.0`meta-clang/classes/clang.bbclass`逻辑高度一致——这是Yocto社区把meta-clang层功能升级到oe-core核心层级,而非能力删除 |
| 其他clang消费者 | `meta-qti-gfx-prop/recipes/adreno/clangtblgen.bb`(自带独立LLVM源码树,专为Adreno 200生成shader工具,与meta-clang/AOSP预编译clang均无关,孤立遗留代码);`uutils-coreutils`selinux PACKAGECONFIG可选依赖clang-native(可被bbappend移除);`meta-virtualization/.../vhost-device-gpio_0.1.0.bb`硬依赖clang-native并用SKIP_RECIPE保护 | 全层`grep -rln 'TOOLCHAIN[[:space:]]*=[[:space:]]*"clang"'`只命中两处recipe级override:`meta-openembedded/meta-oe/recipes-devtools/perfetto/perfetto.bb`、`meta-ros/meta-ros-common/recipes-devtools/ogre-next/ogre-next_2.2.7.bb`;已按规则3做override-scan逐个核实是否真的进入镜像依赖链而非仅层内存在:①`perfetto`在`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`/`meta-ros`全层`grep -rl perfetto`零命中依赖方,没有任何recipe/packagegroup引用它,不进入任何已知构建目标;②`ogre-next`有3个版本共存(`_2.2.7.bb`带clang override,`_2.3.3.bb`/`_3.0.0.bb`不带),各ROS2 distro的`PREFERRED_VERSION_ogre-next`各不相同(`meta-ros2-humble`→2.2.7,`meta-ros2-jazzy`/`kilted`/`meta-spaceros-jazzy`→2.3.3,`meta-ros2-rolling`→3.0.0),而`meta-qcom-robotics-sdk/conf/distro/*.conf`与`ci/qcom-robotics-distro.yml`里`DISTRO_FEATURES:append`/`distro:`实际选的全部是`ros2-jazzy`(零处出现`ros2-humble`),即QLI2.0真实构建路径解析到的是`ogre-next_2.3.3.bb`,不带clang override的那个版本。结论:这两处recipe级override目前都不在QLI2.0任何已知镜像的实际依赖链里,不能算作"QLI2.0存在clang默认使用点" |
| 间接/隐式LLVM依赖 | Mesa `gallium-llvm`/`libclc`(仅x86/x86-64/native默认追加,aarch64不启用)、BPF工具链(clang-native+bpftool-native,可选PACKAGECONFIG,默认关闭)、`rust-llvm_1.75.0.bb`(自建私有静态LLVM供rustc使用) | 相同社区recipe内容,两侧行为基本一致;`rust_1.94.1.bb`改为`DEPENDS += "llvm"`+链接系统共享llvm包(Rust上游构建系统演进,与meta-clang存废无关) |

## 关键差异

- 原判断"clang只是可选项,默认gcc"仅对用户态包成立;内核构建层面QLI1.0现役主流机型(pineapple/kalama/sun/mdm9607/cinder/qcm2290-mtp/qrb5165-rb5/trustedvm系列/seraph/pebble等)强制走AOSP预编译clang,这条路径与meta-clang层无关,体量远大于最初判断的"仅可选项"。
- QLI2.0"没有meta-clang层"是组织形式变化——oe-core(wrynose)已把等价recipe和`clang.bbclass`机制并入主干,默认值与选择逻辑同QLI1.0完全一致,不是能力缺失。
- QLI2.0内核构建体系(meta-qcom+标准linux-yocto)与QLI1.0(私有MSM内核+AOSP预编译clang)是两套完全不同的工程范式,后者在QLI2.0没有被迁移也没有被替代,是彻底不存在的对应体系(因为整个私有MSM内核+DLKM vendor模块体系都不存在了,不是"移除了clang选项"而是"没有移植过去那套内核工程")。
- Mesa/BPF/OpenCL等隐式LLVM依赖两侧完全对等,均为默认关闭的可选路径,不构成差异;Rust内部LLVM依赖两侧均存在,属编译器实现细节,不应与meta-clang/clang工具链选项混淆。

## 影响与风险

- 用户态可选clang工具链:QLI1.0里本来就基本未被激活(仅sa410m/sa515m边缘机型触碰),迁移到QLI2.0后该能力以合并进oe-core主干的形式依然存在且默认行为一致,风险低。
- 内核构建工具链(实际影响面更大):如果QLI2.0产品目标包含需要复用QLI1.0私有MSM内核+AOSP clang预编译工具链的机型/DLKM模块(如迁移pineapple/kalama/sun等现役SoC平台的私有内核栈到QLI2.0),需要明确QLI2.0是否要引入等价的`virtual/kernel-toolchain-native`+AOSP预编译clang机制,否则这些内核/DLKM模块无法直接迁移(QLI2.0当前的meta-qcom上游内核路径默认用gcc,构建方式、driver生态、DLKM打包机制都不同,是两套内核工程体系而非同一体系换了编译器)。这一点应作为独立风险项提给架构师,与Kernel_Build.md联动,而不是归入"clang工具链是否保留"的讨论。
- GCC 13→15、glibc 2.39→2.43、binutils 2.42→2.46三者是标准Yocto 5.0(scarthgap)→6.0(wrynose)升级的一部分,QLI1.0/QLI2.0之间跳过了styhead/walnascar/whinlatter三个中间release(详见output/System_Architecture/Yocto.md已完整核实的逐release迁移指南交叉检查)。已核实:`reference/System_Architecture/Yocto/Migration notes for 6.0 (wrynose)`存档页面里列出的breaking change清单(BitBake fetcher移除、`INIT_MANAGER`默认值改systemd、`DISTRO_FEATURES_BACKFILL`系列变量重构、native/cross类`DEBUG_BUILD`行为变化、U-Boot `UBOOT_CONFIG`拆分、`pkgconfig`变量不再自动export、SPDX2.2/`cve-check`移除等)里**不包含**GCC/glibc/binutils版本号本身的breaking change条目——工具链版本提升属于oe-core逐release的recipe版本迭代(见output/System_Architecture/Yocto.md里scarthgap→wrynose的gcc/glibc/LLVM版本对照表),不是Yocto发布流程强制的迁移动作,不需要因为"跨了3个release"而额外担心工具链断层;真正需要重新验证的风险来自glibc/gcc版本实现自身的ABI/安全默认值演进,通常需要重新验证:(a)依赖特定GCC ABI/内建函数的专有recipe(尤其QTI音视频/相机等native二进制打包场景);(b)glibc新版本可能收紧的符号版本(symbol versioning)/安全特性默认值(如`_FORTIFY_SOURCE`、栈保护默认级别提升),对预编译二进制blob(常见于Qualcomm modem/DSP相关专有组件)的兼容性冲击最大。已核实两侧distro层`SECURITY_CFLAGS`/`SECURITY_STACK_PROTECTOR`/`_FORTIFY_SOURCE`默认逻辑逐字节相同(`security_flags.inc`对比),风险不来自Yocto策略变化而是glibc/gcc版本实现本身;QLI1.0侧`meta-qti-distro/conf/distro/include/security_flags.inc`已有一份现成的高风险组件清单(对上游默认加固做了大量按包覆盖),明确命名了`pn-npu`/`pn-ebtables`(remove `_FORTIFY_SOURCE=2`)、`pn-audiohal`/`pn-setools`(移除format-security检查)、`gps-utils`/`loc-hal`/`loc-core`/`bt-app`/`libbt-vendor`/`media`/`lib32-qmmf-sdk`等一长串改用`SECURITY_PIC_CFLAGS`的组件,证明"预编译二进制对安全加固默认值敏感"在QLI1.0是真实发生过的问题,这些组件迁移到QLI2.0时必须在gcc15/glibc2.43下重新验证而非直接照搬旧覆盖列表。已用grep在QLI2.0全部层核实这份清单里的Qualcomm专有组件(`npu`/`audiohal`/`gps-utils`/`loc-hal`/`loc-core`/`bt-app`/`libbt-vendor`/`qmmf-sdk`)目前**一个都不存在**(零recipe命中,唯一的字面命中是`meta-openembedded`的通用`gpsd`包自带同名`gps-utils`子包,与Qualcomm定位服务无关);`ebtables`/`setools`确实存在,但分别是`meta-networking`/`meta-selinux`的通用上游包,不是QLI1.0那个带专有覆盖的版本。即验证工作目前"无对象可测",风险是潜在的、跟随迁移动作出现,不是当前QLI2.0构建里已经存在的问题。
- QLI2.0新增picolibc支持是能力面扩展(面向更轻量/裸机目标),对现有以glibc为主的产品线没有直接影响,但如果后续有MCU/安全隔离子系统类需求,可以复用此新增能力。
- Rust版本从1.75到1.94.1跨度很大,如果有基于Rust的专有组件(如部分安全/加密模块),需要重新验证crate依赖兼容性和`cargo-bitbake`生成的lockfile是否需要重新生成。

这两项均为"是否迁移私有内核栈/专有组件到QLI2.0"这一路线图决策的下游工作,源码侧已查清技术现状(见上"影响与风险"),决策项已归入README《待拍板事项汇总》,此处不再重复列待确认。

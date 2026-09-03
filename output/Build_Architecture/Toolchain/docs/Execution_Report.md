# Toolchain 规则执行逻辑细节报告

本文档记录`Toolchain.md`当前结论的取证过程,重点复盘"clang使用范围"这一纠错——按`rules/Build_Architecture/Toolchain.md`"专属取证要点"逐条复盘。原理性背景见同目录`Principles.md`,具体差异结论见`../Toolchain.md`。

## 逐条取证过程

### 1. `TC_CXX_RUNTIME`/`PREFERRED_TOOLCHAIN`唯一赋值点与override扫描
**做法**:全文件类型限定搜索`TC_CXX_RUNTIME`赋值点,区分"唯一赋值"与"条件判断";`grep -rn PREFERRED_TOOLCHAIN`扫描全部machine/distro层(meta-qcom系列+meta-security/meta-updater/meta-virtualization/meta-selinux/meta-audioreach/meta-ros/meta-lts-mixins)。
**证据**:全树仅`bitbake.conf`一处赋值`TC_CXX_RUNTIME ??= "gnu"`,其余命中处均为条件表达式;`PREFERRED_TOOLCHAIN`扫描结果零override命中。
**落到结论**:对比总览表"meta-clang默认生效范围"行,用户态工具链纠正表第1行——确认不是仅凭"没搜到就下结论",是真实做过override扫描的空结果。

### 2. 内核构建强制clang范围的最初判断与纠正
**最初判断**:仅看`TC_CXX_RUNTIME`/`PREFERRED_TOOLCHAIN`默认值均为gnu/gcc,容易得出"clang在QLI1.0只是可选项,默认GCC"的结论,且这个结论看起来对整个工具链主题都成立。
**核实过程**:`grep KERNEL_CC.*clang`命中QLI1.0`linux-msm_5.4.bb`(sa410m/sa515m,显式`TOOLCHAIN="clang"`/`RUNTIME="llvm"`)、`linux-msm_5.10/5.15.bb`、`linux-msm_6.%.bb`、`linux-common_6.12.bb`、`linux-common-soc_6.18.bb`共9个recipe文件;进一步核实这些recipe覆盖的机型清单(pineapple/kalama/sun/mdm9607/cinder/qcm2290-mtp/qrb5165-rb5/trustedvm系列/seraph/pebble等)是QLI1.0现役主流机型,而非边缘配置。
**修正结论**:"clang只是可选项,默认GCC"这一判断**仅对用户态包成立**;内核构建层面QLI1.0现役主流机型实际**强制**走AOSP预编译clang(`kernel-toolchain_{5.10,5.15,6.%}.bb`原样打包`kernel_platform/prebuilts/clang/host/linux-x86/`下的谷歌AOSP预编译二进制,与meta-clang层完全无关,不依赖LLVM 18.1.6源码构建),这条路径体量远大于最初判断的"仅可选项"。该纠错已收录进README《曾纠正过的结论》表。
**落到结论**:《关键差异》第一条,用户态工具链纠正表第2、3行。

### 3. meta-clang层组织形式变化核实
**做法**:核对`oe-core/meta/recipes-devtools/clang/`recipe清单与`toolchain/clang.bbclass`,与QLI1.0`meta-clang`层同名recipe逐一对照。
**证据**:`clang_git.bb`/`llvm_git.bb`等recipe名几乎与QLI1.0`meta-clang/recipes-devtools/clang/`同名,逻辑高度一致。
**落到结论**:对比总览表"meta-clang独立层"行,《关键差异》第二条——组织形式变化(升级进oe-core主干),不是能力删除。

### 4. QLI2.0 clang override的实际使用面核实
**做法**:全层`grep -rln 'TOOLCHAIN[[:space:]]*=[[:space:]]*"clang"'`,命中`meta-openembedded/.../perfetto.bb`、`meta-ros/.../ogre-next_2.2.7.bb`两处;逐个核实是否真的进入镜像依赖链:①`grep -rl perfetto`在meta-qcom系列+meta-ros层查依赖方;②核对各`PREFERRED_VERSION_ogre-next`及distro yml实际选择的版本。
**证据**:`perfetto`全层零命中依赖方,不进入任何已知构建目标;`ogre-next`各ROS2 distro的`PREFERRED_VERSION`不同,而`meta-qcom-robotics-sdk`实际选的全部是`ros2-jazzy`(零处`ros2-humble`),对应`PREFERRED_VERSION`解析到不带clang override的`_2.3.3.bb`。
**落到结论**:用户态工具链纠正表"其他clang消费者"行——这两处override目前都不在QLI2.0任何已知镜像的实际依赖链里,不能算作"QLI2.0存在clang默认使用点"。

### 5. 安全加固基线对比
**做法**:`find -iname security_flags.inc`确认两侧文件数量差异,逐字节对比`SECURITY_CFLAGS`等默认逻辑,再grep核实QLI1.0清单里的专有组件名在QLI2.0的存在情况。
**证据**:QLI1.0侧5份`security_flags.inc`(含4份自定义覆盖),QLI2.0仅1份oe-core默认;QLI1.0专有组件清单(npu/audiohal/gps-utils/loc-hal/loc-core/bt-app/libbt-vendor/qmmf-sdk)在QLI2.0全树零命中(唯一字面命中`gpsd`通用包的`gps-utils`子包,与Qualcomm定位服务无关)。
**落到结论**:《影响与风险》"验证工作目前无对象可测,风险是潜在的、跟随迁移动作出现"结论。

### 6. Yocto迁移指南交叉核实
**做法**:读取`reference/System_Architecture/Yocto/Migration notes for 6.0 (wrynose)`存档页面breaking change清单。
**证据**:清单不包含GCC/glibc/binutils版本号本身的breaking change条目。
**落到结论**:《影响与风险》"工具链版本提升属于oe-core逐release的recipe版本迭代,不是Yocto发布流程强制的迁移动作"结论。

## 纠错记录汇总

本主题核心纠错是第2条"内核构建强制clang范围"——初步判断"clang仅是可选项"覆盖范围过大,实际只对用户态包成立;内核构建层面现役主流机型强制使用clang,是完全独立于meta-clang层的另一条路径。该纠错已写入产出文档《关键差异》并收录进README《曾纠正过的结论》表,不是静默覆盖。

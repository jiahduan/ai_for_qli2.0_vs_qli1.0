# System Architecture — RT

## 对比范围

- **覆盖**:本文比较双侧对PREEMPT_RT实时内核的接线/启用/运行时调优状况,按取证要点分组列出双侧锚点:
  - RT内核独立recipe存在性与接线状态:
    - downstream(maili):`poky/meta/recipes-kernel/linux/linux-yocto-rt_6.6.bb`(上游样板,未被任何bb/machine接线,`rt-tests`同样未接线)
    - QLI2.0:`meta-qcom/recipes-kernel/linux/linux-qcom-rt_6.18.bb`(`require linux-qcom_6.18.bb`)、`meta-qcom/recipes-kernel/linux/linux-qcom-next-rt_git.bb`
  - CONFIG_PREEMPT_RT实际赋值核查:
    - downstream(maili):`arch/arm64/configs/{defconfig,gki_defconfig,*.fragment}`及各`build.config`全量grep、`poky/meta-qti-distro`全目录(含`qti-distro-camerastack-debug.conf`及其include链);本次进一步核实pebble机型对应真实生成的构建产物`kernel_platform/temp_out_dir/super_kernel/.config.old`第120行`# CONFIG_PREEMPT_RT is not set`(`kernel_platform/temp_out_dir/soc-repo/.config`同一行同样命中),不再只停留在源码定义文件层面的grep
    - QLI2.0:`linux-qcom-rt_6.18.bb`里`KBUILD_CONFIG_EXTRA:append:aarch64`引用的`arch/arm64/configs/rt.config`(`CONFIG_EXPERT=y`/`CONFIG_PREEMPT_RT=y`),已在构建产物`build/tmp/work-shared/iq-9075-evk/kernel-source/arch/arm64/configs/rt.config`验证真实合并进`.config`;本次进一步核实iq-9075-evk本地实际默认构建走`linux-qcom`(非RT)provider,其构建产物`build/tmp/work/iq_9075_evk-qcom-linux/linux-qcom/6.18.30/build/.config`实测`# CONFIG_PREEMPT_RT is not set`,反向印证默认provider下RT确实关闭
  - RT运行时调优cmdline框架:`meta-qcom/conf/machine/include/qcom-common.inc`(`QCOM_RT_CPU`/`QCOM_IRQAFF`/`QCOM_RCU_NOCBS`/`QCOM_RCU_EXPEDITED`/`QCOM_CPUIDLE_OFF`五个变量拼装为`isolcpus`/`irqaffinity`/`rcu_nocbs`/`rcupdate.rcu_expedited`/`cpuidle.off`cmdline参数),downstream(maili)侧无对应机制
  - 已赋实值机型清单核对:逐一核对`meta-qcom`全部19个machine conf(含`require`链)的`QCOM_RT_CPU`赋值,统计出≥9个已赋值机型(IQ工控评估板/机器人核心套件族)及2个同族未赋值机型(`iq-x5121-evk`、`rb1-core-kit`/`qrb2210-rb1-core-kit`)
  - CI验证矩阵:`meta-qcom/ci/linux-qcom-rt-6.18.yml`、`linux-qcom-next-rt.yml`(`meta-qcom-robotics-sdk`/`meta-qcom-distro`下同名副本);本次进一步核实`meta-qcom-distro/.github/workflows/build-yocto.yml`第191-198行给`iq-9075-evk`额外配置了仅此机型独有的`qcom-next-rt`CI entry(其他机型只有标准`rt-6.18`entry),是官方CI矩阵里被特别对待的RT旗舰验证机型
  - DISTRO_FEATURES`rt`标志与默认kernel provider:全树grep`rt`相关DISTRO_FEATURES(未发现),`qcom-armv8a.conf`默认`PREFERRED_PROVIDER_virtual/kernel`仍为`linux-yocto`
  - 配套软件包:`qcom-minimal-image.bb`(RT provider下自动安装`rt-tests`)
  - downstream(maili)仓库外/私有构建是否曾启用PREEMPT_RT的历史边界核查:对`kernel_platform/soc-repo`(remote`quic/qcom-6.18`)与`kernel_platform/common`(remote`quic/keystone/android17-6.18-keystone-qcom-release`)两仓库跑`git log --all -p`对`arch/arm64/configs/*`做`CONFIG_PREEMPT_RT=y`全文匹配(135万+/141万+条commit可达),确认本地可见全部历史均零命中
- **明确排除**:
  - RT内核相对mainline/downstream(maili)内核的源码血统、仓库治理主体(commit标签体系、庭院多仓vs单一mainline-first等通用内核治理层面的对比,不含PREEMPT_RT本身) ——见[Kernel_Code_Architecture](../Kernel_Code_Architecture/Kernel_Code_Architecture.md)
- **待定边界**:(无,已核实:①与Kernel_Code_Architecture.md的边界——已重新核对该文档《对比范围》"覆盖"字段,确认其commit标签/仓库治理层分析不含PREEMPT_RT diff内容,故本文保留PREEMPT_RT补丁集具体代码改动/历史核查(已在本文"覆盖"字段完成,不排除出去),只排除通用内核治理部分,方向已修正一致;②与Bootargs.md的cmdline参数边界——`Bootargs.md`已反向引用本文作为RT cmdline参数的权威出处,方向一致无冲突;③Yocto.md/Overlay.md/Distro_Version.md/Audio.md均已grep确认未发现与RT主题重叠、本该属于本文却未提及的遗漏内容)

## 对比总览

| 维度 | downstream(maili) | QLI2.0 |
|---|---|---|
| RT内核独立recipe | 无(仅上游`linux-yocto-rt_6.6.bb`样板,`rt-tests`未接线) | 有:`linux-qcom-rt_6.18.bb`(`require linux-qcom_6.18.bb`)、`linux-qcom-next-rt_git.bb` |
| CONFIG_PREEMPT_RT实际赋值 | 遍历`arch/arm64/configs/{defconfig,gki_defconfig,*.fragment}`及各build.config均未发现`=y`;已扩展核查`poky/meta-qti-distro/`全目录(含`qti-distro-camerastack-debug.conf`及其include链)grep`CONFIG_PREEMPT_RT`/`rt-tests`,同样0命中 | `KBUILD_CONFIG_EXTRA:append:aarch64 = " ${S}/arch/arm64/configs/rt.config"`,内容`CONFIG_EXPERT=y`/`CONFIG_PREEMPT_RT=y`(已在`build/tmp/work-shared/iq-9075-evk/kernel-source/arch/arm64/configs/rt.config`验证真实合并进.config) |
| RT运行时调优框架 | 无 | `meta-qcom/conf/machine/include/qcom-common.inc`定义完整cmdline拼装:`QCOM_RT_CPU`→isolcpus、`QCOM_IRQAFF`→irqaffinity、`QCOM_RCU_NOCBS`→rcu_nocbs、`QCOM_RCU_EXPEDITED`→rcupdate.rcu_expedited、`QCOM_CPUIDLE_OFF`→cpuidle.off |
| 已赋实值机型 | 不适用 | ≥9个:qcs615-ride、iq-x7181-evk、qcm6490-idp、iq-9075-evk、iq-615-evk、iq-8275-evk、rb3gen2-core-kit、qcs8300-ride-sx、qcs9100-ride-sx |
| CI验证 | 无 | 独立CI矩阵:`ci/linux-qcom-rt-6.18.yml`、`linux-qcom-next-rt.yml` |
| DISTRO_FEATURES标志 | 未发现`rt`标志 | 未发现`rt`标志(RT通过kernel provider切换而非DISTRO_FEATURES实现) |
| 默认kernel provider | 不适用 | `qcom-armv8a.conf`仍为`linux-yocto`(非RT),RT需显式切换 |
| 配套软件包 | 无 | `qcom-minimal-image.bb`: RT provider下自动安装`rt-tests` |

## 关键差异

- downstream(maili)未启用/未提供任何面向生产的PREEMPT_RT内核路径;QLI2.0为工业/机器人场景(结合meta-qcom-robotics-sdk)预留了完整实时性演进路径,是能力新增而非架构对等替换。
- RT内核走`github.com/qualcomm-linux/kernel.git`社区导向仓库,与downstream(maili)基于Android common kernel的技术栈完全不同源(详见Kernel_Code_Architecture.md),两代内核补丁、驱动、DLKM机制不能直接复用对比,这是比RT本身更大的架构断层。
- `qcom-common.inc`第74行注释明确写"Default values (machines override these)",`QCOM_RT_*`一组变量默认值均为空字符串,机制上就是"默认不生效,按机型显式opt-in";已赋值的9个机型清一色是IQ工控评估板/机器人核心套件,与glymur-crd/kaanapali-mtp/sm8750-mtp等消费类评估板形成清晰产品定位分野,是刻意区分而非遗漏。

## 影响与风险

- RT是通过切换`PREFERRED_PROVIDER_virtual/kernel`实现的"平行内核",带来双内核树维护成本(linux-qcom与linux-qcom-rt分别对应上游qcom-6.18.y分支与rt.config叠加),需评估两套内核补丁同步/安全更新节奏是否一致。
- `QCOM_RT_*`参数目前只在部分机型(IQ系列/工控评估板)配置,其余机型仍为空字符串,若RT特性被下游客户依赖,需明确"哪些SKU官方承诺支持RT"。已逐一核对`meta-qcom`全部19个machine conf(`meta-qcom-robotics-sdk`本身不含machine conf,只挂在`meta-qcom`机型上):同属"IQ工控评估板"命名族的`iq-x5121-evk`(Purwa IoT EVK)、同属"机器人核心套件"命名族的`rb1-core-kit`/`qrb2210-rb1-core-kit`(QRB2210/QCM2290)均未设置`QCOM_RT_CPU`(其`require`链`qcom-purwa.inc`/`qcom-qcm2290.inc`里也没有),与已覆盖的`iq-615-evk`/`iq-8275-evk`/`iq-9075-evk`/`iq-x7181-evk`/`rb3gen2-core-kit`同族但状态不同,是本次可确认的两个具体缺口(`*-open-fw`及`qcs6490-rb3gen2-core-kit`等变体因`require`已覆盖的机型conf而继承了RT参数,不算缺口)。需注意:"未设置`QCOM_RT_*`cmdline调优变量"与"内核层面无法启用`CONFIG_PREEMPT_RT`"是两个不同维度——`linux-qcom-rt_6.18.bb`的`COMPATIBLE_MACHINE = "(qcom)"`门槛覆盖全部meta-qcom机型,不区分机型族;已实测确认`meta-qcom/.github/workflows/build-yocto.yml`第221-338行的官方CI矩阵里`iq-x5121-evk`同样被排入`rt-6.18-distro-kvm`(`ci/linux-qcom-rt-6.18.yml`+`ci/qcom-distro-kvm.yml`)kernel交叉编译组合,`exclude`列表(第266-297行)未将其排除——即该机型理论上仍可编译出`CONFIG_PREEMPT_RT=y`的内核,上述"两个具体缺口"specifically指的是`isolcpus`/`irqaffinity`等cmdline级CPU隔离/IRQ亲和性调优缺失,不是内核RT能力被机型门槛整体拒绝。

## 待确认

- **downstream(maili)在仓库外分支/私有构建是否启用过PREEMPT_RT**——本仓库可见的所有downstream(maili)构建路径均未发现PREEMPT_RT相关配置:`arch/arm64/configs`全部defconfig/fragment/build.config、`meta-qti-distro`全目录(含`qti-distro-camerastack-debug.conf`及其include链)grep`CONFIG_PREEMPT_RT`/`rt-tests`均0命中;本次进一步核查了`pebble`机型实际构建产物`build-qti-distro-camerastack-debug/tmp-glibc/work/pebble-oe-linux/linux-common-soc`(该机型走独立`soc-repo`内核源,与`common`不同源码树),同样0命中,`src/`全目录里能grep到的`PREEMPT_RT`字样均是mainline标准代码里的`#ifdef CONFIG_PREEMPT_RT`条件分支或测试脚本引用,不是配置项被置`=y`。本次进一步对`kernel_platform/soc-repo`(remote`quic/qcom-6.18`)和`kernel_platform/common`(remote`quic/keystone/android17-6.18-keystone-qcom-release`)两个仓库各自本地可见的全部历史(`git log --all -p`,分别135万+/141万+条commit可达)里`arch/arm64/configs/*`路径做`CONFIG_PREEMPT_RT=y`全文匹配,均0命中——即不仅当前checkout,这两个仓库本地镜像到的分支在其全部历史版本里也从未在defconfig里置过这一项。但每个仓库本地只镶了1条远程分支(soc-repo只有`quic/qcom-6.18`,common只有`quic/keystone/android17-6.18-keystone-qcom-release`),代码侧线索已用尽,仍无法排除仓库外其他分支或私有构建启用过该特性,需向downstream(maili)内核/BSP团队做最后确认。

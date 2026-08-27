# System Architecture — Kernel Code Architecture

## 对比范围

- **覆盖**:本文比较QLI1.0/QLI2.0两代内核源码本身的仓库治理模式、版本与获取机制、GKI vendor-hook基建存废、commit标签体系与定制承载方式,以及基于git历史/文件级diff的同源性判断;不判断具体驱动功能是否达标(那部分留给各子系统文档)。按以下几组列出双侧锚点:
  - 版本与源码获取机制:
    - QLI1.0:`src/kernel-6.18/kernel_platform/common/Makefile`(VERSION/PATCHLEVEL/SUBLEVEL=6.18.21)、`.repo/manifests/*.xml`(`AU_LINUX_KERNEL.PLATFORM.6.0.00.00.00.178.129`标签)、`KERNEL_PLATFORM_PATH`+`SRC_URI file://`整树拷贝机制(`poky/meta-qti-bsp*/recipes-kernel/linux-msm/linux-common-soc_6.18.bb`)
    - QLI2.0:`meta-qcom/recipes-kernel/linux/linux-qcom_6.18.bb`(`LINUX_VERSION=6.18.30`,`SRCREV=5086fd78561b...`,`tag=qcom-6.18.y-20260615.1`,本次核实HEAD commit与SRCREV/tag三者完全一致)、`linux-qcom-rt_6.18.bb`、`linux-qcom-next_git.bb`;本次新核实到第4个provider recipe`linux-qcom-next-rt_git.bb`(`require linux-qcom-next_git.bb`叠加RT config,原文归纳"三者分工"时未点出这一个,是next线的RT变体而非独立第4条lineage)
  - 仓库治理与源码组织("庭院式多仓" vs 单一仓库):
    - QLI1.0:`kernel_platform/common`(ACK,remote`quic`的`kernel/common`)、`kernel_platform/soc-repo`(remote`quic`的`kernel/qcom`,含`ack2soc.sh`合并脚本)、`kernel_platform/common-modules`(`trusty`/`virtio-media`/`wonder`三个树外GKI模块)、`kernel_platform/devices/google`(Pixel参考设备`raviole`,独立git)、`kernel_platform/external`(Bazel/Kleaf及`boringssl`等构建支撑库)
    - 本次新核实到的第5个庭院仓库:`kernel_platform/qcom/opensource/devicetree`(独立git,remote`quic`的`platform/vendor/qcom-opensource/devicetree`,6726个dts文件,已核实被`poky/meta-qti-bsp*/recipes-kernel/linux-msm/linux-common-soc_6.18.bb`的`SRC_URI file://qcom/opensource/devicetree`真实引用,非死配置)
    - QLI2.0:`build/downloads/git2/github.com.qualcomm-linux.kernel.git`(完整历史镜像,单一仓库)、`build/tmp/work-shared/iq-9075-evk/kernel-source`(已checkout工作树)
  - Android GKI vendor-hook基建存废:`kernel/sched/core.c`两侧钩子对比(QLI1.0:46处`android_vh_`/`android_rvh_`/`trace_android`,319379字节;QLI2.0:0处,290393字节;本次重新grep,两个数字均精确复现)
  - commit标签体系与定制承载方式:QLI1.0`ANDROID:`/`UPSTREAM:`/`Snap for <bug>...`风格 vs QLI2.0`FROMLIST:`/`BACKPORT:`/`QCLINUX:`/`PENDING:`/`WORKAROUND:`标签抽样统计(本次对`qcom-6.18.y-20260615.1`标签重新跑近3000条抽样复核,五个标签量级排序与原文一致,具体条数存在抽样窗口带来的正常波动)
  - 高度上游化驱动逐文件同源性验证:`drivers/soc/qcom/socinfo.c`(两侧857/862行,本次复核QLI1侧行数精确匹配)、`pmic_glink.c`(三方diff mainline`v6.18.21`)
  - commit集合级同源性(按目录做subject集合diff,含"补入soc-repo前后复核"纠错记录):`drivers/soc/qcom/`、`drivers/gpu/drm/msm/`、`arch/arm64/boot/dts/qcom/`、`drivers/media/platform/qcom/`、`drivers/remoteproc/qcom_*`、`drivers/power/supply/qcom_*`、`drivers/thermal/qcom*`、`kernel/sched/`——这一层是commit元数据层面的同源统计,不涉及驱动功能是否达标
  - SoC新增驱动的仓库承载位置(非编译机制本身):QLI1.0独立soc-repo覆盖层 vs QLI2.0直接commit进`kernel.git`(如`drivers/soc/qcom/qmi-cooling.c`)
  - mmrm多媒体资源管理器全链路缺口核实:`git log --all -i --grep=mmrm`跨全部bitbake层及QLI2.0内核完整git历史,零命中
- **明确排除**:
  - WLAN/BT具体内核驱动(ath10k/ath11k/ath12k/QCACLD等)的功能与承接细节 ——见[WiFi_BT](WiFi_BT.md)
  - Camera ISP内核驱动(CAMSS/camx-dlkm)的功能与承接细节 ——见[Camera](Camera.md)
  - GPU内核驱动(kgsl)的功能与承接细节 ——见[Graphics](Graphics.md)
  - Display侧drm/msm内核驱动与合成能力细节 ——见[Display](Display.md)
  - Audio内核驱动(audiodlkm/audioreach-kernel)细节 ——见[Audio](Audio.md)
  - SELinux/内核安全策略、dm-verity/AVB等内核完整性校验机制 ——见[Security_Architecture](Security_Architecture.md)
  - 内核外置模块(-dlkm)编译框架、`inherit linux-kernel-base`/`inherit module`机制、模块黑名单、dts/dtb具体编译任务(`do_compile_dtb`/`dtb-fit-image.bbclass`)、Yocto层内核补丁数量统计口径 ——见[Kernel_Build](../Build_Architecture/Kernel_Build.md)
  - 内核补丁全量统计口径与纠错(src/ vs poky/层补丁总数、真实补丁总量) ——见[Patch_Management](../Code_Composition/Patch_Management.md)
  - clang工具链在内核构建中的强制依赖关系 ——见[Toolchain](../Build_Architecture/Toolchain.md)
- **待定边界**:(无,已核实两处易混淆边界均不需挪动:①`drivers/gpu/drm/msm`的commit集合diff属本文commit元数据层面的同源统计,与Graphics.md/Display.md的驱动功能级分析是不同角度,不重叠;②`kernel_platform/qcom/opensource/devicetree`经核实是本文"源码组织"覆盖范围内的真实庭院仓库、非死配置,已并入"覆盖"字段,不构成待定)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 内核版本 | 6.18.21(`src/kernel-6.18/kernel_platform/common/Makefile`: VERSION=6 PATCHLEVEL=18 SUBLEVEL=21) | 6.18.30(`linux-qcom_6.18.bb`: `LINUX_VERSION="6.18.30"`,SRCREV=`5086fd78561b1a8824806decd2e9bf2cfe3d6f`,tag`qcom-6.18.y-20260615.1`) |
| 源码来源 | Qualcomm内部repo manifest管理的`kernel_platform`大树(`.repo/manifests/.../manifest.xml`: `project="kernelplatform/manifest" tag="AU_LINUX_KERNEL.PLATFORM.6.0.00.00.00.178.129"`) | `git://github.com/qualcomm-linux/kernel.git`,标准`inherit kernel cml1` |
| 引用机制 | `SRC_URI file://`整树本地拷贝,`KERNEL_PLATFORM_PATH`指向工程根`src/`目录,非externalsrc非git fetch | `SRC_URI git://...;SRCREV=...`,bitbake原生fetcher管理 |
| 源码组织 | "庭院式多仓":`common/`(ACK)、`soc-repo/`(SoC覆盖层,独立git project,含ack2soc等合并脚本)、`common-modules/`(树外GKI模块:trusty/virtio-media/wonder)、`devices/google/`、`external/`(Bazel/Kleaf支持库) | 单一仓库,SoC定制直接commit进kernel.git |
| 仓库治理主体 | Google Android Common Kernel(ACK)/GKI,remote=`git-android-sha-drekar.quicinc.com`,内部Gerrit评审 | Qualcomm官方GitHub,`qcom-6.18.y`分支 |
| 分支/commit风格 | detached HEAD追踪`remotes/quic/keystone/android17-6.18-keystone-qcom-release`;commit风格`ANDROID: GKI: ...`、`UPSTREAM: sched: ...`、`Snap for <bug> from <sha> to android17-6.18-keystone-qcom-release` | HEAD commit `5086fd78561b`("QCLINUX: arm64: dts: qcom: talos: Add GMSL deserializer and sensor"),与SRCREV完全一致 |
| commit标签统计(抽样近3000条) | `ANDROID:`、`UPSTREAM:`为主 | `FROMLIST:`488条(已投LKML待合并)、`BACKPORT:`102条、`QCLINUX:`41条(下游专有未上游化)、`PENDING:`32条、`WORKAROUND:`11条 |
| GKI vendor-hook基建 | `kernel/sched/core.c`319379字节,含46处`android_vh_/android_rvh_/trace_android`钩子,含`sched_proxy_exec`sysfs开关等GKI ABI稳定性基建 | 对应文件290393字节,0处上述钩子,更贴近纯净mainline |
| 高度上游化驱动对比 | `drivers/soc/qcom/socinfo.c` 857行 | 同文件862行,仅5行插入,版权头逐字一致 |
| SoC新增驱动位置 | 独立soc-repo仓库覆盖 | 直接commit进kernel.git(如新增`drivers/soc/qcom/qmi-cooling.c/.h`) |
| 产品机型kernel provider | `linux-msm`/`linux-common-soc`(私有大树,`linux-common-soc_6.18.bb`) | `linux-qcom`(`qcom-base.inc`用`?=`强设),`linux-yocto`+kmeta仅服务`qcom-armv8a`/`qcom-armv7a`上游参考机型(msm8916/sdm845/sm8250等) |
| dts/defconfig组织 | 自定义`TARGET_DTBS`/`PEBBLE_BASE_DT`/`PEBBLE_OVERLAY`,defconfig来自`KERNEL_SRC_TYPE="soc-repo"`路径,脱离Yocto标准kernel-devicetree机制 | 标准`KERNEL_DEVICETREE`变量+`linux-qcom-dtbbin.bbclass` |
| 是否用kmeta | 未使用 | 名义引入(`linux-yocto-6.18/bsp/qcom-armv8a/*.scc|*.cfg`),但仅绑定非产品参考机型 |
| 本地已fetch的可核查路径 | `src/kernel-6.18/kernel_platform/common`(真实git仓库,`.git`软链接指向`.repo/projects/.../common.git`) | `build/downloads/git2/github.com.qualcomm-linux.kernel.git`(完整历史镜像)、`build/tmp/work-shared/iq-9075-evk/kernel-source`(已checkout工作树) |

## 同源性结论(基于git历史+文件级diff双重证据)

- **最底层(mainline Linux+上游QCOM驱动)**:同源,置信度高——socinfo.c几乎逐字相同,6.18.21/6.18.30同处一条stable tag序列(镶像仓库历史检出`Merge tag 'v6.18.21' into qcom-6.18.y`与`Merge tag 'v6.18.30' into qcom-6.18.y`)。
- **中间层(是否叠加Android GKI vendor-hook)**:分叉,置信度高——sched/core.c的46处钩子在QLI2.0侧完全消失,是架构性治理决策,不是随机代码腐化。
- **仓库治理层**:完全独立——QLI1.0=Google ACK(quicinc Gerrit)+soc-repo"庭院多仓"模式;QLI2.0=Qualcomm官方GitHub单一"mainline-first"仓库,commit标签体系完全不同(QCLINUX/FROMLIST/BACKPORT/WORKAROUND vs ANDROID/UPSTREAM/Snap),两侧commit历史无一条可直接对应,未发现共享commit hash或cherry-picked from标记。
- **架构重构判断**:"从多仓庭院式结构合并为单一kernel.git"的判断成立且已被直接证据证实,是一次真实的架构重构,不是简单的版本号升级。
- 交叉检索排除误判:QLI2.0镜像中检出的`ANDROID:`(24条)/`UPSTREAM:`(400条)均是mainline历史遗留通用commit,非指向QLI1.0分支;"keystone"关键词命中的662条均为TI Keystone SoC相关,与Android品牌分支同名不同物。
- commit集合级同源验证(按subject做集合diff,而非整树diff行数):`drivers/soc/qcom/`(QLI1侧986条唯一subject、QLI2侧1031条)、`drivers/gpu/drm/msm/`(4564/4704条)两个关键SoC目录,QLI1侧唯一commit均为0——即QLI1在这两个目录里的每一条commit,subject都能在QLI2侧原样找到,QLI2另外领先45条(soc/qcom)、140条(gpu/drm/msm);扩展到`arch/arm64/boot/dts/qcom/`(QLI2领先548条)、`drivers/media/platform/qcom/`(领先128条)、`drivers/remoteproc/qcom_*`(领先16条)后同一模式重复出现,`drivers/power/supply/qcom_*`与`drivers/thermal/qcom*`两侧完全打平(0差异)。唯一反过来的桶是`kernel/sched/`:QLI1独有705条(即Android vendor-hook基建那部分),QLI2独有仅9条。这组commit集合证据从另一个维度坐实"最底层同源、仅vendor-hook层分叉"的结论。
- **补入soc-repo后的复核(原待确认项已解决)**:上一条统计只用了QLI1.0的`common`仓库,`kernel_platform/soc-repo`(独立git仓库,HEAD `61351abdf37b`,`ack2soc.sh`合并脚本的目标仓库)未纳入。补入soc-repo重新做同一方法的subject集合diff(QLI2侧统一用`github.com/qualcomm-linux/kernel.git`的`qcom-6.18.y`分支):`drivers/gpu/drm/msm/`(common+soc-repo合并去重4574条唯一subject)QLI1独有仅10条,`arch/arm64/boot/dts/qcom/`(6115条)QLI1独有仅3条,`drivers/media/platform/qcom/`(906条)QLI1独有仅1条——这三个目录"几乎全部被QLI2覆盖"的结论不变。但`drivers/soc/qcom/`(合并去重2546条)QLI1独有条数从0跳到1560条,`drivers/power/supply/`(1984条)从0跳到139条,`drivers/thermal/`(3345条)从0跳到214条,`drivers/remoteproc/`(1544条)从16条跳到326条——此前"两侧完全打平"的结论在这四个目录不成立,soc-repo带来了common仓库里完全没有的大量独立改动。放宽到不限qcom子目录的全量`drivers/soc`(5755条唯一subject)、`drivers/gpu`(112390条),QLI1独有分别是1563条、759条(gpu占比不到1%,方向与drm/msm子目录一致)。结论:soc-repo确实是此前统计的主要盲区,纳入后"最底层同源"对gpu/drm/msm、dts、media三个目录仍站得住,但对soc/qcom、power、thermal、remoteproc四个目录需要修正为"存在数量可观的QLI1独有改动"。方法仍是commit subject文本粗粒度匹配而非逐patch内容比对,不排除同义改写导致的漏配对,但方向性结论足够清楚。
- 三方(mainline)抽样验证:mainline的`6.18.21`/`6.18.30`点版本tag实际发布于`github.com/gregkh/linux`(stable树镜像),`torvalds/linux`只有`v6.18`大版本tag没有`.y`点版本;拉取`v6.18.21`后对`drivers/soc/qcom/socinfo.c`、`drivers/soc/qcom/pmic_glink.c`做三方diff:QLI1侧与mainline逐字节相同(diff 0行,即这两个文件在QLI1侧是未经改动的纯净mainline快照),QLI2侧分别有7行/77行增量(pmic_glink.c的增量对应前述FROMGIT的SOCCP remoteproc通道支持)。**抽样声明**:这两个文件是从`drivers/soc/qcom/`目录里挑出来的,选取理由是它们在前一条commit集合diff里分别代表"QLI1/QLI2改动量都极小、接近同源基线"与"QLI2侧有可辨认FROMGIT增量"两种典型情况,不是随机抽样;`drivers/soc/qcom/`合并soc-repo后有2546条唯一commit subject,逐文件三方diff在这个规模上不可行,本条结论只能证明"这两个具体文件的同源/分叉情况",不能外推为`drivers/soc/qcom/`整个目录甚至整个内核的同源比例——目录级的同源程度判断以上一条commit subject集合diff为准,该方法本身"文本粗粒度匹配、不排除同义改写漏配对"的局限已在上一条注明。

## 关键差异

- 内核代码血统本身是分层的,不能用一句"同源"或"分叉"概括:最底层mainline+上游QCOM驱动同源(socinfo.c几乎逐字节相同、6.18.21/6.18.30同处一条stable序列),中间的Android GKI vendor-hook治理层完全分叉(46处钩子在QLI2.0侧清零),仓库治理主体也完全独立(Google ACK Gerrit庭院多仓 vs Qualcomm官方GitHub单一仓库);下游如果需要判断"某个具体改动能不能复用",必须先定位它属于哪一层,笼统套用任一层的结论都会出错。
- 补入soc-repo前后的对比说明"最底层同源"这个结论对不同子系统目录的成立程度并不均匀:gpu/drm/msm、dts、media三个目录在补入soc-repo后仍然是"QLI1几乎被QLI2完全覆盖"(独有条数个位数),但soc/qcom、power、thermal、remoteproc四个目录在只看common仓库时显示"完全打平",补入soc-repo后暴露出成百上千条QLI1独有改动——即"两代内核同源度高"不是一个可以整体外推的结论,必须按子系统分别核实,且核实范围必须覆盖QLI1.0的全部代码来源(common+soc-repo),只看主仓库容易得出过于乐观的同源判断。
- FROMLIST/BACKPORT/QCLINUX/PENDING/WORKAROUND标签体系的引入,叠加"仓库治理从庭院多仓转为单一mainline-first仓库"的事实,说明QLI2.0把原本需要靠Yocto层patch或树内私有DLKM实现的定制,尽量往"先投上游、走内核commit"方向收敛(FROMLIST占比最高达488条)——这直接改变了下游审计方法:追踪某项QCOM定制改动不能再只看Yocto层patch目录(output/Code_Composition/Patch_Management.md已确认Yocto层内核补丁仅剩个位数),必须去看内核git log的标签和commit历史。
- "mainline-first"不是零成本的架构简化:量产机型(`linux-qcom`)与官方参考机型(`linux-yocto`+kmeta,仅服务`qcom-armv8a`/`qcom-armv7a`)对同款硬件(如hamoa/monaco)维护着两条独立的DTS overlay,是有意设计而非疏漏,但意味着一部分原本靠"Yocto层补丁管理"承担的维护复杂度,现在转移成了"多套recipe/kmeta体系并行维护"的成本,并没有消失。

## 影响与风险

- QLI1.0整套`kernel_platform`与Yocto生态(fetcher/SRCREV/sstate)脱节,sstate缓存对内核改动增量判定弱(file://整体拷贝,粒度粗)。
- QLI2.0标准git recipe可获得原生SRCREV追踪、sstate复用、`devtool modify`等能力,升级降级只需改版本号;但存在双轨制现象——`linux-yocto_6.18.bbappend`挂的DTS patch只对`qcom-armv8a`/`qcom-armv7a`两台"上游参考机型"生效(受`COMPATIBLE_MACHINE`限定),量产机型(如`iq-x7181-evk`/`iq-8275-evk`)走`linux-qcom`不受影响;已确认这是"mainline-first参考机型复现同款硬件(hamoa/monaco)"的有意设计而非死配置,但同一款硬件在QLI2.0里事实上存在两条独立维护的DTS overlay,仍是需要留意的双份维护成本。
- 每个驱动独立SRCREV,升级内核大版本时兼容性验证工作量分散到各独立仓库,相较QLI1.0"内核+驱动同一树整体升级"的强一致性,需建立跨仓库兼容性矩阵/CI门禁。
- `linux-qcom_6.18.bb`(release)/`linux-qcom-rt_6.18.bb`(RT)/`linux-qcom-next_git.bb`(next预览)三者分工清晰:RT变体靠`require`继承release分支SRCREV,不存在同步风险;`next`独立pin更新的SRCREV(`qcom-next-7.1-rc7`),定位类似mainline linux-next的预集成通道。已核实`linux-qcom_6.18.bb`对全部meta-qcom机型使用同一条`COMPATIBLE_MACHINE="(qcom)"`规则和同一SRCREV,不存在per-machine单独钉版本的情况,`iq-9075-evk`已checkout的工作树可代表全部量产机型的内核主干基线。
- 8个QLI1.0`inherit linux-kernel-base`vendor驱动recipe逐项核实承接情况:`video-kernel`已由`meta-qcom/recipes-kernel/iris-video-module`承接(venus→iris改名延续);`dsp-devicetree`/adsprpc已上游化内建进`linux-qcom`内核树(`CONFIG_QCOM_FASTRPC=m`),不需要单独recipe;`gki-kernel-modules`因QLI2.0不采用GKI架构而不适用;仅`mmrm-kernel`/`mmrm-devicetree`(多媒体资源管理器)在`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`/`meta-audioreach`/`meta-ros`/`meta-openembedded`/`oe-core`全部bitbake层及QLI2.0内核完整git历史(`git log --all -i --grep=mmrm`)均0命中(唯一字符串命中是AMD GPU寄存器命名`gc_*_offset.h`里的`mmRM...`巧合子串,与多媒体资源管理器无关),代码侧线索已用尽,确认是真实功能缺口而非尚未搜索到。
- 与output/Build_Architecture/Toolchain.md联动:QLI1.0现役机型内核构建强制依赖AOSP预编译clang,QLI2.0无对应体系。

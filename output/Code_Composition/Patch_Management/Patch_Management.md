# Code Composition — Patch Management

## 对比范围

- **覆盖**:
  - 补丁总量统计与两次二次订正:本次重新逐项执行`find <目录> -iname "*.patch" | wc -l`,全部计数与现有正文完全一致——QLI1.0`poky/`4,858、`src/`5,083(其中`src/kernel-6.18/kernel_platform`第三方vendored噪声5,080:`bazelbuild-bazel-central-registry`4,890/`rust`156/`zlib`19/`bazelbuild-rules_rust`5/`bazelbuild-rules_python`4/`u-boot/tools`patman fixture 3/`elfutils`1/`bazel-skylib`1/`bazelbuild-rules_cc`1,合计5,080;真实v4l-utils补丁3个)、`disregard/`废弃备份38、`build-qti-distro-camerastack-debug`构建残留554、`poky/meta-qti-bsp*/recipes-kernel/`真实内核补丁6(逐文件核实文件名一致);QLI2.0按11个repo精确统计(`meta-openembedded`2,416/`meta-ros`1,044/`oe-core`1,116/`meta-virtualization`121/`meta-security`90/`meta-selinux`77/`meta-qcom`61/`meta-qcom-robotics-sdk`43/`meta-qcom-distro`18/`meta-updater`8/`meta-audioreach`1,合计4,995)
  - kas`patches:`声明式跨仓补丁机制本身(字段语义、消费方patches目录物理存放方式、`kas checkout`阶段应用时机),不含其产生的`patched-<sha>`分支状态
  - Systemd补丁去向追踪(3例patch fate对照:`Disable-unused-mount-points.patch`/`fstab-generator-Honor-verity-enabled-cmdline.patch`/`sd-bus-Allow-extra-users-to-communicate.patch`),不含dm-verity/AVB/私有uid体系等架构本体解读
  - 内核补丁抽样(`poky/meta-qti-bsp*/recipes-kernel/`6个补丁逐个核对+QLI2.0侧对应1个构建脚本补丁,及内核commit`FROMLIST:`/`BACKPORT:`/`QCLINUX:`/`PENDING:`/`WORKAROUND:`标签频次抽样统计,约3000条样本)
  - `meta-qti-gst`层patch密度抽样(重新核实144个补丁总数一致,按recipe分布:`gstreamer1.0-plugins-good`60/`plugins-bad`29/`plugins-base`26/`gstreamer1.0-omx`11/`qti-patches`8/`gstreamer1.0-libav`3/核心4/`gstd`2/`gstreamer-vaapi`1)与gstreamer1.0-plugins-base 6补丁个案比对、QLI2.0侧`meta-qcom/recipes-multimedia/gstreamer/`3个bbappend共13补丁(重新核实两侧数字均一致)
  - 补丁治理工具存在性(`meta-qcom-robotics-sdk/ci/yocto-patchreview.sh`)
- **明确排除**:
  - kas`patches:`机制产生的`patched-<sha>`临时分支命名与状态 ——见[Branch_Management](../Branch_Management/Branch_Management.md)
  - systemd补丁涉及的securityfs等挂载机制架构解读 ——见[systemd](../../Boot_Architecture/systemd_/systemd_.md)
- **待定边界**:(无,已核实——本次重新执行全部计数命令[poky/src/disregard/build-qti-*四类、QLI2.0按11个repo统计、`meta-qti-bsp*`内核补丁6个、`meta-qti-gst`及子recipe分布、QLI2.0侧gstreamer bbappend补丁数],数字与现有正文完全一致,未发现新的统计口径缺口或遗漏目录)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 补丁总量(纠正前统计) | 10,533个(`find <dir> -iname "*.patch" \| wc -l`逐项核实:poky/ 4,858;src/ 5,083;build-qti-*工作目录残留554;`disregard/`废弃备份layer残留38;4,858+5,083+554+38=10,533) | 4,995个(meta-openembedded/ 2,416;meta-ros/ 1,044;oe-core/ 1,116;meta-virtualization/ 121;meta-security/ 90;meta-selinux/ 77;meta-qcom/ 61;meta-qcom-robotics-sdk/ 43;meta-qcom-distro/ 18;meta-updater/ 8;meta-audioreach/ 1) |
| 统计口径纠正 | src/的5,083个里,5,080个是`src/kernel-6.18/kernel_platform`下vendored进来的第三方子项目自带补丁(`external/bazelbuild-bazel-central-registry` 4,890、`external/rust` 156、`external/zlib` 19、`external/bazelbuild-rules_rust` 5、`external/bazelbuild-rules_python` 4、`u-boot/tools`patman自测fixture 3、`external/elfutils`/`bazel-skylib`/`rules_cc`各1,合计5,080),与Qualcomm自身内核驱动定制无关;剩余3个在`vendor/qcom/proprietary/video/noship/v4l-utils`,是真实存在的QTI专有v4l-utils视频codec补丁,但与"内核"无关(详见output/Build_Architecture/Kernel_Build/Kernel_Build.md统计口径纠正)。另有两处非补丁本体的重复/残留:`disregard/`下38个补丁经核实是`meta-qti-agm`/`meta-qti-audio`/`meta-qti-arpal`/`meta-qti-qmmf`的废弃备份拷贝(这4个layer名不在当前`build-qti-distro-camerastack-debug/conf/bblayers.conf`激活列表中);`build-qti-*`残留554个已核实全部在`tmp-glibc/sysroots-components`下,是构建期materialize出来的第三方recipe(如perl-cross-native)补丁副本,不是独立补丁。 | 不适用 |
| 真实补丁总量(纠正后) | 约4,861个(poky/ 4,858,其中已含`poky/meta-qti-bsp*/recipes-kernel/`下6个真实内核层补丁,不额外重复计入;加上src/真实的3个v4l-utils补丁;`disregard/`38个与`build-qti-*`554个均为废弃/构建残留,不计入有效补丁总量) | 4,995个(未发现同类统计误差) |
| 组织粒度 | recipe同目录存放,`SRC_URI += "file://xxx.patch"`引入,`do_patch`阶段应用 | 相同惯例;例:`meta-qcom/recipes-graphics/mesa/mesa/0001-freedreno-Add-support-for-A704.patch` |
| 跨仓库补丁机制 | 无,若需改第三方oe-core/meta-openembedded代码,通常直接在`poky/meta`(vendor进来的整份拷贝)上直接改,或用bbappend覆盖 | 有:kas`patches:`字段声明式跨仓补丁,补丁文件物理存放在消费方(如`meta-qcom/patches/meta-oe/0001-mariadb-fix-building-for-the-ARMv8.3-A-and-later-sys.patch`),在`kas checkout`阶段被应用到上游第三方仓库(如meta-openembedded)工作树,正是Branch_Management.md中`patched-<sha>`分支的根因 |
| 补丁治理工具 | 无 | `meta-qcom-robotics-sdk/ci/yocto-patchreview.sh`(补丁健康度CI检查) |

## Systemd补丁去向追踪

| QLI1.0补丁 | 功能概述 | QLI2.0对应情况 | 吸收方式 |
|---|---|---|---|
| `Disable-unused-mount-points.patch` | 把securityfs(`/sys/kernel/security`)挂载点整段注释掉,禁止systemd自动挂载 | 无对应,securityfs相关源码改动零命中 | 功能不再需要,但无直接架构原因证据,是唯一"消失且无法解释"的一项(详见output/Boot_Architecture/systemd_/systemd_.md) |
| `fstab-generator-Honor-verity-enabled-cmdline.patch` | 识别cmdline中`verity=enabled`/`avb-verity`,强制用`/dev/mapper/root`作根设备 | 全局检索`verity=enabled`、`arg_usr_verity`零匹配 | 功能不再需要——QLI1.0整套dm-verity/AVB镜像校验子系统(8个bbclass)在QLI2.0确认完全消失 |
| `sd-bus-Allow-extra-users-to-communicate.patch` | 硬编码放行uid 1000/1001(QTI私有radio等特权用户)跨D-Bus通信 | 全局检索`sender_uid == 1001`零匹配 | 功能不再需要——服务于QLI1.0特定Android风格uid体系,QLI2.0全树无该私有uid体系痕迹 |

## 内核补丁抽样

逐个核对`poky/meta-qti-bsp*/recipes-kernel/`下的补丁,共6个:dtc编译修复、lk指令集扩展、ALSA uapi重复include修复、SoC built-in配置、libbpf缓冲区修复、lttng-ust依赖修复,均为构建期杂项修复,不涉及usb/thermal/display/wlan功能模块的驱动定制。`src/kernel-6.18/kernel_platform`下的5,080个补丁经核实全部是该目录vendored进来的第三方子项目自带补丁(明细见上《对比总览》表"统计口径纠正"行),对"内核补丁"这一统计口径的真实贡献是0个——即QLI1.0侧真正的QTI Yocto层内核补丁全部来自`poky/meta-qti-bsp*`,与`src/`无关,合计6个,此前把这6个错记为"从src/5,083个里筛出来的"是本文档自身的口径错误,现已在对比总览表中订正。QLI2.0内核层面的Yocto补丁也只有1个(构建脚本修复)。真正的驱动定制在QLI2.0已转移为kernel.git仓库内的commit,用`FROMLIST:`/`QCLINUX:`/`BACKPORT:`/`PENDING:`/`WORKAROUND:`标签体系标注来源(抽样近3000条commit统计:`FROMLIST:`488条、`BACKPORT:`102条、`QCLINUX:`41条、`PENDING:`32条、`WORKAROUND:`11条),说明相当一部分原本要靠专有DLKM或Yocto层补丁实现的功能,现在已经在走上游流程,不需要下游单独维护补丁。

## Recipe级补丁抽样:gstreamer1.0-plugins-base

抽样范围修正:`meta-qti-bsp-prop`和`meta-qti-core`两层实际patch数为0(清一色用`SRC_URI="file://xxx"`整树拷贝私有源码,如`sec-config.bb`、`mtd-utils.bb`)。转而在QTI各`meta-qti-*`层做patch密度扫描:`meta-qti-gst`(144,最高)、`meta-qti-bsp`(64)、`meta-qti-wlan`(33)、`meta-qti-ml`(31)、`meta-qti-sepolicy`(14)。

| 编号 | QLI1.0补丁内容 | QLI2.0对应情况 |
|---|---|---|
| #1 | 新增`NV12_Q08C`(Qualcomm 8bit压缩格式)视频格式支持 | 原样保留(重编号为0001) |
| #2 | 新增meson build选项`build-all-plugins`,可选仅编译`gst-libs/gst/video`子集加速构建 | **零命中,未找到等价代码或配置** |
| #3 | `videometa`新增聚合(aggregation)函数用于内存分配元数据 | 大概率被#4功能性取代/合并(代码整合,非丢失) |
| #4 | `videometa`更新聚合逻辑以支持stride对齐 | 原样保留(重编号为0003) |
| #5 | 新增`NV12_Q10LE32C`(Qualcomm 10bit压缩格式)视频格式支持 | 原样保留(重编号为0002) |
| #6 | `video-color.c/h`新增BT601/BT709/BT2100 FULL RANGE色域枚举 | **零命中,未找到等价代码或配置** |

`meta-qcom/recipes-multimedia/gstreamer/gstreamer1.0-plugins-base_%.bbappend`携带3个补丁,与QLI1.0一一对应(见上表)。

抽样范围已扩大到`meta-qti-gst`全部144个补丁(而不只是base层6个):`find poky/meta-qti-gst -iname "*.patch" | wc -l`确认按recipe分布为`gstreamer1.0-plugins-good` 60、`gstreamer1.0-plugins-bad` 29、`gstreamer1.0-plugins-base`(各版本子目录合计)26、`gstreamer1.0-omx` 11、`qti-patches` 8、`gstreamer1.0-libav` 3、`gstreamer1.0`核心4、`gstd` 2、`gstreamer-vaapi` 1。QLI2.0侧`meta-qcom/recipes-multimedia/gstreamer/`下实测3个bbappend共13个补丁(`plugins-base` 3个、`plugins-good` 7个、`plugins-bad` 3个),按补丁subject文本比对,Q08C/Q10C压缩格式、GAP buffer、colorimetry优先级等核心QCOM硬件格式适配诉求在QLI1.0侧都能找到同名/近义补丁;但QLI1.0`plugins-good`里体量最大的pulsedirectsink/pulsedirectsrc系列(约10+个)、AV1格式支持、UBWC input支持、动态分辨率切换、DMA buffer pool优化,以及`plugins-bad`里的waylandsink全屏/位置尺寸控制、GBM protocol支持、DRM protected content caps,在QLI2.0均未找到对应补丁或内联替代实现。按此估算,`meta-qti-gst`层整体补丁存活率约13/144≈9%(仅good+bad两层不含base约13/89≈15%),比单个recipe抽样看到的存活率更陡峭,说明"专有补丁形式延续但数量大幅精简"在层整体尺度上比在单个recipe尺度上更明显。

## 关键差异

- 核心Qualcomm硬件格式支持(NV12_Q08C/NV12_Q10LE32C压缩格式、stride对齐聚合逻辑)确实通过patch延续,未被内联进recipe本身或消化——证明"大量QTI专有补丁被消化"的结论对gstreamer这类多媒体组件并不适用,是patch形式原样延续,只是数量做了精简。
- 补丁总量QLI1.0(纠正后约4,861个:poky/ 4,858+src/真实3个v4l-utils补丁)与QLI2.0(4,995个)明显更接近,而非最初统计的10,533 vs 4,995那种"腰斩"印象——第一轮统计口径错误已在output/Build_Architecture/Kernel_Build/Kernel_Build.md中详细纠正;本文档进一步核实又发现两处需订正:`disregard/`废弃备份layer的38个补丁应排除,且此前把`poky/meta-qti-bsp*`的6个真实内核补丁误记为"从src/里筛出来的"、与src/口径重复计入,现已在对比总览表订正为不重复计数。
- gstreamer案例证明"并非所有专有补丁都能通过上游合并或内核commit化解释",部分功能补丁(如色域FULL RANGE支持)确实丢失且无解释,需要逐层抽样才能发现这类"沉默丢失",不能只看补丁数量统计。
- 已确认QLI2.0不存在独立的`meta-qcom-multimedia`顶层repo(`find . -maxdepth 1 -iname "*multimedia*"`零命中);`recipes-multimedia`只是`meta-qcom`/`meta-qcom-distro`两个既有层内部的子目录,`meta-qcom-distro/conf/layer.conf`里的`multimedia-layer`字符串是DISTRO_FEATURES/backfill特征名而非独立layer声明,本次补丁统计口径(计入meta-qcom/meta-qcom-distro)已完整覆盖,不存在遗漏层。

## 影响与风险

- kas跨仓补丁机制提高了对第三方代码定制的可追溯性,但补丁与目标仓库版本强耦合(`base.lock.yml`锁定的commit变化后,补丁可能失败conflict),需要建立补丁健康度的CI检查(已检索到`meta-qcom-robotics-sdk/ci/yocto-patchreview.sh`此类脚本,说明QLI2.0侧已有配套治理工具)。
- QLI1.0补丁数量巨大且分散在poky/meta-qti-*各层,补丁维护成本高、易与上游脱钩(常年vendored副本);QLI2.0补丁量减少但更依赖"精确锁定commit+补丁"的脆弱组合,commit漂移风险需重点关注。
- 内核patch的"吸收方式"以上游合并(FROMLIST标签)和内核仓库commit化(QCLINUX标签)为主,而非真正"消失",但这意味着追踪具体某项QCOM定制改动的方式从"看Yocto层patch文件"变成了"看内核git commit历史",审计方法需要更新。

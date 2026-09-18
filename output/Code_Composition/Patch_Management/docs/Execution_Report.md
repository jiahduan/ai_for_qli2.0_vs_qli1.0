# Patch_Management 执行报告

本文档复盘`../Patch_Management.md`的结论是怎么从取证要点(见`rules/Code_Composition/Patch_Management.md`"Patch_Management专属取证要点"节)一步步落地的,重点展开本主题的补丁总量纠错(全库最完整的纠错案例,已写入README《曾纠正过的结论》表)及文档内部的两次二次订正。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Patch_Management.md`。

## 纠错主线:补丁总量——从10,533降到约4,861的三步订正过程

**最初判断**:对downstream(maili)侧执行`find <目录> -iname "*.patch" | wc -l`,按`poky/`4,858、`src/`5,083、`build-qti-*`工作目录残留554、`disregard/`废弃备份38四类目录简单相加,得到10,533个,与QLI2.0侧4,995个相比呈"腰斩"式对比印象。

**第一步订正——识别`src/`里的第三方噪声**:逐项核查`src/`5,083个补丁的来源,发现其中5,080个集中在`src/kernel-6.18/kernel_platform`目录下,是该目录vendored进来的第三方子项目自带补丁:`external/bazelbuild-bazel-central-registry` 4,890、`external/rust` 156、`external/zlib` 19、`external/bazelbuild-rules_rust` 5、`external/bazelbuild-rules_python` 4、`u-boot/tools`的patman自测fixture 3、`external/elfutils`/`bazel-skylib`/`rules_cc`各1(合计5,080),与Qualcomm自身内核驱动定制完全无关。剩余3个在`vendor/qcom/proprietary/video/noship/v4l-utils`,是真实存在的QTI专有v4l-utils视频codec补丁,但与"内核"无关。这一步的详细口径纠正记录在`output/Build_Architecture/Kernel_Build/Kernel_Build.md`。

**第二步订正——识别`disregard/`与`build-qti-*`两类非补丁本体**:核实`disregard/`下38个补丁是`meta-qti-agm`/`meta-qti-audio`/`meta-qti-arpal`/`meta-qti-qmmf`四个layer的废弃备份拷贝,这4个layer名不在当前`build-qti-distro-camerastack-debug/conf/bblayers.conf`激活列表中;`build-qti-*`残留554个全部核实在`tmp-glibc/sysroots-components`下,是构建期materialize出来的第三方recipe(如perl-cross-native)补丁副本,不是独立补丁本体。两者均从有效补丁总量中排除。

**第三步订正(本文档新发现的口径错误,二次订正)——`poky/meta-qti-bsp*`的6个真实内核补丁曾被误记为"从src/里筛出来"**:逐个核对`poky/meta-qti-bsp*/recipes-kernel/`下的补丁,共6个(dtc编译修复、lk指令集扩展、ALSA uapi重复include修复、SoC built-in配置、libbpf缓冲区修复、lttng-ust依赖修复),发现此前把这6个错误地当作"从src/5,083个里筛出来的",与`poky/`4,858这一口径产生了重复计入。现已在《对比总览》表与"内核补丁抽样"节明确订正:这6个补丁本就包含在`poky/`4,858的统计口径内,不应额外重复计数,downstream(maili)侧真正的QTI Yocto层内核补丁全部来自`poky/meta-qti-bsp*`,与`src/`无关。

**最终修正结论**:真实补丁总量约4,861个(`poky/`4,858,已含上述6个内核补丁不重复计入;加上`src/`真实的3个v4l-utils补丁),与QLI2.0的4,995个相比明显更接近,而不是最初10,533 vs 4,995那种误导性的"腰斩"印象。这一订正因足够重要(直接影响"补丁数量对比"这一整体判断的方向),已同步写入README.md《曾纠正过的结论》表,是全库最完整的纠错案例。

## 二次纠偏:抽样对象的选择——从"猜测层名"到"验证后改选"

**初步计划**:按经验判断,准备在`meta-qti-bsp-prop`和`meta-qti-core`两层做patch密度抽样,因为这两个层名听起来像是承载硬件定制补丁的主要位置。

**发现问题的过程**:实际检索这两层的补丁数量时,发现均为0——这两层清一色用`SRC_URI="file://xxx"`整树拷贝私有源码(如`sec-config.bb`、`mtd-utils.bb`),根本不采用补丁形式做定制,靠"层名字面含义"猜测抽样对象的做法在这里落空。

**修正做法**:转而对全部`meta-qti-*`层做patch密度扫描,得到`meta-qti-gst`(144个,最高)、`meta-qti-bsp`(64)、`meta-qti-wlan`(33)、`meta-qti-ml`(31)、`meta-qti-sepolicy`(14)的排序,据此改选`meta-qti-gst`作为抽样对象,理由是它补丁密度最高,最能代表"补丁形式定制"这一组织模式的典型样本。

**这条纠偏说明的方法论问题**:取证要点明确总结为"选抽样对象前先验证该层是否真的有patch文件,不能凭layer名称猜测"——层名本身不能作为"该层用补丁做定制"的证据,必须先验证再选择抽样对象,这也呼应了规则1"禁止仅凭目录名断言"在抽样场景下的具体应用。

## 抽样结论的落地:gstreamer补丁存活率的两层估算

**做法**:先在`gstreamer1.0-plugins-base`层做6补丁逐个比对(个案级),再把抽样范围扩大到`meta-qti-gst`全部144个补丁,按recipe统计分布(`gstreamer1.0-plugins-good` 60、`plugins-bad` 29、`plugins-base` 26等),与QLI2.0侧`meta-qcom/recipes-multimedia/gstreamer/`3个bbappend共13个补丁按subject文本逐条比对。
**证据**:核心QCOM硬件格式适配诉求(Q08C/Q10C压缩格式、GAP buffer、colorimetry优先级)两侧均能找到同名/近义补丁;但`plugins-good`里体量最大的pulsedirectsink系列、AV1支持、UBWC input支持等均未找到对应。
**落到结论**:整体存活率约13/144≈9%(仅good+bad两层不含base约13/89≈15%)。取证要点/规则3均强调:这是抽样估算,措辞上明确"存活率约9%"而非"补丁基本都丢了",不得直接外推为总体结论。

## Systemd补丁去向追踪:三例逐一等价性检索

**做法**:对三个downstream(maili)补丁(`Disable-unused-mount-points.patch`、`fstab-generator-Honor-verity-enabled-cmdline.patch`、`sd-bus-Allow-extra-users-to-communicate.patch`)分别做等价性字符串检索:`verity=enabled`/`arg_usr_verity`、`sender_uid == 1001`等。
**证据**:三例均零匹配。
**落到结论**:Systemd补丁去向追踪表——三例中两例(dm-verity相关、私有uid体系相关)有明确架构原因解释(对应架构整体消失),一例(securityfs挂载点)确认消失但无法从代码库找到直接架构原因,如实标注为"唯一消失且无法解释"的一项,不强行编造原因。

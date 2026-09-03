# Overlay —— 规则

> 本文件对应产出文档 [output/System_Architecture/Overlay/Overlay.md](../../output/System_Architecture/Overlay/Overlay.md),与全部33份主题规则文件按本次目录重构选择的方式各自完整独立(7条强制规则全文一致,不做共享继承,变更时需同步维护;背景见[Scope_Section_Design.md](../../Scope_Section_Design.md))。全局工作流/与README关系见根目录[Methodology.md](../../Methodology.md)。

## 强制规则

以下规则对所有主题文档硬性生效,不因主题不同而放宽。

### 1. 证据引用标准

任何结论性陈述必须能追溯到以下至少一种证据:
- 具体文件路径(尽量带行号),如`meta-qcom/classes-recipe/image_types_qcom.bbclass`第127-136行
- 检索命令及其实际输出,如`grep -rln "abctl|libabctl" meta-qcom meta-qcom-distro meta-updater`零匹配
- git commit hash / `git log`/`git describe`输出
- 官方文档原文引用(需注明来源与核实方式,见规则6)

**禁止**仅凭目录名或关键字搜索为空就断言"某功能已消失"——必须展示实际检索命令及零命中证据,并在可能时交叉检索多个关键字变体(如同时检索`abctl`与`libabctl`)。

### 2. 统一文档结构

每个主题文档必须按以下顺序包含章节(可在中间插入主题专属章节,但首尾两类不可省略):

0. `## 对比范围` — 三个固定字段,必须都出现:
   - **覆盖**:本文实际比较的子项列表,每项标明双侧目录/文件锚点。单条bullet的"锚点+说明"过长(经验值:超过约150字/接近一整段)时,拆成更细的子bullet,不要塞成一段长文字,保持列表可扫读
   - **明确排除**:本主题名义上涉及、但结论归属别的文档的项——不要求"正文已经字面提到过才能排除",只要读者可能预期在本文找、但实际该去别的文档找,就该排除。每条只写"项名 ——见[YY](相对路径/YY.md)",不展开排除理由(理由留给目标文档自己交代,或在本文正文引用处简要说明,不塞进这一行);用markdown链接而非书名号,保持和README索引表一致的可点击引用风格;有多条时每条单独一行列出(子bullet),不要用分号堆在同一行——方便脚本按行解析,也方便人工审阅
   - **待定边界**:暂时定不下来该归哪篇、先记录别漏掉的项;为空写"(无)"——如果是"核实过确认没有"而非"没检查",可以写成"(无,已核实XX)"这种形式简要说明核实范围,不算违反"为空写(无)"的要求;随本文档下次修订顺带复核,不单开复核周期;若长期悬而未决,同步进README《待拍板事项汇总》

   本节是文字化元信息(管辖边界、目录锚点、排除去向),不重复下面《对比总览》表已有的对比结论;《对比总览》也不解释某项为何不在表里——两节不互相转述。
1. `## 对比总览` — 一张`维度 | QLI1.0 | QLI2.0`表格,是文档骨架,让读者10秒内看到全貌
2. (可选)主题专属深挖章节 — 追踪表、抽样统计、专项验证等
3. `## 关键差异` — 综合性洞察,**不是对总览表的复述**,要回答"这些差异放在一起意味着什么"
4. `## 影响与风险` — 对下游团队/决策的具体影响,不做纯技术总结

### 2.1 Overlay源码级分析方法论(7步)

以架构师视角做source-level分析,不是从抽象"overlay能力面覆盖度"出发。Overlay主题内部有两类互不相关、只是同名的机制(rootfs overlayfs / 设备树dtbo overlay,原理见`output/System_Architecture/Overlay/docs/Principles.md`第1节),所以第一步先分类,第2-3步、第4-5步再分别按两类各自的"物理载体→核心变量绑定点"两段式收敛,第6步精确到两个具体机型,第7步用实际构建产物做终局验证:

1. **先分类:辨明当前证据属于哪一类"overlay"**:不把rootfs overlayfs与设备树dtbo overlay的证据混在同一条链里讨论——两者解决的工程问题完全不同(存储/更新架构 vs 硬件适配组合性),混谈会导致"overlay是否参与构建"这种问题失去意义(必须先答"哪个overlay")。
2. **定位rootfs overlayfs的物理载体/挂载器**:QLI1.0是自研`gen_overlayfs()`(`poky/meta-qti-bsp/classes/qimage-ext4.bbclass`/`qimage-squashfs.bbclass`)+专用挂载器`overlay-mounter_1.0.bb`;QLI2.0是oe-core自带标准class`oe-core/meta/classes-recipe/overlayfs-etc.bbclass`(非QCOM自研),要落到具体文件与recipe,不能只说"两侧都有overlay机制"。
3. **看驱动rootfs overlayfs是否启用的核心变量绑定点**:QLI1.0是`MNT_POINTS`变量(`gen_overlayfs`内部`bb.utils.contains('MNT_POINTS','overlay',...)`判断)+按机型的`read-only-rootfs` IMAGE_FEATURE;QLI2.0是`overlayfs-etc.bbclass`本身要被具体recipe/机型`inherit`才生效,另有`sota` DISTRO_FEATURE驱动`meta-updater`OSTree路线——`overlayfs-etc.bbclass`文件存在不代表任何构建都启用了它,必须证明某次具体构建真的`inherit`了它(呼应规则1"禁止仅凭目录名断言")。
4. **定位设备树dtbo overlay各自的构建链载体**:QLI1.0是techpack overlay独立recipe(`mmdevicetree_git.bb`/`displaydevicetree_git.bb`)+`qimage.bbclass`的`do_merge_techpack_dtbos`(`merge_dtbs.py`动态扫描合并)+`qimage-dtbo.bbclass`的`do_makedtbo`(产物`dtbo.img`);QLI2.0是`meta-qcom/classes/linux-qcom-dtbbin.bbclass`(基础dtb打包,显式跳过dtbo)与`meta-qcom/classes-recipe/dtb-fit-image.bbclass`(`do_generate_qcom_fitimage`)并行分工的两条class。
5. **看驱动dtbo是否参与最终镶像的核心变量绑定点**:QLI1.0是`BUILD_WITH_TECHPACKS`(`msm-common.inc`默认`"1"`,机型conf可覆盖);QLI2.0是machine级`LINUX_QCOM_KERNEL_DEVICETREE`/`KERNEL_DEVICETREE`(声明哪些dtbo参与)与`FIT_DTB_COMPATIBLE`(声明哪些dtb+dtbo组合打进同一份FIT config)——同样,变量在`.conf`/`.inc`里有没有具体赋值行,是判断"是否真的被distro/machine层管控"的唯一依据,不能停在"class文件存在"。
6. **精确到两个具体机型的dtbo证据链**(不做抽象产品线覆盖度调查):
   - QLI2.0:**iq-9075-evk**(`meta-qcom/conf/machine/iq-9075-evk.conf`,芯片家族`lemans`/QCS9075/QCS9100)——`KERNEL_DEVICETREE`声明1个dtbo(`lemans-evk-camera-csi1-imx577.dtbo`)+`LINUX_QCOM_KERNEL_DEVICETREE`声明8个dtbo,合计9个,与实际构建产物`build/tmp/work/iq_9075_evk-qcom-linux/linux-qcom/6.18.30/image/boot/*.dtbo`(本次重新`find`确认恰好9个)逐一对应,非猜测。
   - QLI1.0:已实测排查,**不存在同芯片家族的直接对应机型**——`find . -path '*/conf/machine/*.conf'`遍历QLI1.0全部140个machine conf文件,`grep -i "lemans\|qcs9100\|qcs9075\|sa8775"`零命中,确认QLI1.0没有对应`lemans`/QCS9075这一芯片家族的Yocto MACHINE/BASEMACHINE集成。但QLI1.0内核源码树`src/kernel-6.18/kernel_platform/common/arch/arm64/boot/dts/qcom/`下确实存在该芯片家族的内核设备树源码(`lemans-evk.dts`/`qcs9100-ride.dts`/`sa8775p-ride.dts`),且该目录`Makefile`第33/35/37行`dtb-$(CONFIG_ARCH_QCOM) += lemans-evk.dtb`等规则证明这些dts已被Kbuild真实引用编译——即"该芯片的内核DT源码已存在于QLI1.0快照里,但meta-qti-bsp层尚未做machine级BSP集成(没有`lemans.conf`一类machine文件)",这是QLI2.0侧率先做了BSP集成的一个真实新增机型,不是QLI1.0"这类机制不存在",要如实分层说明,不能混为一谈。
   - 因此QLI1.0侧改用已验证的真实机型**pebble**(与`Distro_Version.md`核心证据机型一致)演示"techpack overlay merge"这一等价机制本身是真实交付的(证据见步骤7),而不是编造一个不存在的"lemans对应机型"。
   - 交叉核实同一模式非孤例:QLI2.0另一个声明`LINUX_QCOM_KERNEL_DEVICETREE`的机型`qcs615-ride`(芯片codename`talos`/QCS615),用`grep -rli "talos"`核实QLI1.0代码树内命中均为NXP`imx6qdl-ts79xx`系列dtsi文件名巧合(非同一芯片),同样没有真实对应——"新引入的machine级dtbo overlay机制目前覆盖的是QLI1.0尚无同芯片BSP集成的新SoC"具有一致性,不是iq-9075-evk个案。
7. **用实际构建产物做终局验证,不停在machine conf声明层**:
   - dtbo侧QLI2.0:直接读取最终部署镶像的FIT描述文件`build/tmp/deploy/images/iq-9075-evk/qclinux-fit-image.its`,确认其中`fdt-lemans-*.dtbo`节点用`/incbin/("...boot/dts/qcom/lemans-*.dtbo")`把dtbo二进制直接内嵌进最终`.its`,且多个`configuration@N`节点的`fdt = "fdt-lemans-evk.dtb", "fdt-lemans-evk-camx.dtbo", ...`字段把base dtb与多个dtbo列为同一份FIT配置——这比"work目录下存在.dtbo文件"更进一步,证明dtbo确实被编进了最终部署镶像,不是编译阶段性产物。
   - dtbo侧QLI1.0:对最终融合dtb直接`dtc -I dtb -O dts`反解,确认具体techpack节点(如`qcom,hw-fence`、`sde_dp`)真实落入最终产物(既有证据,本次未重复执行dtc,仅复核`# Skip DTBOs`与9个.dtbo文件计数不变)。
   - rootfs侧QLI1.0:本次新增证据——复核`build-qti-distro-camerastack-debug/tmp-glibc/work/pebble-oe-linux/qti-multimedia-image/1.0/rootfs-ext4/usr/libexec/overlay-mounter`及同目录`var/lib/opkg/info/overlay-mounter.control`,确认`overlay-mounter`二进制及其opkg包信息真实出现在pebble机型的实际构建rootfs产物里,不只是recipe定义存在。
   - rootfs侧QLI2.0:`debugfs -R "cat /etc/fstab"`直接读取实际构建镶像内容(既有证据,见"Overlay专属取证要点")。

每一步的产出最终收敛进"Overlay专属取证要点",再由取证要点收敛成正文的对比总览/关键差异/影响与风险——取证要点是证据,正文是结论,不能反过来倒推。

### 3. 抽样声明

涉及大规模内容(补丁、commit、recipe)无法逐一核对时,必须:
- 明示抽样范围与方法(如"随机抽样`meta-qti-gst`全部144个补丁中的6个,按recipe分布统计")
- 明确抽样结论的局限,不得直接外推为总体结论而不加限定语(如用"存活率约9%"而非"补丁基本都丢了")

### 4. 纠错记录

当先前判断被新证据推翻时,禁止静默覆盖旧结论,必须:
- 在该主题文档内保留"初步判断 → 核实后结论"的对照(可用小节或表格形式,如Patch_Management.md的补丁总量纠正)
- 若纠正的结论足够重要(影响其他文档的判断或曾写入README汇总表),同步更新README.md《曾纠正过的结论》表

### 5. 风险分级

任何写入README《安全/合规风险清单》或《待拍板事项汇总》的发现,必须标注优先级:

| 等级 | 判定依据 |
|---|---|
| P0 | 影响范围广且不可逆(如安全校验机制整体消失、需要重建服务端基础设施) |
| P1 | 影响范围较大或需要专项决策,但有明确规避/替代路径 |
| P2 | 影响范围有限,属于工程执行层面的既定工作 |
| P3 | 边缘case或低优先级遗留问题 |

分级依据是"影响范围 × 不可逆性",不是主观感受;同一发现在不同产品线/团队视角下等级可能不同,应在文档中说明判定理由而非只写等级本身。

### 6. 交叉验证

当本地代码库证据不足以支撑结论(尤其是"上游行为是否符合规范""是否遵循最佳实践"类判断)时:
- 必须查找官方文档/release notes/迁移指南等权威来源(如对应的`reference/`子目录下的存档页面)交叉验证
- 明确标注验证状态:"已用XX来源核实"或"未能核实,标注为推测,待后续验证"
- 若本地环境网络受限无法直连官方站点,应将需要的页面存档到本主题的`reference/`子目录后再核实,而非跳过验证直接下结论

### 7. 范围交叉一致性

任何文档《对比范围》里的"明确排除",必须能在被指向的文档的"覆盖"字段里找到对应项;反之,任何"待定边界"项,不得同时被两篇文档都排除或都不提及。写完/改完一篇文档的《对比范围》后,必须检查它指向或被指向的文档是否需要同步更新。可用`scripts/check_scope_links.sh`辅助抓悬空引用(字符串级别粗检查,不能替代人工判断措辞是否准确)。

## System_Architecture 专属取证指引

系统级基础设施与硬件子系统对比。优先证据来源:
- 版本字符串:distro/layer的`.conf`文件(如`poky.conf`的`DISTRO_VERSION`)、`layer.conf`的`LAYERSERIES_COMPAT_core`
- 构建产物内版本信息:`bitbake`/内核源码内`git describe`、`__init__.py`等版本常量
- 子系统专有栈 vs 开源栈的判定:优先搜对应服务/驱动的顶层recipe与依赖(如Display看HWC/Composer vs DRM/KMS+Mesa,Audio看AudioReach源码树 vs meta-audioreach+PipeWire)
- 安全类结论(如SELinux策略)需要给出规则数量级对比(如"661文件"vs"约3个策略点"),不能只写"有/无"

## Overlay专属取证要点(按2.1节7步方法论组织)

- **1.先分类**:本节及正文均按"rootfs overlayfs"/"设备树dtbo overlay"两组分别列锚点,不跨类混谈(原理见`Principles.md`第1节)。
- **2.rootfs overlayfs物理载体**:QLI1.0`poky/meta-qti-bsp/classes/qimage-ext4.bbclass`(`gen_overlayfs()`)、`qimage-squashfs.bbclass`、`overlay-mounter_1.0.bb`、`ab-ota-ext4.bbclass`/`ab-ota-squashfs.bbclass`/`ota-ext4.bbclass`、`overlayfs.cfg`、`qti-csm-image.bb`;QLI2.0`oe-core/meta/classes-recipe/overlayfs-etc.bbclass`(本次复核`grep -rln overlayfs-etc meta-qcom meta-qcom-distro meta-qcom-robotics-sdk`重新确认零处inherit)。
- **3.rootfs overlayfs启用绑定点**:QLI1.0`MNT_POINTS`变量驱动`gen_overlayfs`+`read-only-rootfs` IMAGE_FEATURE(按机型);QLI2.0`overlayfs-etc.bbclass`需具体`inherit`才生效(当前零命中)+`meta-updater`的`sota` DISTRO_FEATURE。
- **4.dtbo overlay构建链载体**:QLI1.0`mmdevicetree_git.bb`/`displaydevicetree_git.bb`+`qimage.bbclass`的`do_merge_techpack_dtbos`(`merge_dtbs.py`)+`qimage-dtbo.bbclass`(`do_makedtbo`,产物`dtbo.img`);QLI2.0`meta-qcom/classes/linux-qcom-dtbbin.bbclass`(`# Skip DTBOs`)与`meta-qcom/classes-recipe/dtb-fit-image.bbclass`(`do_generate_qcom_fitimage`)并行分工。
- **5.dtbo是否参与最终镶像的核心变量**:QLI1.0`BUILD_WITH_TECHPACKS`(`msm-common.inc`默认`"1"`);QLI2.0machine级`KERNEL_DEVICETREE`/`LINUX_QCOM_KERNEL_DEVICETREE`+`fit-dtb-compatible-linux-qcom.inc`里的`FIT_DTB_COMPATIBLE`声明式映射。
- **6.两个具体机型的dtbo证据链(本次新增,已实测确认,是本主题最核心的证据)**:
  - **iq-9075-evk(QLI2.0)**:`meta-qcom/conf/machine/iq-9075-evk.conf`——`KERNEL_DEVICETREE`声明1个dtbo(`qcom/lemans-evk-camera-csi1-imx577.dtbo`)+`LINUX_QCOM_KERNEL_DEVICETREE`声明8个dtbo(`lemans-el2`/`lemans-evk-camx`/`lemans-camx-el2`/`lemans-evk-ifp-mezzanine`/`lemans-evk-staging`/`lemans-staging`/`lemans-evk-emmc`/`lemans-evk-sd-card`),合计9个;本次重新`find build/tmp/work/iq_9075_evk-qcom-linux/linux-qcom/6.18.30/image/boot -iname '*.dtbo'`确认恰好产出9个同名`.dtbo`文件,与machine conf声明逐一对应,非猜测。
  - **QLI1.0侧核实结果:不存在同芯片家族(lemans/QCS9075/QCS9100)的直接对应机型**——已执行`find . -path '*/conf/machine/*.conf'`遍历QLI1.0全部140个machine conf文件,`grep -i "lemans\|qcs9100\|qcs9075\|sa8775"`零命中(命令与"零命中"结果均已实测,非省略核实)。但`src/kernel-6.18/kernel_platform/common/arch/arm64/boot/dts/qcom/`目录下确有该芯片家族内核dts源码(`lemans-evk.dts`/`qcs9100-ride.dts`/`sa8775p-ride.dts`),且该目录`Makefile`第33/35/37行`dtb-$(CONFIG_ARCH_QCOM) += lemans-evk.dtb`等规则证明这些dts已被Kbuild真实引用编译——结论是"该芯片内核DT源码已存在于QLI1.0快照,但meta-qti-bsp层尚无machine级BSP集成(无`lemans.conf`一类文件)",这是QLI2.0侧率先完成BSP集成的新机型,不是"QLI1.0没有这类机制";QLI1.0侧改用已验证的真实机型**pebble**(与`Distro_Version.md`核心证据机型一致)演示techpack overlay merge这一等价机制本身是真实交付的,不编造不存在的"lemans对应机型"。
  - **非孤例交叉核实**:QLI2.0另一声明`LINUX_QCOM_KERNEL_DEVICETREE`的机型`qcs615-ride`(芯片codename`talos`/QCS615,`LINUX_QCOM_KERNEL_DEVICETREE ?= "qcom/talos-el2.dtbo qcom/talos-staging.dtbo"`),已用`grep -rli "talos"`核实QLI1.0代码树内命中均为NXP`imx6qdl-ts79xx`系列dtsi文件名巧合(非同一芯片),同样没有真实对应,与iq-9075-evk属同一模式。
- **7.实际构建产物终局验证(本次新增最强证据)**:
  - QLI2.0侧本次新增:直接grep最终部署镶像的FIT描述文件`build/tmp/deploy/images/iq-9075-evk/qclinux-fit-image.its`,确认`fdt-lemans-*.dtbo`节点用`/incbin/("...boot/dts/qcom/lemans-*.dtbo")`把dtbo二进制直接内嵌入最终`.its`,且多个`configuration@N`节点`fdt = "fdt-lemans-evk.dtb", "fdt-lemans-evk-camx.dtbo", ...`把base dtb与多个dtbo列为同一FIT配置——比"work目录下存在.dtbo文件"更进一步,证明dtbo确实进了最终部署镶像,不是编译阶段性产物。
  - QLI1.0侧本次新增:复核`build-qti-distro-camerastack-debug/tmp-glibc/work/pebble-oe-linux/qti-multimedia-image/1.0/rootfs-ext4/usr/libexec/overlay-mounter`及同目录`var/lib/opkg/info/overlay-mounter.control`,确认`overlay-mounter`二进制及其opkg包信息真实出现在pebble机型的实际构建rootfs产物里,不只是recipe定义存在。
  - `ls build/tmp/work/iq_9075_evk-qcom-linux/linux-qcom/6.18.30/image/boot/*.dtbo`(既有证据,本次复核不变,仍9个)
  - `dtc -I dtb -O dts`反解最终融合dtb(`pebblep-pebble-hfi-core-...-0x3ed5501da86a4297.dtb`),grep`qcom,hw-fence`/`sde_dp`确认techpack节点真实落入最终产物(既有证据)
  - `grep -rlw eva`/`audio`扩大范围到`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`/`meta-audioreach`全层复核audio/eva overlay承接机制,确认零命中(既有证据)
  - `debugfs -R "cat /etc/fstab"`直接读取实际构建镶像(`qcom-robotics-image-iq-9075-evk.rootfs.ext4`)内文件,核实`/`是否只读、是否有overlay相关mount unit(既有证据)
- **已知易错点/纠错记录**:有(与README一致)——"QLI2.0设备树dtbo是否真实参与最终构建":初步判断因仅看到`linux-qcom-dtbbin.bbclass`里`# Skip DTBOs`注释,认为"QLI2.0侧dtbo构建路径不明/可能未真正参与最终镶像";核实后结论"确认参与,证据链完整"——`dtb-fit-image.bbclass`是与`linux-qcom-dtbbin.bbclass`并行、职责互补的另一条路径,实际构建产物有9个`.dtbo`文件,且`qcs615-ride.conf`把dtbo写进machine级配置、由`do_generate_qcom_fitimage`打进U-Boot FIT image。已同步进README《曾纠正过的结论》表。本次(2.1节方法论落地)进一步用iq-9075-evk的最终`.its`文件`/incbin/`证据把"是否真实参与"这条纠错坐实到最终部署镶像层面,不影响已同步进README的结论方向。

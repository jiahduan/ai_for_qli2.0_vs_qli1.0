# OTA_Mechanism —— 规则

> 本文件对应产出文档 [output/Platform_Features/OTA_Mechanism/OTA_Mechanism.md](../../output/Platform_Features/OTA_Mechanism/OTA_Mechanism.md),与全部33份主题规则文件按本次目录重构选择的方式各自完整独立(7条强制规则全文一致,不做共享继承,变更时需同步维护;背景见[Scope_Section_Design.md](../../Scope_Section_Design.md))。全局工作流/与README关系见根目录[Methodology.md](../../Methodology.md)。

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
1. `## 对比总览` — 一张`维度 | downstream(maili) | QLI2.0`表格,是文档骨架,让读者10秒内看到全貌
2. (可选)主题专属深挖章节 — 追踪表、抽样统计、专项验证等
3. `## 关键差异` — 综合性洞察,**不是对总览表的复述**,要回答"这些差异放在一起意味着什么"
4. `## 影响与风险` — 对下游团队/决策的具体影响,不做纯技术总结

### 2.1 OTA_Mechanism源码级分析方法论(8步,补充"分类专属取证指引"的取证起点,不替代标准文档结构)

以架构师视角做source-level分析,不是从"升级机制变了"这种抽象产品维度出发,按下面顺序找证据:

1. **定位OTA机制的选型载体**:哪个distro conf/bbclass决定走哪套升级方案——downstream(maili)是`src/OTA/`等recipe/image级别的常驻组件(不经distro conf开关,是核心交付件的一部分,不是opt-in);QLI2.0是`qcom-distro-sota.conf`(`require conf/distro/include/qcom-distro-sota.inc`→`require conf/distro/sota.conf.inc`,引入`meta-updater`的OSTree+aktualizr)。先确认"谁来决定用哪套方案"这件事本身在两侧是否处于同一层级(recipe级 vs distro-conf级),层级不同会直接影响"opt-in核查"这一步该往哪里查。
2. **核心升级引擎组件树**:downstream(maili)`src/OTA/`(AOSP`bootable/recovery`+`build/tools/releasetools`+`system/update_engine`移植)+`external/bsdiff/`、`external/libdivsufsort/`;QLI2.0`recipes-sota/ostree`+`recipes-sota/aktualizr/`(`aktualizr_git.bb`等)。
3. **A/B切换与回滚实现**:downstream(maili)`src/bootctrl/abctl/`(`libabctl.cpp`,GPT属性优先级+尝试次数);QLI2.0`aktualizr-uboot-env-rollback.bb`(u-boot bootcount触发单一rootfs的OSTree deploy回滚,与downstream(maili)基于固件槛的A/B切换是不同机制,不能直接等价对比)。
4. **opt-in绑定点的"是否真的进过CI/构建"核查**(本主题方法论的核心步骤,比Distro_Version的SELinux opt-in模式更进一步):不能停在"conf文件存在"或"有专属ci yml文件"就下结论,必须核查:①该distro variant是否曾出现在任一层`.github/workflows/*.yml`的编译/测试矩阵`distro:`条目里(用`grep -rn "<variant名>" */.github/workflows`遍历三层仓库);②若零命中,进一步用`git log --oneline -- <相关conf/yml文件>`核实该功能存在时长、期间CI矩阵是否被重写过、重写后是否补录——用来区分"功能太新CI还没排期"与"排期多次仍未纳入"两种性质不同的opt-in状态。
5. **精确到两个具体机型的完整性校验状态核对**(不做抽象产品线覆盖度调查,本主题证据链核心):钉死一对**双侧都有本仓库内真实跑完的buildhistory**(而非仅CI矩阵条目或静态conf推断)的机型,机型级重新核实dm-verity/AVB相关的独立证据(参照规则1"多变体交叉检索"要求),同时检索同代码库内其他真实机型的对应配置,交叉证明"某项能力在架构层面是否真实存在、被使用过"与"被钉定的这台机型是否选用该能力"是两个不同层次的问题,避免把"钉定机型没开"误读成"整条产品线没有这个能力"(反之也要避免把"其他机型开了"误读成"钉定机型也一定开了")。
6. **差分/升级包生成能力对比**:downstream(maili)`full_ota.sh`/`incremental_ota.sh`(bsdiff文件级差分,原生支持);QLI2.0 OSTree对象级去重(`static-deltas`是否被recipe/配置层真正启用,需与"libostree自身具备该能力"区分开,只搜到源码文件名不算启用证据)。
7. **服务端信任模型与首刷边界**:downstream(maili)自建HTTP签名zip分发,无强制TUF后端;QLI2.0需要Uptane/TUF Director+Image Repo(或HERE OTA Connect);两者均需与首刷QDL/EDL流程的边界做一次明确确认(OSTree只改变"刷机后"路径,不改变首刷方式本身)。
8. **成熟度佐证(git历史,包括佐证"尚不成熟"的负面案例)**:与Distro_Version"用commit数量佐证已验证的成熟范式"不同,OTA_Mechanism的新增能力(如`qcom-distro-sota`)git历史也可能佐证的是**尚未成熟/未经生产验证**——需要看新增时间、后续改动频次、以及第4步查到的CI矩阵是否已经历过重写却仍未纳入,三者叠加才能定性,不能只看"存在多久"就类比为成熟。

每一步的产出最终收敛进"专属取证要点",再由取证要点收敛成正文的关键差异/影响与风险——取证要点是证据,正文是结论,不能反过来倒推。

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

## Platform_Features 专属取证指引

平台级功能机制对比。优先证据来源:
- 核心组件:先定位顶层功能目录(如`src/OTA/`)或对应recipe/layer(如`meta-updater/`),再看具体实现文件
- 机制是否默认启用还是opt-in:必须检查distro配置(如`qcom-distro-sota.conf`)与CI配置(如`.ci/*.yml`)是否真的构建了该变体,避免"代码库里存在"被误判为"产品默认启用"
- 涉及安全相关机制(如镶像完整性校验)消失的结论,需要交叉至少两个独立证据源(如同时检索cmdline参数与对应bbclass是否存在),并核查"能力是否人在场但没上岗"(即代码库里其他层已有等价能力但未被目标镜像inherit/引用)

## OTA_Mechanism专属取证要点(按2.1节8步方法论组织)

- **1.OTA机制选型载体**:downstream(maili)`src/OTA/`等recipe/image级常驻组件(不经distro conf开关,是核心交付件的一部分,非opt-in);QLI2.0`qcom-distro-sota.conf`(`require conf/distro/include/qcom-distro-sota.inc`→`require conf/distro/sota.conf.inc`,`INITRAMFS_IMAGE="initramfs-ostree-image"`、`DISTRO_NAME:append=" (OTA-enabled)"`、`DISTRO_FEATURES_OPTED_OUT+="ptest"`、`BUILD_OSTREE_REPO_TARBALL="1"`)——两侧"谁决定用哪套方案"分别处于recipe级与distro-conf级,层级不同
- **2.核心升级引擎组件树**:downstream(maili)`src/OTA/`(AOSP`bootable/recovery`+`build/tools/releasetools`+`system/update_engine`移植:`recovery/{applypatch,edify,updater,minzip,minui,bootloader_message,update_verifier,otafault}`)、`external/bsdiff/`、`external/libdivsufsort/`;QLI2.0`meta-updater/README.adoc`、`recipes-sota/ostree`、`recipes-sota/aktualizr/`(`aktualizr_git.bb`、`aktualizr-device-prov.bb`、`aktualizr-device-prov-hsm.bb`、`aktualizr-shared-prov*.bb`、`aktualizr-uboot-env-rollback.bb`及其安装的`30-rollback.toml`)
- **3.A/B切换与回滚实现**:downstream(maili)`src/bootctrl/abctl/`(`libabctl.cpp`/`abctl.cpp`,命令`--set_active`/`--boot_slot`/`--set_success`/`--set_unbootable`/`--set_priority`)、`ab-updater.service`、`ab-symlink.service`;downstream(maili):`src/OTA/recovery/update_engine/update_engine.cpp`(`#ifdef TARGET_SUPPORTS_AB`/`#include <libabctl.h>`,`ABC_OTA_STATUS_COOKIE_FILE="/cache/recovery/abc_ota_status"`);`qc/le-ota.lnx/cd/cd.xml`(`oem-recovery`/`recovery`/`recovery-ab`三个包);QLI2.0`aktualizr-uboot-env-rollback.bb`(u-boot bootcount触发单一rootfs的OSTree deploy回滚,`inherit allarch`、无`COMPATIBLE_MACHINE`限制,与MACHINE无绑定)
- **4.opt-in绑定点"是否真的进过CI/构建"核查(本次新增,已实测确认,比SELinux opt-in模式更进一步的发现)**:
  - 对`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`三层仓库分别执行`grep -rn "sota" */.github/workflows`(逐一读取三层的`build-yocto.yml`/`test.yml`/`test-distro.yml`/`pr.yml`/`push.yml`/`nightly-build.yml`全文),**零匹配**——三层全部编译矩阵(`compile`/`compile_warm_up`)里出现过的`distro.name`只有`nodistro`/`qcom-distro`/`qcom-distro-catchall`/`debug`/`performance`/`qcom-distro-dpdk`/`qcom-distro-kvm`/`qcom-distro-sdk`/`qcom-distro-multimedia-image`(meta-qcom)与`qcom-robotics-distro`/`qcom-robotics-distro-catchall`/`debug`/`performance`(meta-qcom-robotics-sdk),从未出现`qcom-distro-sota`/`qcom-robotics-distro-sota`
  - `git log`时间线(分别在`meta-qcom`、`meta-qcom-distro`两个repo执行):`meta-qcom`新增`ci/qcom-distro-sota.yml`——`1d42e5b7`,2025-11-26;`meta-qcom-distro`新增`conf/distro/qcom-distro-sota.conf`——`be15846`,2025-11-26,最后一次改动`dd38a45 conf/qcom-distro-sota: change DISTRO_FEATURES_BACKFILL_CONSIDERED`,2026-04-02;CI矩阵重写`e383e94 Another view on meta-qcom-distro CI (#172)`,2026-03-05(**晚于**sota首次加入);当前HEAD 2026-06-24。即该distro variant存在满7个月、期间CI矩阵被重写过一次,重写后仍未纳入——是"排期多次仍未纳入"而非"太新还没排期"
  - 本仓库内唯一一次真实完整构建(`0817/build/conf/local.conf`:`MACHINE ??= "iq-9075-evk"`,`DISTRO ??= "qcom-robotics-ros2-jazzy"`,经`qcom-robotics-ros2-jazzy.conf`→`require qcom-distro.conf`→`qcom-base.inc`链路确认)同样不含sota
  - 结论:**无法在当前代码库快照里找到"实际构建时真的require了`qcom-distro-sota.conf`的具体机型"**,这本身就是取证结果,不应回避或凭空指定一个机型
- **5.两个具体机型的完整性校验状态核对(本次新增,已实测确认,是本主题最核心的证据补充,复用Distro_Version已验证的同一对机型)**:
  - **8950-pebble(downstream(maili))**:`DISTRO=qti-distro-camerastack-debug`(Distro_Version已用`build-qti-distro-camerastack-debug/conf/auto.conf`实测确认真实构建);本次新增核实该机型buildhistory`build-qti-distro-camerastack-debug/buildhistory/images/pebble/glibc/qti-multimedia-image/`——`image-info.txt`的`IMAGE_INSTALL`显式含`recovery-ab`,`installed-package-names.txt`中`grep -i "abctl|recovery-ab|verity|avb"`真实命中`abctl`、`recovery-ab`两个包(已装),**未命中任何verity/avb相关包**;进一步查`poky/meta-qti-bsp/conf/machine/pebble.conf`第194行`MACHINE_FEATURES += "qti-ab-boot qti-audio qti-video qti-adsp qti-cdsp fastrpc"`(qti-ab-boot真实生效)、第160行`MACHINE_FEATURES += "dm-verity-none"`(显式选择"无dm-verity"变体),且全文未见`qti-avb`——**这台被钉定的真实机型本身dm-verity/AVB均未启用**
  - **iq-9075-evk(QLI2.0)**:`DISTRO=qcom-distro`经官方CI矩阵确认真实构建(Distro_Version已实测);本次新增核实该机型buildhistory`0817/build/buildhistory/images/iq_9075_evk/glibc/qcom-robotics-image/`——`image-info.txt`确认`DISTRO = qcom-robotics-ros2-jazzy`,`installed-package-names.txt`中`grep -i "ostree|aktualizr|verity|avb|abctl"`命中的两条`pipewire-modules-avb`/`pipewire-spa-plugins-avb`经核实是音视频桥接协议AVB(与Android Verified Boot无关的误报),**真实业务命中数为0**——这台真实构建的镜像既没有OTA(ostree/aktualizr)组件,也没有dm-verity/AVB相关组件
  - **交叉证据(证明dm-verity/AVB在downstream(maili)侧是真实被其他量产机型使用的能力,不是从未启用的摆设代码,用以避免"pebble没启用⇒downstream(maili)整体没有这个能力"的误判)**:`poky/meta-qti-bsp/conf/machine/sxrneo.conf`——`MACHINE_FEATURES += "...dm-verity-initramfs-v2..."`,`KERNEL_CMD_PARAMS = "${CONSOLE_PARAM} verity=enabled"`未被移除(移除逻辑仅在检测到`dm-verity-none`时触发,sxrneo没有该token),另有`GENERATE_AB_OTA_PACKAGE = "1"`与`qti-abc-boot`(A/B/C boot)——真实启用dm-verity;`poky/meta-qti-bsp/conf/machine/seraph.conf`——`MACHINE_FEATURES += "...qti-avb..."`,`KERNEL_CMD_PARAMS:append`按`qti-avb`条件追加`" avb-verity=enabled systemd.setenv=SLOT_SUFFIX=_a"`——真实启用AVB
  - 选择逻辑证据:`poky/meta-qti-bsp/classes/qimage.bbclass`——`QIMGCLASSES += "${@bb.utils.filter('MACHINE_FEATURES', 'dm-verity-none dm-verity-bootloader dm-verity-initramfs dm-verity-initramfs-v2 dm-verity-initramfs-v3 dm-verity-cpio-cmdline', d)}"`+`QIMGCLASSES += "${@bb.utils.contains('MACHINE_FEATURES', 'qti-avb', 'qimage-vbmeta avb-verity-initramfs', '', d)}"`——证实downstream(maili)的dm-verity/AVB本身也是逐机型`MACHINE_FEATURES`级opt-in(7个bbclass互斥选择,`dm-verity-none.bbclass`自带`CONFLICT_MACHINE_FEATURES += "dm-verity-bootloader dm-verity-initramfs"`),不是全系强制默认开启
  - **这一步的定性(精确化,不是纠错)**:P0结论讲的是"架构能力是否存在、能否被任意机型接入",而不是"某一台设备出厂配置是否勾选"——downstream(maili)侧能力真实存在(sxrneo/seraph等真实机型在用)且任何团队都能通过一行`MACHINE_FEATURES`配置接入;QLI2.0侧`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`里连对应bbclass实现都不存在(`meta-security`层有实现但零qcom recipe inherit),没有"加一行配置"就能打开的开关——这是能力层面"消失"与机型层面"未勾选"的本质区别,不因pebble这台钉定机型本身的基线状态而减弱
  - 与第4点合观:QLI2.0侧同时存在"OTA替代路径(`qcom-distro-sota`)零构建记录"与"完整性校验能力架构级消失"两个未验证/缺失项,双重叠加,但**不弱化**"影响与风险"节P0的严重性表述(P0讲的是完整性校验机制整体消失这一件事本身,不因sota路径未验证而升级或降级,只是提供额外背景)
- **6.差分/升级包生成能力**:downstream(maili)`build/tools/full_ota.sh`、`build/tools/incremental_ota.sh`(同时存在,原生支持全量/差分两种打包路径)、`build/tools/releasetools/ota_from_target_files.py`;QLI2.0 OSTree对象级去重,`grep -rn "static.delta" meta-updater`只命中ostree自身源码文件名,未见recipe/配置层启用static-deltas痕迹
- **7.服务端信任模型与首刷边界**:downstream(maili)无强制TUF后端,OTA包可自建HTTP服务器分发,recovery侧校验签名zip;QLI2.0需要Uptane/TUF兼容服务端(HERE OTA Connect或自建aktualizr后端),涉及director/image repo、root/targets元数据签名体系;首次刷机均走QDL/EDL,不受OSTree影响(边界见明确排除)
- **8.成熟度佐证(负面案例)**:`qcom-distro-sota`从`be15846`(2025-11-26新增)到`dd38a45`(2026-04-02最后改动)约4个月4次改动,且CI矩阵重写(`e383e94`,2026-03-05)后仍未纳入编译/测试矩阵——判定为"实验期/未经生产验证"阶段,不能类比Distro_Version"582 commit已验证范式"的结论方向
- **交叉引用文档**:output/Code_Composition/Patch_Management/Patch_Management.md(3个systemd补丁去向)、output/Boot_Architecture/Bootargs/Bootargs.md(cmdline无verity参数)、output/Boot_Architecture/Partition_Layout/Partition_Layout.md(Android安全HAL分区消失、单一rootfs分区)、output/System_Architecture/Distro_Version/Distro_Version.md(8950-pebble/iq-9075-evk机型钉定的原始出处)

- **已验证的检索方式**:
  - `grep -rln "abctl\|libabctl" meta-qcom meta-qcom-distro meta-updater` 零匹配——确认abctl机制在QLI2.0完全不存在的标准模板
  - 全局检索`verity=enabled`、`arg_usr_verity`零匹配——从cmdline参数侧交叉验证dm-verity消失
  - `grep -rln "dm-verity-img\|ima-evm-rootfs" meta-qcom meta-qcom-distro` 零匹配——确认meta-security里现成的完整性校验class未被任何qcom镜像recipe inherit,是判定"能力人在场但没上岗"的标准取证方式
  - `grep -rn "static.delta" meta-updater` 只命中ostree自身源码文件名——用于判断recipe/配置层面有没有主动生成/启用static-deltas(区分"libostree自带能力"与"本项目实际启用")
  - `grep -rn "sota" */.github/workflows`(三层仓库逐一执行)零匹配——判定"某distro variant是否真的进过CI矩阵"的标准取证方式,比只看"专属ci yml文件是否存在"更严格
  - 读取`meta-updater/README.adoc`原文描述(如"OSTree is a tool for atomic full file system upgrades...sharing files with the same contents across file system deployments")作为官方文档交叉验证依据
  - 读取`qc/le-ota.lnx/cd/cd.xml`确认recovery-ab组件包清单;读取`update_engine.cpp`头部宏定义(`TARGET_SUPPORTS_AB`/`libabctl.h`)判断其是自研封装还是Google原生实现
  - 读取具体机型`build*/buildhistory/images/<machine>/glibc/<image>/installed-package-names.txt`并`grep -i`关键字——机型级"实际安装了什么"的证据,强度高于源码级`grep`(源码级只能证明"代码库里有没有",buildhistory能证明"这台机型的这次真实构建有没有装进去"),但要注意区分误报(如"avb"命中pipewire-modules-avb这类同名不同义的包)

- **已知易错点/纠错记录**:
  - README.md《曾纠正过的结论》表未出现本主题相关条目,文档内部亦未见"初步判断→核实后结论"格式的正式纠错记录。(暂无纠错记录;下方两条新增内容均定性为"精确化",不触发规则4)
  - 文档内曾有两处标注为"推测,待核实"(因本地网络环境无法直连`ostreedev/ostree`官方文档),现已用Bash `curl`直连`ostreedev.github.io`存档4份官方页面(`reference/Platform_Features/OTA_Mechanism/`:`ostree_introduction.html`/`ostree_repo.html`/`ostree_copying-deltas.html`/`ostree_formats.html`,2026-09-09存档,WebFetch仍因域名安全策略被拦截、改用curl)核实完毕:①`static-deltas`是否能达到接近bsdiff的字节级差分能力——**已解除推测,确认成立**,`ostree_formats.html`原文"These deltas are targeted to be a delta between two specific commit objects, including 'bsdiff' and 'rsync-style' deltas within a content object"明确用bsdiff描述该机制;②OSTree pull是否支持HTTP Range分块续传——**已核实是官方架构级文档确实未覆盖该实现细节**(对4份存档页面全文检索`Range`/`resume`/`resumable`/`interrupted download`,零命中),不是网络不可达查不到,若需确认需查libostree源码或更底层实现文档,不再标注"网络受限待核实"。
  - 方法论易错点:看到`meta-security`层存在完整的dm-verity/IMA-EVM实现,容易直接误判为"QLI2.0已有等价完整性校验能力";必须再交叉检查该class是否被qcom镜像recipe实际inherit(本文档用`grep`零命中证实未启用)才能下结论,这是本文档得出P0级安全风险判断的关键方法论,复核时不能只看"层是否存在"。
  - **精确化(非纠错)①**:"对应独立CI作业`meta-qcom/ci/qcom-distro-sota.yml`单独存在"这一表述容易让人误读为"有实际在跑的CI job"——精确表述应为"该kas yml文件在`meta-qcom`与`meta-qcom-distro`两层仓库都存在,但从未出现在任何`.github/workflows`的编译/测试矩阵条目里,是零构建记录的opt-in配置"。原表述并非事实性错误(文件确实独立存在),只是不够精确,不构成规则4意义上的"先前判断被推翻",故不进入正式纠错记录、不同步README纠错表。
  - **精确化(非纠错)②**:容易误读"downstream(maili)的dm-verity/AVB默认覆盖全系"——实际上downstream(maili)的dm-verity/AVB本身也是逐机型`MACHINE_FEATURES`级opt-in(见第5点),被钉定的pebble机型本身选择了`dm-verity-none`且未启用`qti-avb`。这不推翻P0结论(P0讲的是架构能力整体消失,不是单机型出厂状态),只是论证角度从"单机型状态"变成"跨机型交叉证明能力真实存在但架构层面在QLI2.0侧不可复现",复核时不能只看钉定机型是否勾选就误判整条产品线的能力边界,也不应因此弱化"影响与风险"节的P0严重性表述。

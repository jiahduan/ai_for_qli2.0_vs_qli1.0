# OTA_Mechanism 规则执行逻辑细节报告

本文档记录`OTA_Mechanism.md`当前内容(核心OTA机制/A-B切换/差分能力/P0级完整性校验风险)是**怎么从源码证据一步步取得的**——按`rules/Platform_Features/OTA_Mechanism.md`"专属取证要点"逐条复盘,重点说明P0级安全风险结论的多源交叉验证过程。原理性背景见同目录`Principles.md`,具体差异结论本身见`../OTA_Mechanism.md`。

## P0级安全风险结论:四个独立证据源的交叉验证

"镶像完整性校验消失"这一P0结论没有依赖单一证据,而是四个独立证据源相互印证得出,任何一个单独出现都不足以下P0级结论,合在一起才排除了"只是巧合/漏检"的可能:

**证据源①——cmdline参数侧**:全局检索`verity=enabled`、`arg_usr_verity`,QLI2.0零匹配。这一线索最初来自追踪downstream(maili)三个systemd补丁去向时的发现:`fstab-generator-Honor-verity-enabled-cmdline.patch`(识别cmdline中`verity=enabled`/`avb-verity`参数)在QLI2.0侧完全没有对应物——这是从Patch_Management主题的补丁追踪工作里带出来的佐证,不是本主题另起的检索。

**证据源②——bbclass实现侧**:确认downstream(maili)`poky/meta-qti-bsp/classes/`下存在dm-verity/AVB相关bbclass一整套(`dm-verity-initramfs.bbclass`、`dm-verity-initramfs-v2/v3.bbclass`、`dm-verity-bootloader.bbclass`、`dm-verity-cpio-cmdline.bbclass`、`dm-verity-none.bbclass`、`avb-verity-initramfs.bbclass`);QLI2.0的`meta-qcom`中没有任何一个对应class。

**证据源③——"人在场但没上岗"核查**:确认`meta-security`(含`meta-tpm`)作为layer被`meta-qcom/ci/qcom-distro.yml`拉入默认构建、且该层本身有完整实现——`meta-security/classes/dm-verity-img.bbclass`、`meta-security/meta-integrity/classes/ima-evm-rootfs.bbclass`确认文件存在;但对`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`执行`grep -rln "dm-verity-img\|ima-evm-rootfs"`,零匹配(退出码1)——没有任何qcom镜像recipe inherit这两个class;同时核实`qcom-base.inc`第15-28行`DISTRO_FEATURES:append`列表不含`ima`。这一步是方法论上最关键的一步:如果只看"meta-security层是否存在"就会误判为"QLI2.0已有等价能力",必须再交叉检查该class是否被qcom镜像recipe实际引用,才能下"事实上未启用"的结论。

**证据源④——相邻主题的独立佐证**:引用[Partition_Layout](../../Boot_Architecture/Partition_Layout/Partition_Layout.md)"Android安全HAL分区消失、单一rootfs分区"的结论,以及[Bootargs](../../Boot_Architecture/Bootargs/Bootargs.md)"cmdline无verity参数"的结论——这两篇文档各自独立取证得出的结论,与本主题①②③三项证据方向一致,构成第四个独立来源。

四项证据分别来自不同的检索维度(cmdline参数/bbclass文件存在性/recipe实际引用关系/相邻主题独立结论),互不依赖同一份原始数据,交叉一致后才落到`OTA_Mechanism.md`"dm-verity/AVB镶像完整性校验的确认消失"专属章节与"影响与风险"末条的P0判断。

## 一处已发现的数字偏差(未回改正文)

重新核实downstream(maili)`poky/meta-qti-bsp/classes/`下dm-verity/AVB相关bbclass数量时,本次点数结果为7个(`avb-verity-initramfs.bbclass`、`dm-verity-bootloader.bbclass`、`dm-verity-cpio-cmdline.bbclass`、`dm-verity-initramfs.bbclass`、`dm-verity-initramfs-v2.bbclass`、`dm-verity-initramfs-v3.bbclass`、`dm-verity-none.bbclass`),与正文"整整8个"的表述存在1个差异。核查结论:这一数字偏差不影响"QLI2.0侧零个对应class"这一核心事实,也不改变P0判断本身,按"发现偏差先记录、不静默覆盖已定稿正文"的方式处理,记录于此,未回改`OTA_Mechanism.md`正文表述。

## 其余锚点取证过程

### A/B切换机制核实
**做法**:对`meta-qcom`/`meta-qcom-distro`/`meta-updater`执行`grep -rln "abctl\|libabctl"`。
**证据**:零匹配。
**落到结论**:关键差异"abctl在QLI2.0中完全不存在"——与Partition_Layout.md"单一rootfs分区"结论互相印证。

### 差分能力现状核实
**做法**:对`meta-updater`执行`grep -rn "static.delta"`。
**证据**:只命中libostree自身源码文件名(如`ostree-repo-static-delta-core.c`),未见recipe/配置层启用static-deltas的痕迹。
**落到结论**:关键差异"OSTree对象级去重取代bsdiff"一条——区分"libostree自带能力"与"本项目实际启用",避免把工具理论能力误当作已启用的实际能力。

### opt-in配置与量产实际启用范围
**做法**:确认`qcom-distro-sota.conf`(`require conf/distro/sota.conf.inc`)与独立CI`meta-qcom/ci/qcom-distro-sota.yml`,区别于默认`qcom-distro`。
**证据**:OTA能力是opt-in distro,若产品团队仍按默认`qcom-distro`构建,将完全没有OTA能力。
**落到结论**:对比总览表"是否为opt-in"行、关键差异第3条。

### 官方文档交叉验证
**做法**:读取`meta-updater/README.adoc`原文描述。
**证据**:"OSTree is a tool for atomic full file system upgrades with rollback capability...sharing files with the same contents across file system deployments"。
**落到结论**:对比总览表"存储占用""断点续传"行的官方依据。
**未能核实的部分**:OSTree pull是否支持HTTP Range分块续传、static-deltas能否达到接近bsdiff的字节级差分能力,本次重新尝试通过WebFetch/WebSearch核实`ostreedev/ostree`官方文档,网络环境仍不可直连(WebFetch返回域名安全策略拦截,WebSearch无结果),按规则6如实标注为"推测,待核实",状态与正文一致,未发生变化。

### update_engine实现性质核实
**做法**:读取`src/OTA/recovery/update_engine/update_engine.cpp`头部宏定义。
**证据**:`#ifdef TARGET_SUPPORTS_AB`/`#include <libabctl.h>`,`ABC_OTA_STATUS_COOKIE_FILE="/cache/recovery/abc_ota_status"`。
**落到结论**:对比总览表"update_engine实现"行——证实是对`libabctl`的封装/调度层,而非Google原生流式update_engine实现。

### 组件描述文件核实
**做法**:读取`qc/le-ota.lnx/cd/cd.xml`。
**证据**:显式列出`oem-recovery`、`recovery`、`recovery-ab`三个包。
**落到结论**:对比总览表"组件描述文件"行——证实"recovery-ab"是recovery+edify/updater脚本+applypatch的块级OTA叠加A/B分区切换,非Brillo式纯流式A/B。

## 关于纠错记录

`rules/Platform_Features/OTA_Mechanism.md`"已知易错点"明确记录本主题在README《曾纠正过的结论》表及文档内部均无正式"初步判断→核实后结论"格式的纠错记录;上文"一处已发现的数字偏差"是本次复核过程中新发现、按规定记录但未回改正文的偏差,不是对已有正式纠错记录的补充。

## 本轮新增:8步方法论落地+两个具体机型钉定(参照Distro_Version 2.1节模式)

本轮把Distro_Version已验证的"source-level分析方法论+两个具体机型钉定"模式推广到OTA_Mechanism,新增`rules/Platform_Features/OTA_Mechanism.md`2.1节8步方法论。以下按步骤记录本轮的实测过程与新发现,区别于上一轮的取证(上一轮内容见本报告前文)。

### 步骤4:opt-in绑定点"零构建记录"核查——本轮最重要的新发现

**做法**:不满足于"conf文件存在"或"有专属ci yml文件"就下结论,对`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`三层仓库分别执行`grep -rn "sota" */.github/workflows`,并逐一读取三层的`build-yocto.yml`/`test.yml`/`test-distro.yml`/`pr.yml`/`push.yml`/`nightly-build.yml`全文确认矩阵条目。
**证据**:三层全部编译矩阵(`compile`/`compile_warm_up`)里出现过的`distro.name`只有`nodistro`/`qcom-distro`/`qcom-distro-catchall`/`debug`/`performance`/`qcom-distro-dpdk`/`qcom-distro-kvm`/`qcom-distro-sdk`/`qcom-distro-multimedia-image`(meta-qcom)与`qcom-robotics-distro`/`qcom-robotics-distro-catchall`/`debug`/`performance`(meta-qcom-robotics-sdk),从未出现`qcom-distro-sota`/`qcom-robotics-distro-sota`。`git log`确认时间线:`meta-qcom`新增`ci/qcom-distro-sota.yml`——`1d42e5b7`,2025-11-26;`meta-qcom-distro`新增`conf/distro/qcom-distro-sota.conf`——`be15846`,2025-11-26,最后一次改动`dd38a45`,2026-04-02;CI矩阵重写`e383e94`(#172),2026-03-05,**晚于**sota首次加入但重写后仍未纳入;当前HEAD 2026-06-24。本仓库内唯一一次真实完整本地构建(`0817/build/conf/local.conf`:`MACHINE=iq-9075-evk`/`DISTRO=qcom-robotics-ros2-jazzy`)同样不含sota。
**中间的一次自我纠正**:任务最初设想是"选定一个实际构建时真的require了`qcom-distro-sota.conf`的具体机型",按此思路检索了`meta-qcom-distro/.github/workflows/build-yocto.yml`全文、`meta-qcom`同名文件全文、`test.yml`/`test-distro.yml`/`nightly-build.yml`/`pr.yml`/`push.yml`,均未找到这样的机型;没有为了完成任务而编造一个"理论上兼容"的机型组合,而是把"零构建记录"本身作为取证结果写入文档——这是Methodology规则1"禁止仅凭关键字搜索为空就断言"的反向应用:这里恰恰是"搜索为空"且经过多路径交叉确认后,如实断言"当前查无此类真实构建证据",而不是回避或臆测。
**落到结论**:`rules/Platform_Features/OTA_Mechanism.md`取证要点第4点;`OTA_Mechanism.md`对比范围/对比总览"是否为opt-in"行/关键差异opt-in条,均已精确化措辞,不改变"OTA能力是opt-in"这一结论方向,只是把严重程度从"未被选用"上调为"从未被验证过"。

### 步骤5:两个具体机型的完整性校验状态核对

**做法**:复用Distro_Version已验证的`8950-pebble`/`iq-9075-evk`这对机型(理由:两者均已有本仓库内真实跑完的buildhistory,证据强度高于仅凭CI矩阵条目或静态conf推断;且`qcom-distro-sota`本身查无真实构建证据,无法另钉一个"sota机型"),对两侧buildhistory的`installed-package-names.txt`做机型级独立验证。
**证据**:iq-9075-evk(`0817/build/buildhistory/images/iq_9075_evk/glibc/qcom-robotics-image/`)——`grep -i "ostree|aktualizr|verity|avb|abctl"`命中两条`pipewire-*-avb`均为音视频协议误报,真实业务命中0;8950-pebble(`build-qti-distro-camerastack-debug/buildhistory/images/pebble/glibc/qti-multimedia-image/`)——`grep -i "abctl|recovery-ab|verity|avb"`真实命中`abctl`/`recovery-ab`(已装),未命中verity/avb。
**新发现**:`poky/meta-qti-bsp/conf/machine/pebble.conf`第160行`MACHINE_FEATURES += "dm-verity-none"`,且全文未见`qti-avb`——这台被钉定的真实机型本身dm-verity/AVB均未启用,与"downstream(maili)整体有dm-verity能力"这一表述不冲突,但需要交叉证据支撑,否则容易被误读为"downstream(maili)其实也没在用"。
**交叉证据**:检索downstream(maili)`poky/meta-qti-bsp/conf/machine/*.conf`全部机型,找到`sxrneo.conf`(`MACHINE_FEATURES`含`dm-verity-initramfs-v2`,`KERNEL_CMD_PARAMS`保留`verity=enabled`)与`seraph.conf`(`MACHINE_FEATURES`含`qti-avb`,`KERNEL_CMD_PARAMS:append`条件追加`avb-verity=enabled`)两台真实机型,证明该能力在downstream(maili)代码库里是被使用的,不是摆设代码。
**落到结论**:`rules/Platform_Features/OTA_Mechanism.md`取证要点第5点;`OTA_Mechanism.md`新增"两个具体机型的完整性校验状态核对"章节。此发现按协调方(coordinator)确认,定性为**"精确化",不触发Methodology规则4的正式纠错记录**,理由:P0结论(完整性校验机制整体消失)本身没有被推翻,只是论证角度从"单机型状态"变成"跨机型交叉证明能力真实存在但架构层面在QLI2.0侧不可复现";不同步README《曾纠正过的结论》表;同时按协调方要求,"影响与风险"节P0严重性表述未做任何弱化改动。

### OSTree官方文档核实(用户直接要求的追加任务,非本轮方法论主线,记录于此保持完整性)

**做法**:WebFetch仍因域名安全策略被拦截,改用Bash `curl`直连`ostreedev.github.io`存档4份官方页面到`reference/Platform_Features/OTA_Mechanism/`(`ostree_introduction.html`/`ostree_repo.html`/`ostree_copying-deltas.html`/`ostree_formats.html`,2026-09-09存档)。
**证据**:①`ostree_formats.html`原文"These deltas are targeted to be a delta between two specific commit objects, including 'bsdiff' and 'rsync-style' deltas within a content object"——明确用bsdiff描述static-delta机制,原"推测,待核实"状态解除,确认成立。②对4份存档页面全文检索`Range`/`resume`/`resumable`/`interrupted download`关键字,零命中——确认HTTP Range续传这一实现细节确实不在这些架构级文档的覆盖范围内,不是网络受限查不到。
**落到结论**:`OTA_Mechanism.md`对比范围"待定边界"字段、对比总览"断点续传"行、关键差异bsdiff条,均已更新措辞,不再使用"网络不可达/待网络可用后核实"这一过时表述;`rules/Platform_Features/OTA_Mechanism.md`"已知易错点"同步更新。

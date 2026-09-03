# OTA_Mechanism 规则执行逻辑细节报告

本文档记录`OTA_Mechanism.md`当前内容(核心OTA机制/A-B切换/差分能力/P0级完整性校验风险)是**怎么从源码证据一步步取得的**——按`rules/Platform_Features/OTA_Mechanism.md`"专属取证要点"逐条复盘,重点说明P0级安全风险结论的多源交叉验证过程。原理性背景见同目录`Principles.md`,具体差异结论本身见`../OTA_Mechanism.md`。

## P0级安全风险结论:四个独立证据源的交叉验证

"镶像完整性校验消失"这一P0结论没有依赖单一证据,而是四个独立证据源相互印证得出,任何一个单独出现都不足以下P0级结论,合在一起才排除了"只是巧合/漏检"的可能:

**证据源①——cmdline参数侧**:全局检索`verity=enabled`、`arg_usr_verity`,QLI2.0零匹配。这一线索最初来自追踪QLI1.0三个systemd补丁去向时的发现:`fstab-generator-Honor-verity-enabled-cmdline.patch`(识别cmdline中`verity=enabled`/`avb-verity`参数)在QLI2.0侧完全没有对应物——这是从Patch_Management主题的补丁追踪工作里带出来的佐证,不是本主题另起的检索。

**证据源②——bbclass实现侧**:确认QLI1.0`poky/meta-qti-bsp/classes/`下存在dm-verity/AVB相关bbclass一整套(`dm-verity-initramfs.bbclass`、`dm-verity-initramfs-v2/v3.bbclass`、`dm-verity-bootloader.bbclass`、`dm-verity-cpio-cmdline.bbclass`、`dm-verity-none.bbclass`、`avb-verity-initramfs.bbclass`);QLI2.0的`meta-qcom`中没有任何一个对应class。

**证据源③——"人在场但没上岗"核查**:确认`meta-security`(含`meta-tpm`)作为layer被`meta-qcom/ci/qcom-distro.yml`拉入默认构建、且该层本身有完整实现——`meta-security/classes/dm-verity-img.bbclass`、`meta-security/meta-integrity/classes/ima-evm-rootfs.bbclass`确认文件存在;但对`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`执行`grep -rln "dm-verity-img\|ima-evm-rootfs"`,零匹配(退出码1)——没有任何qcom镜像recipe inherit这两个class;同时核实`qcom-base.inc`第15-28行`DISTRO_FEATURES:append`列表不含`ima`。这一步是方法论上最关键的一步:如果只看"meta-security层是否存在"就会误判为"QLI2.0已有等价能力",必须再交叉检查该class是否被qcom镜像recipe实际引用,才能下"事实上未启用"的结论。

**证据源④——相邻主题的独立佐证**:引用[Partition_Layout](../../Boot_Architecture/Partition_Layout/Partition_Layout.md)"Android安全HAL分区消失、单一rootfs分区"的结论,以及[Bootargs](../../Boot_Architecture/Bootargs/Bootargs.md)"cmdline无verity参数"的结论——这两篇文档各自独立取证得出的结论,与本主题①②③三项证据方向一致,构成第四个独立来源。

四项证据分别来自不同的检索维度(cmdline参数/bbclass文件存在性/recipe实际引用关系/相邻主题独立结论),互不依赖同一份原始数据,交叉一致后才落到`OTA_Mechanism.md`"dm-verity/AVB镶像完整性校验的确认消失"专属章节与"影响与风险"末条的P0判断。

## 一处已发现的数字偏差(未回改正文)

重新核实QLI1.0`poky/meta-qti-bsp/classes/`下dm-verity/AVB相关bbclass数量时,本次点数结果为7个(`avb-verity-initramfs.bbclass`、`dm-verity-bootloader.bbclass`、`dm-verity-cpio-cmdline.bbclass`、`dm-verity-initramfs.bbclass`、`dm-verity-initramfs-v2.bbclass`、`dm-verity-initramfs-v3.bbclass`、`dm-verity-none.bbclass`),与正文"整整8个"的表述存在1个差异。核查结论:这一数字偏差不影响"QLI2.0侧零个对应class"这一核心事实,也不改变P0判断本身,按"发现偏差先记录、不静默覆盖已定稿正文"的方式处理,记录于此,未回改`OTA_Mechanism.md`正文表述。

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

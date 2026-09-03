# Platform Features — OTA Mechanism

## 对比范围

- **覆盖**:
  - 核心OTA机制架构对比:QLI1.0`src/OTA/`(AOSP`bootable/recovery`+`build/tools/releasetools`+`system/update_engine`移植,`recovery/{applypatch,edify,updater,minzip,minui,bootloader_message,update_verifier,otafault}`)+`external/bsdiff/`、`external/libdivsufsort/` vs QLI2.0`meta-updater/README.adoc`、`recipes-sota/ostree`、`recipes-sota/aktualizr/`(`aktualizr_git.bb`等)。
  - A/B切换实现对比:QLI1.0`src/bootctrl/abctl/`(`libabctl.cpp`/`abctl.cpp`,`ab-updater.service`/`ab-symlink.service`)vs QLI2.0`aktualizr-uboot-env-rollback.bb`(u-boot bootcount触发单一rootfs回滚);本次重新执行`grep -rln "abctl\|libabctl" meta-qcom meta-qcom-distro meta-updater`,零匹配,与正文结论一致。
  - 升级包生成/差分能力对比:QLI1.0`build/tools/full_ota.sh`/`incremental_ota.sh`/`releasetools/ota_from_target_files.py` vs QLI2.0 OSTree对象级去重现状;重新执行`grep -rn "static.delta" meta-updater`,只命中libostree自身源码文件名(如`ostree-repo-static-delta-core.c`),未见recipe/配置层启用static-deltas的痕迹,与正文结论一致。
  - opt-in配置与量产实际启用范围核实:`qcom-distro-sota.conf`(`require conf/distro/sota.conf.inc`)+独立CI`meta-qcom/ci/qcom-distro-sota.yml`,区别于默认`qcom-distro`。
  - 镶像完整性校验(dm-verity/AVB)消失的确认与"人在场没上岗"排查(P0级安全风险结论所在,本次逐项重新取证):
    - QLI1.0侧`poky/meta-qti-bsp/classes/`下dm-verity/AVB相关bbclass本次重新点数为7个(`avb-verity-initramfs.bbclass`、`dm-verity-bootloader.bbclass`、`dm-verity-cpio-cmdline.bbclass`、`dm-verity-initramfs.bbclass`、`dm-verity-initramfs-v2.bbclass`、`dm-verity-initramfs-v3.bbclass`、`dm-verity-none.bbclass`),与正文"整整8个"的表述有偏差(记录见本报告末尾,未改动正文)。
    - QLI2.0侧全局`grep -rln "verity=enabled\|arg_usr_verity"`对`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`/`meta-security`/`meta-selinux`/`meta-virtualization`/`meta-updater`/`meta-audioreach`/`oe-core`/`meta-openembedded`/`meta-ros`/`meta-lts-mixins`/`bitbake`重新检索,零匹配。
    - `meta-security/classes/dm-verity-img.bbclass`、`meta-security/meta-integrity/classes/ima-evm-rootfs.bbclass`本次重新确认文件存在;`grep -rln "dm-verity-img\|ima-evm-rootfs" meta-qcom meta-qcom-distro meta-qcom-robotics-sdk`重新执行,零匹配(退出码1)。
    - `meta-qcom-distro/conf/distro/include/qcom-base.inc`第15-28行`DISTRO_FEATURES:append`列表(efi/glvnd/kvm/minidebuginfo/opencl/overlayfs/pam/pni-names/polkit/security/tpm2/virtualization/wifi/x11)本次重新读取确认不含`ima`。
    - 以上4项独立证据源均与正文结论一致,P0级安全风险判断维持不变。
  - 服务端依赖体系对比:Uptane/TUF Director/Image Repo(或HERE OTA Connect)vs QLI1.0自建HTTP签名zip分发。
  - 与首刷流程的边界确认(仅确认关系,不深入QDL/EDL工具链细节):首次刷机走QDL/Firehose,不受OSTree影响,OSTree只改变"刷机后"的升级路径。
- **明确排除**:
  - 首次量产刷机QDL/EDL工具链与流程本身 ——见[Flash_Process](../Flash_Process/Flash_Process.md)
  - Android安全HAL分区/单一rootfs分区结构本身 ——见[Partition_Layout](../../Boot_Architecture/Partition_Layout/Partition_Layout.md)
  - cmdline层面verity参数消失的证据细节 ——见[Bootargs](../../Boot_Architecture/Bootargs/Bootargs.md)
  - QLI1.0的3个systemd补丁去向的完整追踪过程 ——见[Patch_Management](../../Code_Composition/Patch_Management/Patch_Management.md)
- **待定边界**:(无,已核实。文档内两处"推测,待核实"标注——①OSTree pull是否支持HTTP Range分块续传;②static-deltas能否达到接近bsdiff的字节级差分能力——属于证据不足/网络不可达导致的验证状态未决,不是文档归属不明确;本次重新尝试通过WebFetch/WebSearch核实ostreedev/ostree官方文档,网络环境仍不可直连(WebFetch返回域名安全策略拦截,WebSearch无结果),状态与正文一致,未发生变化。)

## 对比总览

| 维度 | QLI1.0(Android式recovery/A-B块级OTA) | QLI2.0(标准OSTree+aktualizr) |
|---|---|---|
| 核心组件 | `src/OTA/`,完整移植的AOSP`bootable/recovery`+`build/tools/releasetools`+`system/update_engine`:`recovery/{applypatch,edify,updater,minzip,minui,bootloader_message,update_verifier,otafault}`;`external/bsdiff/`、`external/libdivsufsort/`(bsdiff差分算法) | `meta-updater/README.adoc`:"OSTree is a tool for atomic full file system upgrades with rollback capability...minimizes network bandwidth and data storage footprint by sharing files with the same contents across file system deployments";recipes-sota/ostree、recipes-sota/aktualizr/(`aktualizr_git.bb`、`aktualizr-device-prov.bb`、`aktualizr-device-prov-hsm.bb`、`aktualizr-shared-prov*.bb`、`aktualizr-uboot-env-rollback.bb`) |
| A/B切换实现 | `src/bootctrl/abctl/`: `libabctl.cpp`/`abctl.cpp`提供`--set_active`、`--boot_slot`、`--set_success`、`--set_unbootable`、`--set_priority`等命令;`ab-updater.service`(在sysinit.target阶段执行`abctl --set_success`标记启动成功)、`ab-symlink.service`(在local-fs.target前建立slot符号链接) | `aktualizr-uboot-env-rollback.bb`回滚机制依赖u-boot环境变量标记(bootcount/rollback) |
| 升级包生成 | `build/tools/full_ota.sh`与`incremental_ota.sh`**同时存在**,原生支持全量包与增量(差分)包两种打包路径;`build/tools/releasetools/ota_from_target_files.py`是标准AOSP OTA打包脚本 | 不适用(OSTree原生按对象/blob增量) |
| update_engine实现 | `src/OTA/recovery/update_engine/update_engine.cpp`头部含`#ifdef TARGET_SUPPORTS_AB`/`#include <libabctl.h>`,证实实为对`libabctl`(QLI1.0自研A/B切换库)的封装/调度层,而非Google原生流式update_engine(payload.bin+omaha-like)实现;`ABC_OTA_STATUS_COOKIE_FILE="/cache/recovery/abc_ota_status"` | aktualizr实现Uptane,支持设备认证与provisioning,与OSTree集成,可连接自建后端或HERE OTA Connect |
| 组件描述文件 | `qc/le-ota.lnx/cd/cd.xml`显式列出`oem-recovery`、`recovery`、`recovery-ab`三个包,产出`/usr/bin/{recovery,updater,applypatch,edify}`、`recovery.service`等,证实"recovery-ab"是基于recovery+edify/updater脚本+applypatch的块级OTA,再叠加A/B分区切换(非Google Brillo式纯流式A/B) | 不适用 |
| 是否为opt-in | 否,recovery/bootctrl是核心交付件 | 是,`qcom-distro-sota.conf`(`require conf/distro/sota.conf.inc`;`INITRAMFS_IMAGE="initramfs-ostree-image"`;`DISTRO_NAME:append=" (OTA-enabled)"`;`DISTRO_FEATURES_OPTED_OUT+="ptest"`;`BUILD_OSTREE_REPO_TARBALL="1"`),对应独立CI作业`meta-qcom/ci/qcom-distro-sota.yml`(`distro: qcom-distro-sota`)单独存在 |
| 升级粒度 | 分区镜像整包,或bsdiff文件级差分补丁(zip包+edify脚本) | 文件系统级commit(OSTree硬链接去重,按对象/blob增量) |
| 存储占用 | A/B双分区各占一份完整系统镶像空间(典型2x rootfs) | 通过内容寻址+硬链接跨版本共享未变化文件,理论上占用远低于2x |
| 回滚方式 | abctl分区属性(GPT attribute/优先级+尝试次数),recovery-ab包配合 | OSTree deploy保留多个历史commit,aktualizr-uboot-env-rollback通过u-boot bootcount触发回滚 |
| 断点续传 | 依赖full_ota.sh/incremental_ota.sh生成的整包/差分包一次性下载校验(recovery阶段执行) | OSTree pull按对象/blob增量拉取,未变化对象不重复下载,已按`meta-updater/README.adoc`"sharing files with the same contents across file system deployments"核实;是否支持HTTP Range分块续传属于libostree自身实现细节,本仓库/`reference/`目录均无相应官方文档存档,当前网络环境也无法直连`ostreedev/ostree`官方文档核实,标注为推测,待网络可用后核实 |
| 服务端依赖 | 无强制TUF后端,OTA包可自建HTTP服务器分发,recovery侧校验签名zip | 需要Uptane/TUF兼容服务端(HERE OTA Connect或自建aktualizr后端),涉及director/image repo、root/targets元数据签名体系 |
| 触发/执行环境 | 需重启进入recovery模式执行升级 | aktualizr在线运行时后台拉取、部署,reboot生效但无需独立recovery分区 |
| 是否默认启用 | 是(recovery/bootctrl是核心交付件) | 否(需选择qcom-distro-sota distro变体) |

## dm-verity/AVB镜像完整性校验的确认消失(与本文档强相关)

- 追踪QLI1.0的3个systemd补丁去向时(详见output/Code_Composition/Patch_Management/Patch_Management.md)发现关键佐证:`fstab-generator-Honor-verity-enabled-cmdline.patch`(识别cmdline中`verity=enabled`/`avb-verity`参数)在QLI2.0全局检索`verity=enabled`、`arg_usr_verity`均零匹配。
- **决定性证据**:QLI1.0的`poky/meta-qti-bsp/classes/`下存在整整8个dm-verity相关bbclass(`dm-verity-initramfs.bbclass`、`dm-verity-initramfs-v2/v3.bbclass`、`dm-verity-bootloader.bbclass`、`dm-verity-cpio-cmdline.bbclass`、`dm-verity-none.bbclass`、`avb-verity-initramfs.bbclass`等),构成一整套AVB/dm-verity镶像签名与校验架构。QLI2.0的meta-qcom中没有任何一个对应class。
- 与output/Boot_Architecture/Bootargs/Bootargs.md(cmdline无verity参数)、output/Boot_Architecture/Partition_Layout/Partition_Layout.md(Android安全HAL分区消失)三方证据互相印证——QLI2.0不仅切换了OTA升级机制,还同步移除了整套镶像完整性校验(dm-verity/AVB)机制,这是比"升级机制切换"本身更大的安全架构变化。
- **能力"人在场但没上岗"**:`meta-security`(含`meta-tpm`)其实作为layer被`meta-qcom/ci/qcom-distro.yml`拉入默认构建,该层本身有完整的dm-verity实现(`meta-security/classes/dm-verity-img.bbclass`等)和IMA/EVM完整性度量实现(`meta-security/meta-integrity/classes/ima-evm-rootfs.bbclass`等),但`grep -rln "dm-verity-img\|ima-evm-rootfs" meta-qcom meta-qcom-distro`零匹配——没有任何qcom镜像recipe inherit这两个class,`qcom-base.inc`的`DISTRO_FEATURES:append`里也没有`ima`。结论:当前qcom-distro/qcom-distro-sota量产镜像不启用任何块级/文件级完整性校验,rootfs完整性完全依赖aktualizr的Uptane签名校验(OSTree pull/deploy阶段)。

## 关键差异

- **服务端集成是最大变更点**:QLI1.0的OTA服务端只需托管签名zip包(HTTP/HTTPS),QLI2.0需要一整套Uptane TUF Director/Image Repo基础设施(或采购HERE OTA Connect),这是架构级的服务端重建,不是简单协议适配。
- **首次刷机流程不受OSTree影响**:无论QLI1.0还是QLI2.0,首次量产刷机都走QDL/EDL整机镶像(详见Flash_Process.md),OSTree只改变"第二次及后续升级"的路径——从"重新整包/差分刷写分区"变为"OSTree pull+deploy+reboot"。产线刷机脚本/流程基本不变,但售后/远程升级流程需要重新设计(涉及设备provisioning、TUF密钥管理、aktualizr密钥/证书注入)。
- 由于OTA能力是opt-in distro(`qcom-distro-sota`),若产品团队仍按`qcom-distro`默认配置构建,将完全没有OTA能力,需要显式确认目标产品选用哪个distro。
- QLI1.0的bsdiff差分能力(更小升级包)在QLI2.0里由OSTree对象级去重取代,但两者的"网络流量最优场景"不同:bsdiff针对整文件二进制差分优化更极致,OSTree依赖文件级去重,若某文件整体变化(如内核镶像替换),不启用`static-deltas`时无法做到bsdiff级别的字节差分(`static-deltas`本身理论上可提供接近bsdiff的二进制差分能力,但这一点是libostree官方文档描述的能力,本仓库网络环境无法直连核实,标注为推测)。经核实`grep -rn "static.delta" meta-updater`只命中ostree自身源码文件名(libostree二进制自带能力),meta-updater的recipe/配置里没有任何生成或启用static-deltas的痕迹,目前QLI2.0没有分发过差分包,若要对齐QLI1.0的bsdiff体积水平需要专门立项开发。
- **abctl在QLI2.0中完全不存在**:`grep -rln "abctl\|libabctl" meta-qcom meta-qcom-distro meta-updater`零匹配,与Partition_Layout.md"QLI2.0只有单一rootfs分区"的结论互相印证。`aktualizr-uboot-env-rollback.bb`只安装一个`30-rollback.toml`,让aktualizr利用u-boot bootcount对**单一rootfs的OSTree deploy**做回滚,跟QLI1.0基于abctl的固件槽位(`xbl_a/b`等)A/B切换是完全不同的机制,两者不冲突;但固件槽位在OTA场景下由谁触发A/B判定与回滚,在meta-updater/meta-qcom里都没有找到对应实现,这是output/Boot_Architecture/Partition_Layout/Partition_Layout.md已列出的独立待确认项。

## 影响与风险

- QLI1.0的recovery模式在断电/异常中断时的行为(是否可续传、是否需要重新下载整包)与OSTree pull的容错行为不同,需要针对目标网络环境(车载/嵌入式弱网)做专项验证。
- **镶像完整性校验缺失是新增的P0级安全风险**:dm-verity/AVB整套机制消失后,已核实等价能力(meta-security的dm-verity/IMA-EVM)存在于代码库但未被任何qcom镜像recipe启用(详见上文"能力人在场但没上岗"),当前根文件系统完整性完全依赖aktualizr的Uptane签名校验,并非fs-verity或其它等价机制,需要安全团队评估是否要显式打开这些开关。

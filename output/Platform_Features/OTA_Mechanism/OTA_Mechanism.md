# Platform Features — OTA Mechanism

## 对比范围

- **覆盖**:
  - 核心OTA机制架构对比:downstream(maili)`src/OTA/`(AOSP`bootable/recovery`+`build/tools/releasetools`+`system/update_engine`移植,`recovery/{applypatch,edify,updater,minzip,minui,bootloader_message,update_verifier,otafault}`)+`external/bsdiff/`、`external/libdivsufsort/` vs QLI2.0`meta-updater/README.adoc`、`recipes-sota/ostree`、`recipes-sota/aktualizr/`(`aktualizr_git.bb`等)。
  - A/B切换实现对比:downstream(maili)`src/bootctrl/abctl/`(`libabctl.cpp`/`abctl.cpp`,`ab-updater.service`/`ab-symlink.service`)vs QLI2.0`aktualizr-uboot-env-rollback.bb`(u-boot bootcount触发单一rootfs回滚);本次重新执行`grep -rln "abctl\|libabctl" meta-qcom meta-qcom-distro meta-updater`,零匹配,与正文结论一致。
  - 升级包生成/差分能力对比:downstream(maili)`build/tools/full_ota.sh`/`incremental_ota.sh`/`releasetools/ota_from_target_files.py` vs QLI2.0 OSTree对象级去重现状;重新执行`grep -rn "static.delta" meta-updater`,只命中libostree自身源码文件名(如`ostree-repo-static-delta-core.c`),未见recipe/配置层启用static-deltas的痕迹,与正文结论一致。
  - opt-in配置与量产实际启用范围核实:`qcom-distro-sota.conf`(`require conf/distro/sota.conf.inc`)+独立CI`meta-qcom/ci/qcom-distro-sota.yml`,区别于默认`qcom-distro`;本次进一步核实`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`三层全部`.github/workflows/*.yml`的编译/测试矩阵,`grep -rn "sota"`零命中——该distro variant自2025-11-26新增以来从未被任何官方CI job实际构建或测试过一次,比"opt-in但未被当前一次构建选用"更进一步,详见下文"两个具体机型的完整性校验状态核对"。
  - 镶像完整性校验(dm-verity/AVB)消失的确认与"人在场没上岗"排查(P0级安全风险结论所在,本次逐项重新取证):
    - downstream(maili)侧`poky/meta-qti-bsp/classes/`下dm-verity/AVB相关bbclass本次重新点数为7个(`avb-verity-initramfs.bbclass`、`dm-verity-bootloader.bbclass`、`dm-verity-cpio-cmdline.bbclass`、`dm-verity-initramfs.bbclass`、`dm-verity-initramfs-v2.bbclass`、`dm-verity-initramfs-v3.bbclass`、`dm-verity-none.bbclass`),与正文"整整8个"的表述有偏差(记录见本报告末尾,未改动正文)。
    - QLI2.0侧全局`grep -rln "verity=enabled\|arg_usr_verity"`对`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`/`meta-security`/`meta-selinux`/`meta-virtualization`/`meta-updater`/`meta-audioreach`/`oe-core`/`meta-openembedded`/`meta-ros`/`meta-lts-mixins`/`bitbake`重新检索,零匹配。
    - `meta-security/classes/dm-verity-img.bbclass`、`meta-security/meta-integrity/classes/ima-evm-rootfs.bbclass`本次重新确认文件存在;`grep -rln "dm-verity-img\|ima-evm-rootfs" meta-qcom meta-qcom-distro meta-qcom-robotics-sdk`重新执行,零匹配(退出码1)。
    - `meta-qcom-distro/conf/distro/include/qcom-base.inc`第15-28行`DISTRO_FEATURES:append`列表(efi/glvnd/kvm/minidebuginfo/opencl/overlayfs/pam/pni-names/polkit/security/tpm2/virtualization/wifi/x11)本次重新读取确认不含`ima`。
    - 以上4项独立证据源均与正文结论一致,P0级安全风险判断维持不变。
    - 本次新增第5项独立证据,精确到两个具体机型(复用[Distro_Version](../../System_Architecture/Distro_Version/Distro_Version.md)已验证的同一对`8950-pebble`/`iq-9075-evk`,理由与实测结果见下文"两个具体机型的完整性校验状态核对"章节),用真实buildhistory的已安装包清单做机型级独立验证,而非仅source-level grep推断。
  - 服务端依赖体系对比:Uptane/TUF Director/Image Repo(或HERE OTA Connect)vs downstream(maili)自建HTTP签名zip分发。
  - 与首刷流程的边界确认(仅确认关系,不深入QDL/EDL工具链细节):首次刷机走QDL/Firehose,不受OSTree影响,OSTree只改变"刷机后"的升级路径。
- **明确排除**:
  - 首次量产刷机QDL/EDL工具链与流程本身 ——见[Flash_Process](../Flash_Process/Flash_Process.md)
  - Android安全HAL分区/单一rootfs分区结构本身 ——见[Partition_Layout](../../Boot_Architecture/Partition_Layout/Partition_Layout.md)
  - cmdline层面verity参数消失的证据细节 ——见[Bootargs](../../Boot_Architecture/Bootargs/Bootargs.md)
  - downstream(maili)的3个systemd补丁去向的完整追踪过程 ——见[Patch_Management](../../Code_Composition/Patch_Management/Patch_Management.md)
- **待定边界**:(无,已核实。文档内曾有两处"推测,待核实"标注,本次已用Bash `curl`直连`ostreedev.github.io`存档4份OSTree官方页面(`reference/Platform_Features/OTA_Mechanism/`:`ostree_introduction.html`/`ostree_repo.html`/`ostree_copying-deltas.html`/`ostree_formats.html`,2026-09-09存档,WebFetch仍因域名安全策略被拦截、改用curl)核实完毕——①static-deltas能否达到接近bsdiff的字节级差分能力:**已解除推测,确认成立**,`ostree_formats.html`原文"These deltas are targeted to be a delta between two specific commit objects, including 'bsdiff' and 'rsync-style' deltas within a content object"明确用bsdiff描述该机制;②OSTree pull是否支持HTTP Range分块续传:**已核实是官方架构级文档确实未覆盖此实现细节,不是网络不可达查不到**——对4份存档页面全文检索`Range`/`resume`/`resumable`/`interrupted download`关键字,零命中,该实现细节可能只存在于libostree HTTP fetcher的源码层面,已不再标注"网络受限待核实"。)

## 对比总览

| 维度 | downstream(maili)(Android式recovery/A-B块级OTA) | QLI2.0(标准OSTree+aktualizr) |
|---|---|---|
| 核心组件 | `src/OTA/`,完整移植的AOSP`bootable/recovery`+`build/tools/releasetools`+`system/update_engine`:`recovery/{applypatch,edify,updater,minzip,minui,bootloader_message,update_verifier,otafault}`;`external/bsdiff/`、`external/libdivsufsort/`(bsdiff差分算法) | `meta-updater/README.adoc`:"OSTree is a tool for atomic full file system upgrades with rollback capability...minimizes network bandwidth and data storage footprint by sharing files with the same contents across file system deployments";recipes-sota/ostree、recipes-sota/aktualizr/(`aktualizr_git.bb`、`aktualizr-device-prov.bb`、`aktualizr-device-prov-hsm.bb`、`aktualizr-shared-prov*.bb`、`aktualizr-uboot-env-rollback.bb`) |
| A/B切换实现 | `src/bootctrl/abctl/`: `libabctl.cpp`/`abctl.cpp`提供`--set_active`、`--boot_slot`、`--set_success`、`--set_unbootable`、`--set_priority`等命令;`ab-updater.service`(在sysinit.target阶段执行`abctl --set_success`标记启动成功)、`ab-symlink.service`(在local-fs.target前建立slot符号链接) | `aktualizr-uboot-env-rollback.bb`回滚机制依赖u-boot环境变量标记(bootcount/rollback) |
| 升级包生成 | `build/tools/full_ota.sh`与`incremental_ota.sh`**同时存在**,原生支持全量包与增量(差分)包两种打包路径;`build/tools/releasetools/ota_from_target_files.py`是标准AOSP OTA打包脚本 | 不适用(OSTree原生按对象/blob增量) |
| update_engine实现 | `src/OTA/recovery/update_engine/update_engine.cpp`头部含`#ifdef TARGET_SUPPORTS_AB`/`#include <libabctl.h>`,证实实为对`libabctl`(downstream(maili)自研A/B切换库)的封装/调度层,而非Google原生流式update_engine(payload.bin+omaha-like)实现;`ABC_OTA_STATUS_COOKIE_FILE="/cache/recovery/abc_ota_status"` | aktualizr实现Uptane,支持设备认证与provisioning,与OSTree集成,可连接自建后端或HERE OTA Connect |
| 组件描述文件 | `qc/le-ota.lnx/cd/cd.xml`显式列出`oem-recovery`、`recovery`、`recovery-ab`三个包,产出`/usr/bin/{recovery,updater,applypatch,edify}`、`recovery.service`等,证实"recovery-ab"是基于recovery+edify/updater脚本+applypatch的块级OTA,再叠加A/B分区切换(非Google Brillo式纯流式A/B) | 不适用 |
| 是否为opt-in | 否,recovery/bootctrl是核心交付件 | 是,`qcom-distro-sota.conf`(`require conf/distro/sota.conf.inc`;`INITRAMFS_IMAGE="initramfs-ostree-image"`;`DISTRO_NAME:append=" (OTA-enabled)"`;`DISTRO_FEATURES_OPTED_OUT+="ptest"`;`BUILD_OSTREE_REPO_TARBALL="1"`),该kas yml文件在`meta-qcom`与`meta-qcom-distro`两层仓库均存在,但已核实从未出现在任一层`.github/workflows/*.yml`的编译/测试矩阵条目里——当前代码库快照内查无任何CI job或本地构建记录实际构建过该variant |
| 升级粒度 | 分区镜像整包,或bsdiff文件级差分补丁(zip包+edify脚本) | 文件系统级commit(OSTree硬链接去重,按对象/blob增量) |
| 存储占用 | A/B双分区各占一份完整系统镶像空间(典型2x rootfs) | 通过内容寻址+硬链接跨版本共享未变化文件,理论上占用远低于2x |
| 回滚方式 | abctl分区属性(GPT attribute/优先级+尝试次数),recovery-ab包配合 | OSTree deploy保留多个历史commit,aktualizr-uboot-env-rollback通过u-boot bootcount触发回滚 |
| 断点续传 | 依赖full_ota.sh/incremental_ota.sh生成的整包/差分包一次性下载校验(recovery阶段执行) | OSTree pull按对象/blob增量拉取,未变化对象不重复下载,已按`meta-updater/README.adoc`"sharing files with the same contents across file system deployments"核实;HTTP Range分块续传属于libostree自身实现细节,已存档4份OSTree官方架构文档(`reference/Platform_Features/OTA_Mechanism/`)并逐一检索`Range`/`resume`/`resumable`/`interrupted download`关键字,零命中——确认是这些架构级文档未覆盖该实现细节,不属于网络受限查不到,若需确认需查libostree源码或更底层实现文档 |
| 服务端依赖 | 无强制TUF后端,OTA包可自建HTTP服务器分发,recovery侧校验签名zip | 需要Uptane/TUF兼容服务端(HERE OTA Connect或自建aktualizr后端),涉及director/image repo、root/targets元数据签名体系 |
| 触发/执行环境 | 需重启进入recovery模式执行升级 | aktualizr在线运行时后台拉取、部署,reboot生效但无需独立recovery分区 |
| 是否默认启用 | 是(recovery/bootctrl是核心交付件) | 否(需选择qcom-distro-sota distro变体) |

## dm-verity/AVB镜像完整性校验的确认消失(与本文档强相关)

- 追踪downstream(maili)的3个systemd补丁去向时(详见output/Code_Composition/Patch_Management/Patch_Management.md)发现关键佐证:`fstab-generator-Honor-verity-enabled-cmdline.patch`(识别cmdline中`verity=enabled`/`avb-verity`参数)在QLI2.0全局检索`verity=enabled`、`arg_usr_verity`均零匹配。
- **决定性证据**:downstream(maili)的`poky/meta-qti-bsp/classes/`下存在整整8个dm-verity相关bbclass(`dm-verity-initramfs.bbclass`、`dm-verity-initramfs-v2/v3.bbclass`、`dm-verity-bootloader.bbclass`、`dm-verity-cpio-cmdline.bbclass`、`dm-verity-none.bbclass`、`avb-verity-initramfs.bbclass`等),构成一整套AVB/dm-verity镶像签名与校验架构。QLI2.0的meta-qcom中没有任何一个对应class。
- 与output/Boot_Architecture/Bootargs/Bootargs.md(cmdline无verity参数)、output/Boot_Architecture/Partition_Layout/Partition_Layout.md(Android安全HAL分区消失)三方证据互相印证——QLI2.0不仅切换了OTA升级机制,还同步移除了整套镶像完整性校验(dm-verity/AVB)机制,这是比"升级机制切换"本身更大的安全架构变化。
- **能力"人在场但没上岗"**:`meta-security`(含`meta-tpm`)其实作为layer被`meta-qcom/ci/qcom-distro.yml`拉入默认构建,该层本身有完整的dm-verity实现(`meta-security/classes/dm-verity-img.bbclass`等)和IMA/EVM完整性度量实现(`meta-security/meta-integrity/classes/ima-evm-rootfs.bbclass`等),但`grep -rln "dm-verity-img\|ima-evm-rootfs" meta-qcom meta-qcom-distro`零匹配——没有任何qcom镜像recipe inherit这两个class,`qcom-base.inc`的`DISTRO_FEATURES:append`里也没有`ima`。结论:当前qcom-distro/qcom-distro-sota量产镜像不启用任何块级/文件级完整性校验,rootfs完整性完全依赖aktualizr的Uptane签名校验(OSTree pull/deploy阶段)。

### 两个具体机型的完整性校验状态核对(机型级独立验证,复用Distro_Version已验证的机型)

钉死`8950-pebble`(downstream(maili))与`iq-9075-evk`(QLI2.0)——两者均已被[Distro_Version](../../System_Architecture/Distro_Version/Distro_Version.md)用真实`auto.conf`/官方CI矩阵确认过是"真实被构建过"的组合,本次进一步核实两者在本仓库内**各自真实跑完的buildhistory**(而非仅source-level grep推断),并交叉检索downstream(maili)代码库内其他真实机型作为佐证:

- **iq-9075-evk(QLI2.0,DISTRO=qcom-robotics-ros2-jazzy)**:`0817/build/buildhistory/images/iq_9075_evk/glibc/qcom-robotics-image/image-info.txt`确认`DISTRO = qcom-robotics-ros2-jazzy`;对该镜像`installed-package-names.txt`执行`grep -i "ostree|aktualizr|verity|avb|abctl"`,命中的两条`pipewire-modules-avb`/`pipewire-spa-plugins-avb`核实为音视频桥接协议AVB,与Android Verified Boot无关(误报)——**真实业务命中数为0**。即这枚真实构建的镜像既未安装任何OTA(ostree/aktualizr)组件,也未安装任何dm-verity/AVB相关组件。
- **8950-pebble(downstream(maili),DISTRO=qti-distro-camerastack-debug)**:`build-qti-distro-camerastack-debug/buildhistory/images/pebble/glibc/qti-multimedia-image/image-info.txt`的`IMAGE_INSTALL`显式含`recovery-ab`;`installed-package-names.txt`执行`grep -i "abctl|recovery-ab|verity|avb"`真实命中`abctl`、`recovery-ab`两个包(已装),**未命中任何verity/avb相关包**。进一步核实`poky/meta-qti-bsp/conf/machine/pebble.conf`第194行`MACHINE_FEATURES += "qti-ab-boot qti-audio qti-video qti-adsp qti-cdsp fastrpc"`(qti-ab-boot真实生效),第160行`MACHINE_FEATURES += "dm-verity-none"`(显式选择"无dm-verity"变体),且全文未见`qti-avb`——**这枚被钉定的真实机型本身dm-verity/AVB均未启用**。
- **交叉证据(证明dm-verity/AVB在downstream(maili)侧是真实被其他量产机型使用的能力,不是从未启用的摆设代码,避免"pebble没启用⇒downstream(maili)整体没有这个能力"的误判)**:`poky/meta-qti-bsp/conf/machine/sxrneo.conf`——`MACHINE_FEATURES += "...dm-verity-initramfs-v2..."`,`KERNEL_CMD_PARAMS = "${CONSOLE_PARAM} verity=enabled"`未被移除(移除逻辑仅在检测到`dm-verity-none`时触发,sxrneo没有该token)——真实启用dm-verity;`poky/meta-qti-bsp/conf/machine/seraph.conf`——`MACHINE_FEATURES += "...qti-avb..."`,`KERNEL_CMD_PARAMS:append`按`qti-avb`条件追加`" avb-verity=enabled systemd.setenv=SLOT_SUFFIX=_a"`——真实启用AVB。两者均是真实存在于代码库的量产机型conf,不是假设组合。
- **本节结论(精确化,不改变P0结论方向)**:P0结论讲的是"架构能力是否存在、能否被任意机型接入",而不是"某一台设备出厂配置是否勾选"——downstream(maili)侧的dm-verity/AVB本身也是逐机型`MACHINE_FEATURES`级opt-in(`poky/meta-qti-bsp/classes/qimage.bbclass`用`bb.utils.filter`在7个互斥bbclass里按token选择),被钉定的pebble机型本身选择了关闭,但能力真实存在且被sxrneo/seraph等其他真实机型使用,任何团队都能通过一行`MACHINE_FEATURES`配置接入;QLI2.0侧`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`里连对应bbclass实现都不存在(`meta-security`层有实现但零qcom recipe inherit,见上文),没有"加一行配置"就能打开的开关——这才是能力层面"消失"与机型层面"未勾选"的本质区别,不因pebble这台钉定机型本身的基线状态而减弱P0结论。

## 关键差异

- **服务端集成是最大变更点**:downstream(maili)的OTA服务端只需托管签名zip包(HTTP/HTTPS),QLI2.0需要一整套Uptane TUF Director/Image Repo基础设施(或采购HERE OTA Connect),这是架构级的服务端重建,不是简单协议适配。
- **首次刷机流程不受OSTree影响**:无论downstream(maili)还是QLI2.0,首次量产刷机都走QDL/EDL整机镶像(详见Flash_Process.md),OSTree只改变"第二次及后续升级"的路径——从"重新整包/差分刷写分区"变为"OSTree pull+deploy+reboot"。产线刷机脚本/流程基本不变,但售后/远程升级流程需要重新设计(涉及设备provisioning、TUF密钥管理、aktualizr密钥/证书注入)。
- 由于OTA能力是opt-in distro(`qcom-distro-sota`),若产品团队仍按`qcom-distro`默认配置构建,将完全没有OTA能力,需要显式确认目标产品选用哪个distro。经本次核实,这一opt-in的严重程度比"未被当前一次构建选用"更进一步:对`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`三层全部`.github/workflows/*.yml`执行`grep -rn "sota"`零命中,`git log`确认该distro variant存在满7个月(`meta-qcom-distro` `be15846`,2025-11-26新增;最后一次改动`dd38a45`,2026-04-02)、期间CI矩阵重写过一次(`e383e94`,2026-03-05)仍未纳入编译/测试矩阵——即该OTA替代路径自诞生以来从未在官方可见的构建/测试体系里被验证过一次,若产品团队后续启用它,相当于在一条未经生产验证的路径上叠加使用,需要专项验证而非直接照搬默认配置。
- downstream(maili)的bsdiff差分能力(更小升级包)在QLI2.0里由OSTree对象级去重取代,但两者的"网络流量最优场景"不同:bsdiff针对整文件二进制差分优化更极致,OSTree依赖文件级去重,若某文件整体变化(如内核镶像替换),不启用`static-deltas`时无法做到bsdiff级别的字节差分。`static-deltas`本身能否提供接近bsdiff的二进制差分能力,已用存档的OSTree官方文档核实(`reference/Platform_Features/OTA_Mechanism/ostree_formats.html`,"These deltas are targeted to be a delta between two specific commit objects, including 'bsdiff' and 'rsync-style' deltas within a content object"),**确认成立,不再是推测**。但经核实`grep -rn "static.delta" meta-updater`只命中ostree自身源码文件名(libostree二进制自带能力),meta-updater的recipe/配置里没有任何生成或启用static-deltas的痕迹,目前QLI2.0没有分发过差分包——即"官方能力确认存在"与"本项目实际启用"仍是两件事,若要对齐downstream(maili)的bsdiff体积水平,理论上可通过启用`static-deltas`配置实现(而非需要重新开发差分算法),但仍需专项验证与配置工作,不能假设"开箱即用"。
- **abctl在QLI2.0中完全不存在**:`grep -rln "abctl\|libabctl" meta-qcom meta-qcom-distro meta-updater`零匹配,与Partition_Layout.md"QLI2.0只有单一rootfs分区"的结论互相印证。`aktualizr-uboot-env-rollback.bb`只安装一个`30-rollback.toml`,让aktualizr利用u-boot bootcount对**单一rootfs的OSTree deploy**做回滚,跟downstream(maili)基于abctl的固件槽位(`xbl_a/b`等)A/B切换是完全不同的机制,两者不冲突;但固件槽位在OTA场景下由谁触发A/B判定与回滚,在meta-updater/meta-qcom里都没有找到对应实现,这是output/Boot_Architecture/Partition_Layout/Partition_Layout.md已列出的独立待确认项。

## 影响与风险

- downstream(maili)的recovery模式在断电/异常中断时的行为(是否可续传、是否需要重新下载整包)与OSTree pull的容错行为不同,需要针对目标网络环境(车载/嵌入式弱网)做专项验证。
- **镶像完整性校验缺失是新增的P0级安全风险**:dm-verity/AVB整套机制消失后,已核实等价能力(meta-security的dm-verity/IMA-EVM)存在于代码库但未被任何qcom镜像recipe启用(详见上文"能力人在场但没上岗"),当前根文件系统完整性完全依赖aktualizr的Uptane签名校验,并非fs-verity或其它等价机制,需要安全团队评估是否要显式打开这些开关。

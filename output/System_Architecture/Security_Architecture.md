# System Architecture — Security Architecture (SELinux)

## 对比范围

- **覆盖**:
  - SELinux/refpolicy策略体系整体对照(上游层版本、refpolicy基线、Qualcomm定制策略层规模与组织方式、策略类型、默认启用状态、可选启用方式、裁剪机制、relabel机制):
    - QLI1.0:`poky/meta-selinux`(fork自`quic/le/meta-selinux`)、`poky/meta-qti-sepolicy`(661个`.te`/`.fc`/`.if`文件,`common/`/`alor/`/`kera/`/`pebble/`/`sdmsteppe/`/`generic/`/`robotics/`/`patches/`子目录)、`refpolicy_git.inc`
    - QLI2.0:`meta-selinux`、`meta-qcom/dynamic-layers/selinux/`(`qcom_nhx`/`tee_supplicant_qtee`/曾有pd-mapper backport三个策略点)、`refpolicy_git.inc`、`qcom-distro-selinux.conf`/`qcom-robotics-distro-selinux.conf`
  - Qualcomm定制策略Git提交历史与本地checkout落后主线情况的核实——`meta-qcom/dynamic-layers/selinux`的`git log`及`git log HEAD..origin/wrynose -- dynamic-layers/selinux`
  - 量产环境实际生效的refpolicy provider变体核实——QLI1.0:`poky/meta-qti-distro/conf/distro/`下30个distro变体的provider声明、`release/crm/PACK.TXT`、`release/syncbuild.sh`
  - 替代MAC/沙箱隔离机制排查(是否有机制替代SELinux)——两侧`meta-security`层:`apparmor_4.0.3.bb`、`firejail_0.9.72.bb`、seccomp、`meta-security/meta-integrity`(IMA/EVM)是否被qcom镜像`IMAGE_INSTALL`引用
  - 机型代号(alor/kera/pebble/sdmsteppe)与SELinux策略目录、soc-repo驱动文件、QLI2.0内核树的对应关系排查
  - 合规声明机制对照——QLI1.0:`qc/le-sepolicy.lnx`分支族的`cd.xml`;QLI2.0:`create-spdx-image-3.0.bbclass`、`SPDX_INCLUDE_KERNEL_CONFIG`、实际构建产物`build/tmp/deploy/spdx/3.0.1/`
- **明确排除**:
  - 镶像完整性校验(dm-verity+AVB) ——见[OTA_Mechanism](../Platform_Features/OTA_Mechanism.md)、[Bootargs](../Boot_Architecture/Bootargs.md)、[Boot_Flow](../Boot_Architecture/Boot_Flow.md)
  - Android安全HAL分区(keystore/secretkeeper/hwcrypto等) ——见[Partition_Layout](../Boot_Architecture/Partition_Layout.md)
  - TUI(Trusted UI)生产能力 ——见[Layer_Architecture](../Code_Composition/Layer_Architecture.md)
- **待定边界**:FBE(File-Based Encryption,通过fscrypt)磁盘/文件加密能力——QLI1.0侧真实在用:`poky/meta-qti-bsp/conf/machine/qrb5165-rb5.conf`的`MACHINE_FEATURES`显式含`qti-fscrypt`与`file-based-encryption`,`qrbx210-rbx.conf`同样显式含`qti-fscrypt`(`qcm2290-mtp.conf`仅在注释里列出该feature说明,实际`MACHINE_FEATURES`行未启用,三份machine conf的引用方式不完全一致,需注意区分);QLI2.0侧`meta-security/recipes-security/fscrypt/fscrypt_1.1.0.bb`与`fscryptctl/fscryptctl_1.1.0.bb`两个recipe存在(该层已纳入`build/conf/bblayers.conf`),但对`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`/`build/conf`全目录检索`fscrypt`/`qti-fscrypt`/`file-based-encryption`均零命中——与本文档已有的AppArmor/Firejail"层里有、没人用"结论是同一模式。本次核实时对本仓库全部产出文档检索"FBE/FDE/dm-crypt/磁盘加密/数据加密"关键字同样零命中,当前没有任何文档的《对比范围》"覆盖"字段认领此项,本文档正文亦未展开分析,暂记为待定边界,留待下次修订本文档或Partition_Layout.md(该文档已讨论`keymaster_a/b`分区留存,与FBE密钥管理相关)时定归属。

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 上游层 | `poky/meta-selinux`(repo fork自`quic/le/meta-selinux`),libselinux/libsepol/libsemanage/checkpolicy/policycoreutils/mcstrans/secilc/semodule-utils版本统一3.6 | `meta-selinux`,以上组件版本升至3.10 |
| refpolicy基线 | `refpolicy_git.inc`: `PV="2.20240226+git"`,`SRCREV_refpolicy="71f4bd1992e05bcd79dc5234f8a30deeb141aa3d"`(2024-02上游快照) | `PV="2.20260312+git"`,`SRCREV_refpolicy="fbae939176fed7163730506878d92d3b1da433e4"`(2026-03上游快照,晚约2年) |
| Qualcomm定制策略层 | `poky/meta-qti-sepolicy`,独立repo,`BBFILE_PRIORITY="11"`,`LAYERDEPENDS_qti-sepolicy="selinux qti-bsp"`,661个`.te`/`.fc`/`.if`文件 | `meta-qcom/dynamic-layers/selinux/`,以patch形式内嵌于refpolicy-targeted源码树 |
| 策略组织方式 | `common/`(361文件,跨机型公共域:audio/camera/modem-data/diag/encryption/WLAN/OTA/overlay挂载器等)+`alor/`(52)/`kera/`(51)/`pebble/`(47)/`sdmsteppe/`(26)机型专属+`generic/`(2)+`robotics/`(仅readme,空)+`patches/`(12个) | 3个策略点:`qcom_nhx`策略模块(246行,相机测试工具域)、`tee_supplicant_qtee`(TrustZone/QTEE tunable适配)、曾有pd-mapper服务策略(已因上游可用而移除本地backport) |
| 策略类型 | MLS弱化版——`disable-mls-constraints.patch`删除上游`policy/mls`绝大部分`mlsconstrain`规则,仅保留敏感度标签 | 默认`refpolicy-targeted`(meta-selinux/conf/layer.conf: `PREFERRED_PROVIDER_virtual/refpolicy ??= "refpolicy-targeted"`) |
| 默认启用状态 | 默认开启且enforcing,`qti-distro-camerastack-debug.conf`显式`PREFERRED_PROVIDER_virtual/refpolicy="refpolicy-mls-robotics"` | 默认关闭——`qcom-base.inc`不含selinux feature,当前实际DISTRO(`qcom-robotics-ros2-jazzy`)未require任何selinux inc |
| 可选启用方式 | 需显式`DISTRO_FEATURES:remove`才能关闭 | 需选`qcom-distro-selinux.conf`/`qcom-robotics-distro-selinux.conf`才能打开,打开后无自定义refpolicy provider指定 |
| 裁剪机制 | `PURGE_POLICY_MODULES`/`CONTRIB_MODULES`/`REMOVE_MODULES`,按`MACHINE_FEATURES(qti-vm/qti-recovery)`及`COMBINED_FEATURES(qti-ab-boot)`条件生成 | 无对应机制 |
| relabel机制 | `label-cache/data/persist/systemrw.service`配合overlay/持久化分区做restorecon | 无对应物 |
| 构建产物验证 | — | build/downloads、sstate-cache、buildhistory中均未发现refpolicy被实际下载或构建过的痕迹 |
| bblayers状态 | — | meta-selinux层已纳入`build/conf/bblayers.conf`,层就位但开关未打开 |

## 纠错记录:SELinux覆盖范围判断纠正

| 阶段 | 结论 | 依据 |
|---|---|---|
| 初步判断 | QLI2.0侧SELinux策略"完全空白" | 全量检索`.te`/`.fc`/`.if`扩展名文件,仅命中6个mariadb自带的通用可选策略文件,与Qualcomm定制无关,据此误判为"没有任何自定义策略" |
| 核实后结论 | 有真实但规模远小的雏形 | QLI2.0的Qualcomm定制策略不以独立`.te/.fc/.if`文件形式存在,而是以patch形式内嵌进`meta-qcom/dynamic-layers/selinux/`下的refpolicy-targeted源码树,按扩展名搜索必然漏判;改用git log排查该目录后,确认存在3个真实策略点(camera测试工具域`qcom_nhx`、TrustZone/QTEE的`tee_supplicant_qtee`、曾有的pd-mapper backport已因上游可用而清理),对应QLI1.0覆盖范围(661个`.te/.fc/.if`文件)差距在两个数量级以上,但绝非"零" |

已同步更新README.md《曾纠正过的结论》表(SELinux行:"QLI2.0完全空白"→"有真实但规模远小的雏形"),下方各节(Git提交历史、关键差异、影响与风险)均基于核实后结论展开。

## Qualcomm定制策略Git提交历史(meta-qcom/dynamic-layers/selinux)

| 时间 | 提交内容 |
|---|---|
| 2025-10-27 | linux-qcom-next: add config fragment to support SELinux |
| 2026-02-06 | refpolicy: Introduce SELinux domain and policies for pd-mapper service |
| 2026-02-12 | refpolicy: drop SELinux policy backport patch for pd-mapper(因已随meta-selinux版本升级而上游可用) |
| 2026-02-20 | linux-qcom: enable SELinux kernel configs on LTS kernel |
| 2026-03-03 | refpolicy-targeted: Add SELinux policy for proprietary camera test app (nhx.sh) |
| 2026-03-10 | refpolicy: Introduce SELinux domain and policies for tee_supplicant |
| 2026-03-19 | Revert "...tee_supplicant..."(见下方引用) |
| 2026-06-11/24/25 | refpolicy_targeted: Enable tunable flag tee_supplicant_qtee(为Kodiak/Lemans/Monaco/Talos等KLMT机型开放QTEE权限) |
| 2026-06-25 | refpolicy-targeted: Update SELinux policy for nhx.sh with additional permissions |
| 2026-07-02 | [Backport wrynose]上述tunable修复回填(#2633) |

两条revert/drop提交的原文说明(证明团队按标准流程推上游后清理本地patch):
> "This reverts commit ... as this is now available as part of refpolicy update in meta-selinux." — Anuj Mittal
> "The change is present in the refpolicy revision currently pinned by meta-selinux. Remove the backport patch ... to align with upstream." — Sasi Kumar Maddineni

本地checkout(HEAD=`ef0004df`/PR#2607)已确认落后于`origin/wrynose`(最新到PR#2987),`tee_supplicant_qtee`的0002号patch因此未出现在本次快照磁盘上,但`--all`可确认已合入wrynose主线——即"已落地但未同步到这份代码快照",非废弃方案。`git log HEAD..origin/wrynose -- dynamic-layers/selinux`重新核实,整体落后317个commit,但SELinux相关路径只有3条(nhx.sh追加权限、tee_supplicant_qtee tunable修复及其backport),均已体现在上表,策略覆盖范围截至本次核查未进一步扩大。

## 替代隔离机制排查结果

| 机制 | 排查结果 |
|---|---|
| AppArmor/Firejail | 存在于`meta-security`层recipe(`apparmor_4.0.3.bb`、`firejail_0.9.72.bb`),但未被任何qcom镜像的IMAGE_INSTALL引用,属"层里有、没人用"的死代码 |
| Landlock | 未发现任何专门集成 |
| seccomp | 110个文件命中,但均为qemu/docker/systemd等标准上游软件包自带的固有属性,非Qualcomm团队主动安全设计 |
| IMA(meta-security/meta-integrity) | 上游原样内容,无Qualcomm定制迹象 |
| 结论 | 无证据表明安全团队选择了这些机制替代SELinux MAC;TrustZone/QTEE隔离与SELinux是互补而非替代关系 |

## 关键差异

- QLI1.0覆盖audio/camera/modem/加密/OTA/诊断等数十个高权限daemon的域定义;QLI2.0仅覆盖相机测试工具和TrustZone/QTEE两小块,规模不在一个量级。
- `qc/le-sepolicy.lnx`是manifest分支族名称(`le-sepolicy.lnx.3.0`),内容仅为合规声明`cd.xml`,真正策略源码在`meta-qti-sepolicy`,不要被目录名误导。
- QLI2.0策略以patch形式打入refpolicy-targeted源码树,直接搜索`.te/.fc/.if`文件扩展名会漏判(初步判断→核实后结论的完整纠错过程见文档开头"纠错记录"一节)。
- QLI2.0团队有清晰的"推动修复上游合并、上游可用后清理本地patch"工程实践,是活跃维护中的项目而非占位符或废弃试验。
- QLI1.0四个机型目录中`sdmsteppe`已确认对应QCS610(`poky/meta-qti-bsp/conf/machine/include/qcs610.inc`: `BASEMACHINE ?= "sdmsteppe"`);`alor`/`kera`/`pebble`是Qualcomm内部代号,三个`.conf`均未声明`SOC_FAMILY`,无法仅凭本仓库配置反推对应新命名芯片。已额外核实:这三个代号在`soc-repo`里各自有独立的SoC级驱动(`pinctrl-alor.c`/`gcc-alor.c`/`camcc-alor.c`、`gcc-kera.c`/`gpucc-kera.c`/`camcc-kera.c`、`pinctrl-pebble.c`/`gcc-pebble.c`/`camcc-pebble.c`/`evacc-pebble.c`等),说明三者是独立芯片而非同芯片不同板级;同时在QLI2.0内核树(`drivers/clk/qcom`、`drivers/pinctrl/qcom`、`drivers/interconnect/qcom`、`arch/arm64/boot/dts/qcom`)里对`alor`/`kera`/`pebble`三个代号全文检索均为0命中,说明QLI2.0没有直接沿用这三个旧代号,新命名规则与旧代号之间没有本仓库可查的直接线索。
- QLI1.0 perf/debug两条产线的refpolicy provider写法确认不同:`qti-distro-base-perf.conf`用`bb.utils.contains`条件生成,`qti-distro-base-debug.conf`硬编码`refpolicy-mls-generic`;已把`poky/meta-qti-distro/conf/distro/`下全部30个变体逐一核实provider声明(含被`require`的.inc链):`camerastack`/`fullstack`/`rb`三条产线(debug+perf共6个变体)统一硬编码`refpolicy-mls-robotics`,`xr`(debug+perf)走条件生成的`refpolicy-mls-xr`,仅`base-debug`用`refpolicy-mls-generic`、`base-perf`条件生成同值;`vnm`/`host`/`fullstack-noselinux`/`nogplv3`/`*-nosecurity`/`*-user`/`fullstack-virtualization`等变体在自身及`require`链里都没有声明,会落到`meta-selinux`层的默认provider。即"只能代表一个配置"已升级为"已核实全部30个变体声明值",但这仍是配置层声明,不等于各SKU量产时实际选用的变体清单,后者仍需release管理团队核对。
- QLI2.0`meta-qcom-robotics-sdk`的SELinux配置(`qcom-robotics-distro-selinux.conf`)只是复用`meta-qcom-distro`基础开关的wiring,没有任何`.te/.fc/.if`文件——robotics场景SELinux策略在两侧都是"尚未开始",不存在迁移丢失。
- `build/conf/bblayers.conf`完整层列表中不含任何clang相关层,与output/Build_Architecture/Toolchain.md交叉确认一致:meta-clang功能已合并进oe-core主干,不存在未公开的独立clang层。

## 影响与风险

- 安全基线存在弱化风险,但非"从零开始"——QLI2.0已有真实维护中的雏形,只是覆盖面和默认启用状态与QLI1.0差距巨大。
- 661个策略文件迁移需在新refpolicy基线(跨2年上游演进)和libselinux 3.10上重新验证,不能整体照搬。
- 裁剪机制(按MACHINE_FEATURES条件生成策略)和relabel服务QLI2.0均无对应物,若重新启用selinux而未补齐,overlay分区重新打包后可能出现unlabeled_t导致AVC拒绝。
- 现网运维经验(AVC审计、白名单)围绕MLS策略建立,迁移到targeted或自研策略后QA基本要从零开始。
- 合规声明流程(对应QLI1.0`cd.xml`那套东西)在QLI2.0没有代码侧承接:已在`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`全目录grep`cd.xml`及`compliance`关键字,0命中;但已确认存在一个真实生效、非custom的替代物——oe-core标准`create-spdx-image-3.0.bbclass`,`meta-qcom-distro/conf/distro/include/qcom-base.inc`里`SPDX_INCLUDE_KERNEL_CONFIG ?= "1"`已开启,且在实际构建产物`build/tmp/deploy/images/iq-9075-evk/`及`build/tmp/deploy/spdx/3.0.1/`里能看到真实生成的`.spdx.json`(SPDX 3.0)文件,即软件成分清单(SBOM)是当前默认构建就在跑的能力,只是它是oe-core通用机制而非Qualcomm专属合规流程,能否满足`cd.xml`对应的出口合规/法务要求仍是另一个问题。

## 待确认

- **alor/kera/pebble机型代号与QLI2.0新机型的映射**——确认方向:`sdmsteppe`已核实对应QCS610,但`alor`/`kera`/`pebble`是Qualcomm内部代号,本仓库配置未声明`SOC_FAMILY`。**新证据**:在QLI1.0`build-qti-distro-camerastack-debug/conf/`下找到了`alor_prebuilts.conf`/`kera_prebuilts.conf`/`pebble_prebuilts.conf`/`sun_prebuilts.conf`——这4个是当前构建配置实际在用的机型(非历史遗留代号),对应`poky/meta-qti-bsp/conf/machine/{alor,kera,pebble,sun}.conf`,`TARGET_BOARD_PLATFORM`分别是`alor-le`/`kera-le`/`pebble-le`/`sun-le`,且`KERNEL_SRC_TYPE = "soc-repo"`。已在soc-repo里进一步核实三者均为独立SoC:`drivers/soc/qcom/socinfo.c`板级ID表里有`ALOR`/`ALORP`/`ALOR_INTERPOSER`、`PEBBLE`/`PEBBLEP`、`SUN`/`SUNP`各自独立的board_id项(kera未见独立board_id项,但`drivers/clk/qcom/Kconfig`里`SM_TCSRCC_TUNA`同时`depends on SM_GCC_TUNA || SM_GCC_KERA`,提示kera在TCSR时钟这一层与tuna共用基础设施,可能是tuna同代的兄弟/变体芯片而非完全独立设计);Kconfig里`SM_GCC_ALOR`/`SM_GCC_KERA`/`SM_GCC_PEBBLE`等条目只给出"Alor/Kera/Pebble devices"这类代号化描述,不含任何商用芯片型号字样。QLI2.0内核树(`drivers/clk/qcom`、`drivers/pinctrl/qcom`、`drivers/interconnect/qcom`、`arch/arm64/boot/dts/qcom`)里对`alor`/`kera`/`pebble`三个代号全文检索仍为0命中。代码侧能查的线索(board_id表、Kconfig描述、新内核树关键字)已用尽,商用芯片型号本身不在这两个仓库的可查范围内。本次又通读了`{alor,kera,pebble,sun}.conf`在`meta-qti-bsp`与`meta-qti-bsp-prop`两层的完整内容(非仅grep片段),除已提取的`TARGET_BOARD_PLATFORM`/`KERNEL_SRC_TYPE=soc-repo`外没有其它商用型号线索;并用Sourcegraph公网代码搜索(覆盖GitHub/GitLab等公开索引仓库,非本地两个仓库)分别查`ALOR_INTERPOSER`/`SM_GCC_KERA`/`ALORP_INTERPOSER`/`alor-le TARGET_BOARD_PLATFORM`,均0命中——这4个代号在公网可索引代码范围内也没有留下痕迹,不是本地两仓库特有的信息缺口。确认步骤:找BSP团队查`alor-le`/`kera-le`/`pebble-le`/`sun-le`这4个`TARGET_BOARD_PLATFORM`值对应的商用芯片型号,以及各自在QLI2.0`meta-qcom`里的新机型名(如iq-8275-evk/qcs9100-ride-sx/sm8750-mtp)。
- **量产环境实际使用的refpolicy provider变体**——确认方向:已把`poky/meta-qti-distro/conf/distro/`下全部30个变体的provider声明逐一核实完(见上方"关键差异"新增条目):camerastack/fullstack/rb统一`refpolicy-mls-robotics`,xr走`refpolicy-mls-xr`,base-debug/perf是`refpolicy-mls-generic`,其余变体(vnm/host/nogplv3/nosecurity/user/virtualization)自身及require链都没有声明会落到meta-selinux默认值——但这仍是"代码声明了什么",不等于"各SKU量产时实际选用了哪个变体"。本次又检查了`release/crm/PACK.TXT`(实际打包脚本,把`build-qti-distro-fullstack-debug`/`build-qti-distro-fullstack-perf`两个变体的`tmp-glibc/deploy/images`打进`HK11`发布包),与`release/syncbuild.sh`里的`qti-distro-rb-debug`是两个独立的release侧文件,但指向的都是`refpolicy-mls-robotics`这一个provider家族(fullstack/rb都在该家族内),再无第三个变体在任何release相关脚本/清单里出现过——只能说这两份能找到的实际发布证据互相印证、指向同一个provider,仍不能代表全部产线(camerastack等其余家族成员及30个变体里的其余大多数在release侧完全没有踪迹),本仓库范围内没有能覆盖全部产品线的release manifest。确认步骤:找release/build管理团队核实各产品线量产DISTRO清单(PACK manifest或release流水线配置),对上本次已核实的30变体声明表,确认各产线实际生效的是哪一个。

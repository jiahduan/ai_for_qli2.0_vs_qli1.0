# QLI2.0 vs downstream(maili) 架构对比 — 总览

QLI2.0代码根:`/local/mnt/workspace/jiahduan/qli2.0/0817`
downstream(maili)代码根:`/local/mnt/workspace/jiahduan/8950/0804_ko_in_bak4_copy1`

## 文档索引

| 分类 | 主题文件 |
|---|---|
| System_Architecture | [Security_Architecture](output/System_Architecture/Security_Architecture/Security_Architecture.md) · [Yocto](output/System_Architecture/Yocto.md) · [Distro_Version](output/System_Architecture/Distro_Version/Distro_Version.md) · [Kernel_Code_Architecture](output/System_Architecture/Kernel_Code_Architecture/Kernel_Code_Architecture.md) · [RT](output/System_Architecture/RT/RT.md) · [Overlay](output/System_Architecture/Overlay/Overlay.md) · [Display](output/System_Architecture/Display/Display.md) · [Camera](output/System_Architecture/Camera/Camera.md) · [Audio](output/System_Architecture/Audio/Audio.md) · [Graphics](output/System_Architecture/Graphics/Graphics.md) · [WiFi_BT](output/System_Architecture/WiFi_BT/WiFi_BT.md) |
| Boot_Architecture | [Partition_Layout](output/Boot_Architecture/Partition_Layout/Partition_Layout.md) · [Boot_Flow](output/Boot_Architecture/Boot_Flow/Boot_Flow.md) · [Bootloader](output/Boot_Architecture/Bootloader/Bootloader.md) · [Bootargs](output/Boot_Architecture/Bootargs/Bootargs.md) · [systemd](output/Boot_Architecture/systemd_/systemd_.md) |
| Build_Architecture | [Build_Environment](output/Build_Architecture/Build_Environment/Build_Environment.md) · [Build_Tools](output/Build_Architecture/Build_Tools/Build_Tools.md) · [Bitbake_Version](output/Build_Architecture/Bitbake_Version/Bitbake_Version.md) · [Toolchain](output/Build_Architecture/Toolchain/Toolchain.md) · [Kernel_Build](output/Build_Architecture/Kernel_Build/Kernel_Build.md) · [SDK_eSDK](output/Build_Architecture/SDK_eSDK/SDK_eSDK.md) |
| Code_Composition | [Code_Sync_Method](output/Code_Composition/Code_Sync_Method/Code_Sync_Method.md) · [Code_Repository](output/Code_Composition/Code_Repository/Code_Repository.md) · [Layer_Architecture](output/Code_Composition/Layer_Architecture/Layer_Architecture.md) · [Source_Code_Structure](output/Code_Composition/Source_Code_Structure/Source_Code_Structure.md) · [Branch_Management](output/Code_Composition/Branch_Management/Branch_Management.md) · [Patch_Management](output/Code_Composition/Patch_Management/Patch_Management.md) · [HY11_HY22](output/Code_Composition/HY11_HY22/HY11_HY22.md) |
| Platform_Features | [Log_System](output/Platform_Features/Log_System/Log_System.md) · [OTA_Mechanism](output/Platform_Features/OTA_Mechanism/OTA_Mechanism.md) · [Code_Submission](output/Platform_Features/Code_Submission/Code_Submission.md) · [Flash_Process](output/Platform_Features/Flash_Process/Flash_Process.md) |

## 专有栈 → 开源栈对照表

| 子系统 | downstream(maili) | QLI2.0 | 详见 |
|---|---|---|---|
| 内核治理 | Google ACK多仓庭院模式,Android vendor-hook基建 | 单一GitHub仓库,mainline-first(FROMLIST/QCLINUX标签) | Kernel_Code_Architecture |
| WLAN | QCACLD/PRIMA/CNSS | mac80211(ath10k/11k/12k)+标准linux-firmware | WiFi_BT |
| BT | Fluoride(AOSP) | BlueZ5 | WiFi_BT |
| Display | SDM Composer/HWC | DRM/KMS+Wayland+Mesa/freedreno | Display |
| Audio | 内部AudioReach源码树 | meta-audioreach开源layer,PulseAudio→PipeWire | Audio |
| Camera服务层 | QMMF(闭源) | camera-service(BSD-3-Clause) | Camera |
| Bootloader | ABL/EDK2(闭源) | u-boot(开源fork) | Bootloader |
| 内核模块编译 | file://本地树+build_module.sh | 独立git仓库+module.bbclass | Kernel_Build |
| 代码同步 | Google repo(内网manifest) | kas(声明式yaml,GitHub) | Code_Sync_Method |
| C/C++工具链 | meta-clang第三方层 | 合并进oe-core主干,行为对等 | Toolchain |
| GPU用户态3D驱动 | 专有二进制(内部编译) | 专有二进制(qartifactory下载,**仍未开源**) | Graphics |
| CamX/ChiCDK算法引擎 | 专有源码(内部编译) | 专有二进制(按板级预编译,**仍未开源**) | Camera |

## 安全/合规风险清单

| 项目 | downstream(maili) | QLI2.0 | 风险等级 | 详见 |
|---|---|---|---|---|
| SELinux策略 | 661文件,默认MLS enforcing | 约3个策略点(camera+TrustZone/QTEE),默认不启用 | P1 | Security_Architecture |
| Android安全HAL分区 | keystore/secretkeeper/hwcrypto等 | 全部消失 | P0 | Partition_Layout |
| 镶像完整性校验 | dm-verity+AVB(8个bbclass) | 全套机制消失,替代方案不明;UKI层面本可补一层secure boot签名(`uki.bbclass`的`UKI_SB_KEY`/`UKI_SB_CERT`),但`meta-qcom*`/`meta-security*`/`meta-updater`/`build/conf`全局检索该变量及`sbsign`同样零命中,即当前默认构建的UKI本身也是未签名的 | P0 | OTA_Mechanism / Bootargs / Boot_Flow |
| SSR故障恢复看门狗 | reboot-daemon(slot切换/EDL恢复) | 未找到对应物 | P1 | Layer_Architecture |
| EVA视觉分析引擎 | libeva固件+测试套件,`meta-qti-eva-devicetree`标记HY11专属;硬件驱动侧`src/vendor/qcom/opensource/eva-kernel/msm/eva/target/cvp_kaanapali_hal.c`(实测存在,Qualcomm署名,专为kaanapali芯片实现的CVP HAL)证实该SoC确实带EVA/CVP硬件IP | 用户态软件栈(eva/libeva/evass/cvp/icp)全树零命中,kernel dts里的`cvp@`保留内存节点/`compatible`字符串也零命中,即QLI2.0内核基线未随之移植驱动;`meta-qcom/conf/machine/kaanapali-mtp.conf`确认kaanapali是QLI2.0真实在用机型,两侧指向同一SoC代号,硬件IP大概率仍在硅片上,只是软件栈未跟进,转向ROS2感知栈 | P1 | Layer_Architecture / Camera |
| DIAG诊断能力 | 源码级核心组件 | 降级为测试镜像可选预编译包 | P1 | Log_System |
| HY11/HY22预编译分发 | CRM variant机制完整存在(`populate_prebuilt.sh`+manifest`x-quic-distributable`规则+各专有模块`crm/noship_common_HY11`/`HY22`清单文件) | 无HY11/HY22标签本身,但存在替代机制:闭源组件recipe直接从`softwarecenter.qualcomm.com`按组件名+版本/构建日期拉取指定预编译包,分发粒度从两个粗粒度CRM variant变为逐组件独立版本化,不是能力缺失,是分发机制的现代化改造 | P1 | HY11_HY22 |
| TUI(Trusted UI) | `securemsm-noship`里真实的`TUICoreService`生产二进制,按HY11打包到alor/kera/pebble/sun | 已检出层零命中,连securemsm字符串本身都不存在 | P1 | Layer_Architecture |
| ACDB音频调优数据开源发布 | `meta-iot-audio-prop/acdbdata_git.bb`闭源 | 公开仓库`audioreach-conf`(github.com/Audioreach/audioreach-conf),校准/调音数据本身随代码一起开源 | P1 | Audio |

## 待拍板事项汇总(按优先级)

| 优先级 | 事项 | 决策方 |
|---|---|---|
| P0 | OTA终态方案(继续A/B还是定OSTree)及迁移计划 | 系统架构+产品 |
| P0 | Android安全HAL替代方案 | 安全团队 |
| P0 | dm-verity/AVB完整性校验替代方案 | 安全团队 |
| P1 | SELinux策略规模差距的补齐计划 | 安全架构团队 |
| P1 | WiFi/BT重新认证的计划与成本 | 产品+合规 |
| P1 | ss-mgr看门狗、EVA引擎的真实去向确认 | BSP团队 |
| P1 | HY11/HY22等价分发机制 | Release/CRM团队 |
| P1 | DIAG/QXDM售后诊断能力完整性 | 测试/售后团队 |
| P1 | MDM/QMI专属栈(meta-qti-ss-mgr-prop套件:ssreq-server/pdc-daemon等)产品线SKU取舍 | 产品+BSP团队 |
| P1 | 多媒体资源管理器(mmrm)在QLI2.0全部已检出层及内核历史均0命中,确认无承接,是否需要重新实现 | 多媒体+内核团队 |
| P1 | camerastack/xr/vnm/host产品线在QLI2.0的迁移规划(30个变体里目前仅robotics线已承接) | 产品+系统架构团队 |
| P1 | downstream(maili)`release/kw`(Klocwork)静态扫描在QLI2.0没有替代物,`meta-qcom`/`meta-qcom-distro`/`meta-audioreach`的`.github/workflows`已核实对`codeql/klocwork/coverity/static.analysis/SAST`零命中,现有CI只做license header与build/DCO检查,是能力缺口而非尚不确定 | 质量/安全团队 |
| P1 | SDM/HWC消失后的合成能力缺口(QDCM色彩管理/HDR tone-mapping、并发多显示拓扑)在DRM/KMS+Weston下是否有等效方案——已核实"单一输出故不需要"的假设不成立,lemans-evk(2路eDP)、hamoa-iot-evk(4路DP)、sm8550-hdk(HDMI+DP)等板级是真实多输出硬件配置 | 显示/图形团队 |
| P1 | WLAN/BT量产制造测试工具链缺口——`qsaharaservice`(固件下载协议)/`ftm`(工厂测试模式)在QLI2.0无对应物,`diag-router`/`libdiag`只覆盖诊断日志路由;已核实linux-firmware的ath10k/11k/12k固件里也没有UTF类工厂测试固件变体,代码与物料侧均空白 | 制造测试团队 |
| P2 | 迁移私有内核栈需重建clang工具链体系 | Toolchain+Kernel团队 |
| P2 | 非机器人产品线是否需要补齐eSDK能力 | 产品团队 |
| P2 | meta-qti-*层迁移wrynose规范的机械性改造(`S=${WORKDIR}`→`UNPACKDIR`等,已量化510个文件) | BSP/Build团队 |
| P2 | logd/logcat兼容层在QLI2.0确认不存在(代码库全量检索零真实命中),依赖logcat语义的现有工具链/问题定位脚本迁移到journalctl/rsyslog的方案 | 平台/工具链团队 |
| P2 | downstream(maili)是否有迁移到kas的计划;技术侧已查清kas原生schema(`additionalProperties: false`)无法承载downstream(maili) manifest里`x-quic-distributable`/`x-ship`等内网扩展属性及repo凭证机制,只能靠kas之外的wrapper脚本/CI层补,若要迁移需先定这部分怎么做 | 构建/工具链团队 |
| P2 | touch、synx两个内核功能域在QLI2.0(`meta-qcom`内核配置/recipe/层目录)零命中,确认无承接;`security-TEE`(optee+minkipc)当前只挂在`rb3gen2-core-kit-open-fw`/`iq-9075-evk-open-fw`等open-fw机型变体,默认/主流机型不启用,是否要扩展到默认机型需要决策(mmrm缺口已在上表单独跟踪) | BSP/内核团队 |
| P3 | gstreamer补丁去向不明问题 | 多媒体团队 |

## 曾纠正过的结论(供复核引用时参考)

| 结论 | 初步判断 | 核实后结论 |
|---|---|---|
| SELinux | QLI2.0完全空白 | 有真实但规模远小的雏形 |
| Display overlay | 是否参与最终构建未知 | 确认参与,证据链完整 |
| clang使用范围 | 仅是可选项 | 用户态可选,内核构建曾强制使用 |
| 补丁总量 | src下约5,083个 | src中约5,080个是第三方vendored库/patman测试噪声,真实仅3个(v4l-utils);另有6个真实内核补丁实际在poky/meta-qti-bsp(而非src,此前误记为从src筛出);加上disregard/废弃备份layer 38个、build-qti-*构建残留554个均需排除,downstream(maili)全量补丁纠正后约4,861个 |
| EVA/CVP硬件证据(Camera) | 初步:kernel dts里16个文件的`cvp@`保留内存节点=硅片仍带EVA/CVP硬件IP;一度复核收窄为"证据不足",误判`cvp_kaanapali_hal.c`两侧代码库检索不到、系无效引用 | 经output/Code_Composition/Layer_Architecture/Layer_Architecture.md实测,`src/vendor/qcom/opensource/eva-kernel/msm/eva/target/cvp_kaanapali_hal.c`确实存在(Qualcomm/Linux Foundation署名,600+行含寄存器访问/PM QoS/TZ交互的完整功能代码,非样板),专为kaanapali芯片实现的CVP HAL,与QLI2.0`meta-qcom/conf/machine/kaanapali-mtp.conf`真实在用机型指向同一SoC代号,可作为硅片带EVA/CVP IP的有效交叉证据;之前"检索不到"是复核路径疏漏(未搜索`src/vendor/qcom/opensource/`路径)。结论收敛为:硅片大概率带IP,但QLI2.0内核基线未随之移植驱动(`compatible.*cvp`/`memory-region`引用仍是零命中) |
| QLI2.0 UKI是否签名(Boot_Flow/Bootargs) | 初步表述为"构建期静态烘焙进UKI,签名后不可变",暗示UKI已走secure boot签名流程 | 核实后更正:`oe-core/meta/classes-recipe/uki.bbclass`提供的`UKI_SB_KEY`/`UKI_SB_CERT`签名钩子,在`meta-qcom*`/`meta-security*`/`meta-updater`/`build/conf`范围内全局检索(含`sbsign`)均零命中,当前默认构建的UKI实际未签名;cmdline构建期固化目前只带来可预测性/可审计性,尚未带来防篡改能力 |

## 方法说明

审计基于静态代码/配置/git历史/构建产物取证,未做实机验证或完整上游三方diff(仅抽样)。已发现的若干"仅凭目录名/关键字搜索为空"导致的误判见上表,任何用于决策的关键结论应优先信任带具体命令输出、文件路径、commit hash的部分。

完整的分析方法论(工作流、与本页汇总表的关系)见[Methodology.md](Methodology.md);7条强制规则全文与各主题专属取证指引已下沉到`rules/<分类>/<主题>.md`,与下方文档索引一一对应;跨文档一致性校验脚本见`scripts/`,外部参考资料存档见`reference/`。新增或深化任何主题文档前,应先读该主题对应的`rules/`文件。

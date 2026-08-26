# QLI2.0 vs QLI1.0 架构对比 — 总览

QLI2.0代码根:`/local/mnt/workspace/jiahduan/qli2.0/0817`
QLI1.0代码根:`/local/mnt/workspace/jiahduan/8950/0804_ko_in_bak4_copy1`

## 文档索引

| 分类 | 主题文件 |
|---|---|
| System_Architecture | [Security_Architecture](System_Architecture/Security_Architecture.md) · [Yocto](System_Architecture/Yocto.md) · [Distro_Version](System_Architecture/Distro_Version.md) · [Kernel_Code_Architecture](System_Architecture/Kernel_Code_Architecture.md) · [RT](System_Architecture/RT.md) · [Overlay](System_Architecture/Overlay.md) · [Display](System_Architecture/Display.md) · [Camera](System_Architecture/Camera.md) · [Audio](System_Architecture/Audio.md) · [Graphics](System_Architecture/Graphics.md) · [WiFi_BT](System_Architecture/WiFi_BT.md) |
| Boot_Architecture | [Partition_Layout](Boot_Architecture/Partition_Layout.md) · [Boot_Flow](Boot_Architecture/Boot_Flow.md) · [Bootloader](Boot_Architecture/Bootloader.md) · [Bootargs](Boot_Architecture/Bootargs.md) · [systemd](Boot_Architecture/systemd_.md) |
| Build_Architecture | [Build_Environment](Build_Architecture/Build_Environment.md) · [Build_Tools](Build_Architecture/Build_Tools.md) · [Bitbake_Version](Build_Architecture/Bitbake_Version.md) · [Toolchain](Build_Architecture/Toolchain.md) · [Kernel_Build](Build_Architecture/Kernel_Build.md) · [SDK_eSDK](Build_Architecture/SDK_eSDK.md) |
| Code_Composition | [Code_Sync_Method](Code_Composition/Code_Sync_Method.md) · [Code_Repository](Code_Composition/Code_Repository.md) · [Layer_Architecture](Code_Composition/Layer_Architecture.md) · [Source_Code_Structure](Code_Composition/Source_Code_Structure.md) · [Branch_Management](Code_Composition/Branch_Management.md) · [Patch_Management](Code_Composition/Patch_Management.md) · [HY11_HY22](Code_Composition/HY11_HY22.md) |
| Platform_Features | [Log_System](Platform_Features/Log_System.md) · [OTA_Mechanism](Platform_Features/OTA_Mechanism.md) · [Code_Submission](Platform_Features/Code_Submission.md) · [Flash_Process](Platform_Features/Flash_Process.md) |

## 专有栈 → 开源栈对照表

| 子系统 | QLI1.0 | QLI2.0 | 详见 |
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

| 项目 | QLI1.0 | QLI2.0 | 风险等级 | 详见 |
|---|---|---|---|---|
| SELinux策略 | 661文件,默认MLS enforcing | 约3个策略点(camera+TrustZone/QTEE),默认不启用 | P1 | Security_Architecture |
| Android安全HAL分区 | keystore/secretkeeper/hwcrypto等 | 全部消失 | P0 | Partition_Layout |
| 镶像完整性校验 | dm-verity+AVB(8个bbclass) | 全套机制消失,替代方案不明 | P0 | OTA_Mechanism / Bootargs |
| SSR故障恢复看门狗 | reboot-daemon(slot切换/EDL恢复) | 未找到对应物 | P1 | Layer_Architecture |
| EVA视觉分析引擎 | libeva固件+测试套件 | 未找到对应物,转向ROS2感知栈 | P1 | Layer_Architecture / Camera |
| DIAG诊断能力 | 源码级核心组件 | 降级为测试镜像可选预编译包 | P1 | Log_System |
| HY11/HY22预编译分发 | CRM变体机制完整存在 | 无对应机制 | P1 | HY11_HY22 |

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
| P2 | 迁移私有内核栈需重建clang工具链体系 | Toolchain+Kernel团队 |
| P2 | 非机器人产品线是否需要补齐eSDK能力 | 产品团队 |
| P3 | gstreamer补丁去向不明问题 | 多媒体团队 |

## 曾纠正过的结论(供复核引用时参考)

| 结论 | 初步判断 | 核实后结论 |
|---|---|---|
| SELinux | QLI2.0完全空白 | 有真实但规模远小的雏形 |
| Display overlay | 是否参与最终构建未知 | 确认参与,证据链完整 |
| clang使用范围 | 仅是可选项 | 用户态可选,内核构建曾强制使用 |
| 补丁总量 | src下约5083个 | 约5077个是第三方工具噪声文件,真实补丁仅6个 |

## 方法说明

审计基于静态代码/配置/git历史/构建产物取证,未做实机验证或完整上游三方diff(仅抽样)。已发现的若干"仅凭目录名/关键字搜索为空"导致的误判见上表,任何用于决策的关键结论应优先信任带具体命令输出、文件路径、commit hash的部分。

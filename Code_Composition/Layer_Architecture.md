# Code Composition — Layer Architecture

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 激活层数量 | 51条(`meta-qti-*`约45个) | 约21条 |
| 命名体系 | 私有前缀`meta-qti-*`,按prop/internal/core/kernel后缀细分同一功能域 | 社区惯例`meta-qcom*`,已开源到github.com/qualcomm-linux |
| 层数降幅 | — | 约60% |

## 旧layer → 新layer映射

| QLI1.0旧layer | QLI2.0新layer/归属 | 判定 |
|---|---|---|
| meta-qti-bsp(-prop)、meta-qti-gfx-kernel(-prop)、meta-qti-touch等硬件使能层 | meta-qcom | 已合并 |
| meta-qti-camera(-prop) | meta-qcom(camx内核态) + meta-qcom-distro(libcamera用户态) | 已合并,用户态开源化 |
| meta-qti-display(-internal/-prop) | meta-qcom(wayland/mesa) | 已合并,私有HAL移除 |
| meta-qti-wlan(-prop) | meta-qcom(sigma-dut)+主线ath驱动 | 已合并,详见System_Architecture/WiFi_BT.md |
| meta-qti-bt(-prop) | meta-qcom-distro(bluez5) | 已合并,专有栈替换为标准BlueZ5 |
| meta-qti-distro | meta-qcom-distro | 一一对应 |
| meta-iot-audio(-internal/-prop) | meta-audioreach(独立开源仓库) | 整层拆出 |
| meta-qti-ss-mgr(内核态remoteproc部分) | 主线`CONFIG_QCOM_Q6V5_*`驱动 | 已迁移(架构升级) |
| meta-qti-ss-mgr(用户态reboot-daemon) | 未找到 | **需人工确认** |
| meta-qti-ss-mgr-prop(MDM/QMI专属栈) | 未找到 | 可能是产品线取舍 |
| meta-qti-aosphal-adaptation | 已移除 | **架构决策**(放弃AOSP HAL) |
| meta-qti-cta-internal | 已移除 | 随ss-mgr退役,预期内 |
| meta-qti-sv-internal/-prop(EVA引擎) | 未找到 | **需人工确认** |
| meta-qti-security-internal-common | 无法评估 | QLI1.0侧本就是空层 |
| meta-qti-security-internal(测试工具) | 底层能力已迁移(见下),测试工具本身未找到 | 低风险 |
| meta-qti-internal(各类internal QA工具) | 未找到 | 疑似系统性移除模式 |
| meta-clang | 合并进oe-core主干 | 组织形式变化,非移除(详见Build_Architecture/Toolchain.md) |
| meta-poky/meta-yocto-bsp/meta-selftest/meta-skeleton | 移除,改用纯oe-core+`nodistro` | 架构简化 |
| — | meta-qcom-robotics-sdk、meta-ros(全新) | 机器人/ROS2产品线 |
| — | meta-updater(全新) | OSTree OTA,详见Platform_Features/OTA_Mechanism.md |
| — | meta-security/meta-tpm(全新) | TPM2安全栈 |
| — | meta-lts-mixins(全新) | Yocto LTS固件对齐 |

## 逐层核实证据摘要

| 层 | QLI1.0原功能 | QLI2.0核实结果 |
|---|---|---|
| meta-qti-ss-mgr | `init_rproc_mss.service`本身是remoteproc sysfs封装;`reboot-daemon`处理SSR失败后slot切换 | 内核`CONFIG_QCOM_Q6V5_MSS`等主线驱动确认保留;用户态reboot-daemon及MDM/QMI专属栈(ssreq-server等)全树零命中 |
| meta-qti-aosphal-adaptation | `libhardware_1.0.bb`+`camera-metadata_1.1.bb`,给CamX复用AOSP HAL接口 | libcutils/liblog/libbinder等基础Android兼容库全部不存在 |
| meta-qti-sv-internal/-prop | 产出`libeva`,即EVA计算机视觉分析引擎固件与测试套件 | `eva/libeva/evass`全树零命中,机器视觉转向ROS2/qrb-ros-*栈 |
| meta-qti-security-internal | mink传输层测试、QTVM测试TA、TUI资源 | `qseecom/mink-transport`零命中;但底层能力已升级为主线Linux TEE子系统+`qcom-tee`+生产版minkipc |

## 影响与风险

- 层合并使原有`-internal`/`-prop`/`-core`(开源/内部专有/客户可见)边界在物理目录层面消失,新的边界控制机制需确认。
- `meta-qti-ss-mgr`用户态reboot-daemon和EVA引擎是本次审计风险最高的未决问题,分别涉及系统稳定性和产品能力。
- `meta-qti-internal`系列的QA/调试/基准测试工具呈系统性消失模式,可能转移到未提交的独立测试仓库。

## 待确认

- SSR故障恢复看门狗在QLI2.0是否有等价物,还是下沉到bootloader。
- EVA对应硬件模块在QLI2.0目标平台是否仍存在。
- TUI相关能力是否有生产级实现。
- internal-only QA工具是否转移到独立测试仓库。

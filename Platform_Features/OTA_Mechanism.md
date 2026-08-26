# Platform Features — OTA Mechanism

## 对比总览

| 维度 | QLI1.0(AB-OTA/recovery) | QLI2.0(OSTree+aktualizr) |
|---|---|---|
| 核心组件 | `src/OTA/`(AOSP recovery/releasetools/update_engine移植),`libabctl`自研A/B切换库 | `meta-updater`层,aktualizr+ostree |
| 升级粒度 | 分区镜像整包,或bsdiff文件级差分 | 文件系统级commit(硬链接去重) |
| 存储占用 | A/B双分区各占一份完整镜像(典型2x rootfs) | 内容寻址+硬链接共享未变化文件 |
| 回滚机制 | GPT分区属性(优先级+尝试次数) | u-boot环境变量bootcount(`aktualizr-uboot-env-rollback`) |
| 服务端要求 | 无强制后端,可自建HTTP分发签名包 | 需Uptane/TUF兼容服务端(HERE OTA Connect或自建) |
| 触发环境 | 需重启进recovery模式 | aktualizr在线运行时后台拉取部署 |
| 默认启用 | 是(recovery/bootctrl是核心交付件) | 否,需选`qcom-distro-sota`变体 |
| 镜像完整性校验 | dm-verity/AVB(8个bbclass) | 全套机制确认消失(详见Boot_Architecture/Bootargs.md、systemd_.md) |

## 关键差异

- OTA机制从Android式A/B分区切换为OSTree原子文件系统升级,是本次审计架构断裂最大的单点。
- 追踪QLI1.0的verity相关systemd补丁去向时发现:QLI2.0不只是换了OTA机制,连整套dm-verity/AVB镶像完整性校验也一并消失,三方证据(本文档+Bootargs.md+Partition_Layout.md)互相印证。

## 影响与风险

- 服务端需从"托管签名zip包"重建为完整的Uptane TUF基础设施,是架构级重建。
- 首次产线刷机不受OSTree影响(仍走QDL整机镶像,详见Flash_Process.md),但售后/远程升级SOP需重新设计。
- OTA能力是opt-in的,若产品仍按默认`qcom-distro`构建将完全没有OTA能力。
- **QLI2.0根文件系统完整性校验替代方案不明确**,是本文档最高优先级的待确认项。

## 待确认

- 目标产品最终选择哪个distro,是否所有SKU都需要OTA。
- OTA服务端方案(采购HERE OTA Connect或自建)及密钥管理归属。
- OSTree `static-deltas`是否已启用以对齐QLI1.0 bsdiff的增量包体积。
- abctl与aktualizr-uboot-env-rollback两套回滚机制在同一bootloader上是否冲突。
- dm-verity/AVB消失后镜像完整性靠什么保证(是否有等价机制,还是完全依赖OSTree commit签名)。

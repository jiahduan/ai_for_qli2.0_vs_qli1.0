# System Architecture — Security Architecture (SELinux)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 上游层 | `poky/meta-selinux`,libselinux/checkpolicy等版本3.6,refpolicy基线2024-02快照 | `meta-selinux`,版本升至3.10,refpolicy基线2026-03快照 |
| Qualcomm定制策略层 | `poky/meta-qti-sepolicy`,独立repo,661个`.te`/`.fc`/`.if`文件 | `meta-qcom/dynamic-layers/selinux/`,以patch形式内嵌,规模约3个策略点 |
| 策略组织方式 | `common/`(361文件,跨机型公共域)+ `alor/kera/pebble/sdmsteppe`(机型专属)+ 12个patch | `qcom_nhx`(相机测试工具域)+ `tee_supplicant_qtee`(TrustZone/QTEE适配)+ 曾有pd-mapper(已随上游可用而移除) |
| 策略类型 | MLS(弱化版,`disable-mls-constraints.patch`删除大部分mlsconstrain规则) | 默认`refpolicy-targeted`(社区通用策略) |
| 默认启用状态 | 默认开启,enforcing,provider钉死`refpolicy-mls-robotics` | 默认关闭,需选`qcom-distro-selinux`等独立DISTRO变体 |
| 维护活跃度 | — | 2025-10~2026-07持续提交,含"推上游后清理本地patch"记录 |
| relabel机制 | `label-cache/data/persist/systemrw.service`配合overlay做restorecon | 无对应物 |
| 替代隔离机制排查 | — | AppArmor/Firejail存在于meta-security但未被任何镜像引用,属死代码;无Landlock集成 |

## 关键差异

- QLI1.0覆盖audio/camera/modem/加密/OTA/诊断等数十个高权限daemon的域定义;QLI2.0仅覆盖相机测试工具和TrustZone/QTEE两小块。
- `qc/le-sepolicy.lnx`是manifest分支族名称,内容仅为合规声明`cd.xml`,真正策略源码在`meta-qti-sepolicy`,不要被目录名误导。
- QLI2.0策略以patch形式打入refpolicy-targeted源码树,直接搜索`.te/.fc/.if`文件扩展名会漏判(第一次核查即因此误判为"完全空白")。
- 裁剪机制(`PURGE_POLICY_MODULES`等按MACHINE_FEATURES条件生成策略)QLI2.0无对应物。

## 影响与风险

- 安全基线存在弱化风险,但非"从零开始"——QLI2.0已有真实维护中的雏形。
- 661个策略文件迁移需在新refpolicy基线(跨2年演进)和libselinux 3.10上重新验证,工作量大。
- 若重新启用selinux而未补齐relabel服务,overlay分区重新打包后可能出现unlabeled_t导致AVC拒绝。

## 待确认

- meta-qcom安全团队后续策略覆盖范围规划(是否会扩大到接近QLI1.0水平)。
- 产品目标策略类型(弱化MLS/targeted/虚拟化-TEE分担隔离职责)。
- QLI1.0四个机型目录(alor/kera/pebble/sdmsteppe)与QLI2.0新机型的映射关系。
- 合规声明流程在新仓库结构下归属。
- robotics场景策略是否本就未做过(QLI1.0该目录本身为空),而非迁移丢失。
- 本地checkout落后于上游最新进度,建议同步后重新核实覆盖范围。

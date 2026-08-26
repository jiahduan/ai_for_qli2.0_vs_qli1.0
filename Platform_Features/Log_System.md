# Platform Features — Log System

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 基础日志 | systemd/journald | systemd/journald,新增rsyslog+logrotate定制 |
| Android兼容日志 | logd+logcat完整AOSP实现,已适配systemd(`/dev/socket/logdw`) | 无对应组件 |
| Qualcomm DIAG | `src/diag`全量源码,核心组件 | `recipes-test/diag`,闭源预编译包,与diag-router互斥 |
| DIAG镜像集成 | 随发布默认存在 | 仅`qcom-multimedia-proprietary-image`等特定镜像依赖`libdiag-bin` |

## 关键差异

- Android logd/logcat兼容层完全消失,依赖该语义读日志的应用/HAL组件无对应接口。
- DIAG从"源码级核心组件"降级为"测试镜像/可选预编译二进制",量产镜像默认可能不含完整能力。

## 影响与风险

- 依赖QXDM/QPST做售后诊断的流程受DIAG降级直接影响。
- rsyslog落盘策略是否已过安全合规评审需确认。

## 待确认

- `libdiag-bin`/`diag-router`量产machine/distro的默认启用范围。
- 是否有计划提供logd/logcat兼容层,还是要求上层应用迁移journald API。

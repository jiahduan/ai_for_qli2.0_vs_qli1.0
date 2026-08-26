# Boot Architecture — Partition Layout

> QLI1.0默认样例为`pebble`(手机类SoC),QLI2.0默认为`iq-9075-evk`(基于QCS9100的机器人开发板),差异含硬件世代因素。

## 对比总览

| 维度 | QLI1.0(pebble) | QLI2.0(iq-9075-evk) |
|---|---|---|
| 分区总数 | 156个 | 67个 |
| OS层A/B分区 | `boot_a/b`、`system_a/b`、`dtbo_a/b`、`userdata` | 无,单一`rootfs`分区 |
| 底层固件A/B | `xbl_a/b`、`tz_a/b`、`hyp_a/b`(SoC ROM强制要求) | 同样保留A/B |
| Android安全HAL分区 | `keystore`、`secretkeeper_a/b`、`hwcrypto_a/b`、`frp` | 均不存在,仅保留`keymaster_a/b` |
| 新增分区 | — | `gearvm_a/b`(虚拟化)、`recoveryinfo`、日志类分区 |
| A/B管理组件 | `src/bootctrl/abctl` | 无对应组件 |

## 关键差异

- OS层从A/B双分区改为单一分区,是OTA升级模型(A/B切换→OSTree原子部署)转变的直接体现(详见Platform_Features/OTA_Mechanism.md)。
- Android安全HAL分区全部消失,依赖这些分区的硬件密钥库/防重放计数器服务需重新实现或改为软件方案。

## 影响与风险

- 单分区模型下若rootfs写坏,没有物理备用分区可切回,回滚可靠性需重新评估。
- QLI2.0当前默认构建未开`sota`,rootfs是普通ext4镜像,OTA机制未真正接线。

## 待确认

- 需"同代同芯片"样本剥离产品形态差异的干扰。
- 低层固件槽位(xbl_a/b等)的A/B判定与回滚在QLI2.0由谁管理。

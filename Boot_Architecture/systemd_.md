# Boot Architecture — systemd

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| systemd版本 | 255.21 | 259.5 |
| vendor层.service数量 | 125个(meta-qti-bsp 41、meta-qti-wlan 16、meta-qti-security-prop 9等) | 约7个(meta-qcom 1个`format-tee-partition.service`,meta-updater 6个aktualizr相关) |
| 定制补丁 | 3个:securityfs挂载禁用、verity cmdline支持、D-Bus特权uid放行 | 1个:UEFI PE段对齐修复(与业务逻辑无关) |

## 补丁去向

| QLI1.0补丁 | 内容 | QLI2.0对应情况 |
|---|---|---|
| `Disable-unused-mount-points.patch` | 禁用securityfs自动挂载 | 无对应,原因不明,需人工确认 |
| `fstab-generator-Honor-verity-enabled-cmdline.patch` | 识别verity cmdline强制走dm-verity根设备 | 无对应——整套dm-verity/AVB机制(8个bbclass)已消失 |
| `sd-bus-Allow-extra-users-to-communicate.patch` | 放行uid 1000/1001跨D-Bus通信 | 无对应——QLI1.0私有uid体系不存在于QLI2.0 |

## 关键差异

- Unit定制量125→7断崖式下降,更可能是meta-qcom尚未覆盖QLI1.0那些垂直子系统,而非架构精简。
- 新增unit全部与`meta-updater`(aktualizr/OTA)相关,是QLI1.0没有的能力域。

## 影响与风险

- 版本跨4个大版本,mount生成规则、cgroup默认值等行为变更需逐一回归测试。
- `aktualizr*.service`引入新的常驻网络更新客户端,证书管理与信任链需安全评审。
- securityfs挂载消失需排除对IMA/AppArmor等安全功能的影响。

## 待确认

- WLAN/相机/安全等子系统的systemd化管理在QLI2.0的补齐计划。
- 建议做一次255.21→259.5官方changelog逐条评审。

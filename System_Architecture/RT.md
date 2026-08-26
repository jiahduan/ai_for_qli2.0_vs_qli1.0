# System Architecture — RT

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| RT内核独立recipe | 无(仅上游`linux-yocto-rt_6.6.bb`样板,未接线) | 有:`linux-qcom-rt_6.18.bb`、`linux-qcom-next-rt_git.bb` |
| CONFIG_PREEMPT_RT实际赋值 | 遍历全部defconfig/fragment均未发现`=y` | `rt.config`: `CONFIG_PREEMPT_RT=y`(已在构建产物验证) |
| RT运行时调优 | 无 | `QCOM_RT_CPU`(isolcpus)、`QCOM_IRQAFF`(irqaffinity)等cmdline拼装框架,≥9个机型已赋实值 |
| CI验证 | 无 | 独立CI矩阵(`ci/linux-qcom-rt-6.18.yml`等) |
| 默认kernel provider | 不适用 | 仍为`linux-yocto`(非RT),RT需手动切换 |

## 关键差异

- QLI1.0没有任何走向生产的PREEMPT_RT路径;QLI2.0为工业/机器人场景新增了完整RT演进路径。
- RT内核走`qualcomm-linux/kernel.git`社区路线,与QLI1.0基于Android common kernel的内核完全不同源(详见Kernel_Code_Architecture.md)。

## 影响与风险

- 需维护`linux-qcom`与`linux-qcom-rt`两套内核树,升级节奏是否同步需评估。
- RT调优参数仅覆盖少数IQ系列机型,若被客户依赖需明确承诺支持的SKU范围。

## 待确认

- RT内核是否已经/计划成为某产品线默认内核。
- QLI1.0是否在审计范围外的分支启用过PREEMPT_RT。
- RT调优参数只覆盖部分机型是否符合预期。

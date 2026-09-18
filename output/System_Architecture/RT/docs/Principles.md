# RT 原理文档

本文档解释RT(实时性)主题在Qualcomm Linux BSP体系里管什么、为什么要对比它、以及它与相邻主题的分工原理——这是理解`RT.md`具体差异结论的前置知识,不涉及downstream(maili)/QLI2.0具体差异结论(结论见`../RT.md`)。

## 1. RT管的是"实时性能力启用状态",不是内核代码血统

PREEMPT_RT是Linux内核的一个可选补丁集/配置项,把内核从"尽力而为的低延迟"改造为"可预测的确定性延迟",代价通常是牺牲一部分吞吐量。RT本文档管的是双侧对这一能力的接线/启用/运行时调优状况——是否存在独立的RT kernel provider(如`linux-qcom-rt`)、`CONFIG_PREEMPT_RT`是否真的被置为`y`、有没有配套的cmdline调优框架(isolcpus/irqaffinity等)与已启用的具体机型清单。这是一个横切的"能力维度"视角,不涉及内核代码本身是从哪个仓库来的、和谁同源——那是Kernel_Code_Architecture的范畴。

同一段代码完全可以同时被两种视角分析而不冲突:比如`linux-qcom-rt_6.18.bb`这个recipe,从"代码血统"视角看是"require了linux-qcom_6.18.bb再叠加RT config"(Kernel_Code_Architecture关心的问题);从"能力启用状态"视角看是"这个provider是否真的打开了CONFIG_PREEMPT_RT、配了什么cmdline参数、哪些机型选用了它"(本主题关心的问题)。两个视角回答的是不同问题,不构成重叠。

## 2. 为什么要对比这个主题

RT能力直接关系到工业控制/机器人场景对确定性延迟的硬性要求。downstream(maili)完全没有面向生产的PREEMPT_RT路径(只有未接线的上游样板),QLI2.0新增了完整的实时性演进路径(独立recipe+cmdline调优框架+CI验证矩阵),这是一次"能力新增"而不是"架构对等替换"。对比的现实意义在于给产品/客户团队一份准确的"哪些SKU官方支持RT"清单,而不是一句笼统的"支持RT"——已启用的机型清一色是IQ工控评估板/机器人核心套件,与消费类评估板形成清晰的产品定位分野,这种颗粒度的信息只有逐机型核查才能得到。

## 3. 与相邻主题的分工边界原理

- RT内核相对mainline/downstream(maili)内核的源码血统、仓库治理主体(commit标签体系、庭院多仓 vs 单一mainline-first等)归Kernel_Code_Architecture——这条边界在本文档内已明确核对过:Kernel_Code_Architecture的commit标签/仓库治理层分析本身不含PREEMPT_RT diff内容,所以本主题保留PREEMPT_RT补丁集具体代码改动的核查(不排除出去),只把通用内核治理部分让给Kernel_Code_Architecture。
- RT cmdline参数(isolcpus/irqaffinity等)的具体拼装机制由本主题定义,Bootargs.md反向引用本主题作为这些参数的权威出处——即"谁产生这个参数"归本主题,"cmdline整体怎么拼装、还有哪些其他来源的参数"归Bootargs,两者方向一致不冲突。

判断原则:**"这个能力有没有被启用、启用到什么程度"归本主题;"承载这个能力的代码本身是从哪来的"归Kernel_Code_Architecture**——RT是本轮9个主题里对"同一份代码、不同视角、不冲突"这一分工哲学阐述最直接的案例。

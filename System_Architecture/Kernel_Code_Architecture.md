# System Architecture — Kernel Code Architecture

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 内核版本 | 6.18.21(`src/kernel-6.18/kernel_platform/common/Makefile`) | 6.18.30(`linux-qcom_6.18.bb`,SRCREV=`5086fd78561b...`) |
| 源码来源 | Qualcomm内部repo manifest管理的`kernel_platform`大树 | `git://github.com/qualcomm-linux/kernel.git`,标准`inherit kernel` |
| 引用机制 | `SRC_URI file://`整树本地拷贝 | `SRC_URI git://...;SRCREV=...`,bitbake原生fetcher |
| 源码组织 | "庭院式多仓": common(ACK)+soc-repo(SoC覆盖)+common-modules(树外GKI模块) | 单一仓库,SoC定制直接commit进kernel.git |
| 仓库治理主体 | Google Android Common Kernel(ACK)/GKI,quicinc内部Gerrit | Qualcomm官方GitHub,`qcom-6.18.y`分支 |
| commit标签体系 | `ANDROID:`、`UPSTREAM:`、`Snap for <bug>` | `QCLINUX:`、`FROMLIST:`(488条)、`BACKPORT:`(102条)、`WORKAROUND:`(11条) |
| GKI vendor-hook基建 | `sched/core.c`含46处`android_vh_/android_rvh_`钩子 | 对应位置0处钩子,更贴近纯净mainline |
| 高度上游化驱动示例 | `drivers/soc/qcom/socinfo.c` 857行 | 同文件862行,仅5行插入,版权头逐字一致 |
| 产品机型kernel provider | `linux-msm`/`linux-common-soc`(私有大树) | `linux-qcom`(`qcom-base.inc`强制`?=`设定),`linux-yocto`+kmeta仅服务上游参考机型 |

## 同源性结论

- 最底层(mainline Linux+上游QCOM驱动):同源,置信度高——socinfo.c几乎逐字相同,6.18.21/6.18.30同处一条stable tag序列。
- 中间层(是否叠加Android GKI vendor-hook):分叉,置信度高——是治理决策不是代码腐化。
- 仓库治理层:完全独立——两侧commit历史无一条可直接对应,QLI2.0确认是从多仓庭院结构收敛为单一仓库,是真实架构重构。

## 影响与风险

- Layer兼容性:`linux-yocto_6.18.bbappend`挂的DTS patch对应真实产品provider `linux-qcom`不生效,是潜在死配置。
- 每个驱动独立SRCREV,升级内核大版本时兼容性验证工作量分散到各独立仓库,需建立跨仓库兼容性矩阵。
- 与Toolchain.md联动:QLI1.0现役机型内核构建强制用AOSP预编译clang,QLI2.0无对应体系。

## 待确认

- `linux-yocto_6.18.bbappend`里针对monaco-evk等机型的DTS patch是否为遗留代码。
- `linux-qcom-rt`/`linux-qcom-next`两个变体与主线SRCREV是否同步。
- QLI1.0的8个vendor驱动在QLI2.0是否已有`-dlkm`recipe承接(详见Build_Architecture/Kernel_Build.md)。
- 若要做完整patch级diff,需拉取纯净Linux 6.18.21/6.18.30 mainline tag做三方diff,并补上QLI1.0侧的soc-repo(本次只分析了common)。
- 当前已checkout的工作树仅对应`iq-9075-evk`一台机器,其他machine需逐一核实SRCREV。

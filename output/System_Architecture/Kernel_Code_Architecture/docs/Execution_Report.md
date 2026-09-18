# Kernel_Code_Architecture 规则执行逻辑细节报告

本文档记录`Kernel_Code_Architecture.md`当前内容是怎么从源码证据一步步推导出来的——按`rules/System_Architecture/Kernel_Code_Architecture.md`"Kernel_Code_Architecture专属取证要点"逐条复盘,每一条"做了什么→得到什么证据→落到最终结论的哪一行"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Kernel_Code_Architecture.md`。

## 1. 版本与源码获取机制核实

**做法**:核对downstream(maili)`kernel_platform/common/Makefile`的VERSION/PATCHLEVEL/SUBLEVEL赋值、`.repo/manifests/*.xml`的镶像标签、`SRC_URI file://`整树拷贝机制;核对QLI2.0`linux-qcom_6.18.bb`的`LINUX_VERSION`/`SRCREV`/`tag`三者是否一致。
**证据**:6.18.21 vs 6.18.30版本号;QLI2.0侧`SRCREV=5086fd78561b...`与`tag=qcom-6.18.y-20260615.1`及本地HEAD commit三者完全一致。
**落到结论**:对比总览表"内核版本""源码来源""引用机制"三行。

## 2. 仓库治理与源码组织核实(庭院多仓 vs 单一仓库)

**做法**:逐一确认downstream(maili)`kernel_platform/common`(ACK)、`soc-repo`(SoC覆盖层,含`ack2soc.sh`)、`common-modules`(树外GKI模块)、`devices/google`、`external`各自的remote与git仓库身份;核实第5个庭院仓库`kernel_platform/qcom/opensource/devicetree`(独立git,remote`quic`,6726个dts文件)是否被`linux-common-soc_6.18.bb`的`SRC_URI`真实引用。
**证据**:确认该devicetree仓库不是死配置,而是被`SRC_URI file://qcom/opensource/devicetree`真实引用;QLI2.0侧确认单一仓库`build/downloads/git2/github.com.qualcomm-linux.kernel.git`。
**落到结论**:对比总览表"源码组织"行,以及"覆盖"字段本次新核实到的第5个庭院仓库记录。

## 3. GKI vendor-hook基建存废核实

**做法**:对`kernel/sched/core.c`两侧重新grep`android_vh_`/`android_rvh_`/`trace_android`钩子数量及文件字节数。
**证据**:downstream(maili)侧46处钩子、319379字节;QLI2.0侧0处、290393字节,两个数字均精确复现。
**落到结论**:对比总览表"GKI vendor-hook基建"行,"同源性结论"节"中间层完全分叉,置信度高"的判断。

## 4. commit标签体系抽样统计核实

**做法**:对`qcom-6.18.y-20260615.1`标签重新跑近3000条commit抽样,按标签前缀分类统计。
**证据**:`FROMLIST:`488条、`BACKPORT:`102条、`QCLINUX:`41条、`PENDING:`32条、`WORKAROUND:`11条,五个标签量级排序与原文一致(具体条数存在抽样窗口带来的正常波动,已按规则3做抽样声明)。
**落到结论**:对比总览表"commit标签统计"行,"关键差异"节"定制改动尽量往先投上游方向收敛"的判断。

## 5. commit集合级同源性统计与soc-repo盲区纠错(本文档取证重点)

**初步方法**:按目录做commit subject集合diff(如`drivers/soc/qcom/`、`drivers/power/supply/qcom_*`、`drivers/thermal/qcom*`、`drivers/remoteproc/qcom_*`),但只纳入了downstream(maili)的`common`仓库,未纳入`kernel_platform/soc-repo`。

**初步结论**:上述四个目录downstream(maili)独有commit数均为0,即"两侧完全打平"。

**发现盲区**:意识到`kernel_platform/soc-repo`(独立git仓库,HEAD`61351abdf37b`,`ack2soc.sh`合并脚本的目标仓库)承载了大量SoC覆盖层改动,未纳入统计会漏掉这部分改动。

**补入soc-repo后的复核**:重新做同一方法的subject集合diff(QLI2侧统一用`qcom-6.18.y`分支)。结果分两类:`drivers/gpu/drm/msm/`、`arch/arm64/boot/dts/qcom/`、`drivers/media/platform/qcom/`三个目录补入soc-repo后"几乎全部被QLI2覆盖"的结论依然成立(QLI1独有条数仅个位数);但`drivers/soc/qcom/`(从0跳到1560条)、`drivers/power/supply/`(从0跳到139条)、`drivers/thermal/`(从0跳到214条)、`drivers/remoteproc/`(从16条跳到326条)四个目录的"完全打平"结论不成立,soc-repo带来了common仓库里完全没有的大量独立改动。

**最终结论**:soc-repo确实是此前统计的主要盲区,补入soc-repo后需要把"最底层同源"的结论按目录拆分处理——对gpu/drm/msm、dts、media三个目录仍站得住,对soc/qcom、power、thermal、remoteproc四个目录需要修正为"存在数量可观的QLI1独有改动"。

**落到结论**:"同源性结论"节"补入soc-repo后的复核(原待确认项已解决)"完整段落,"关键差异"节"两代内核同源度高不是一个可以整体外推的结论,必须按子系统分别核实"的判断。这一纠错的教学意义在于:统计范围本身(是否覆盖了downstream(maili)的全部代码来源)是同源性判断能否成立的前提,只看主仓库容易得出过于乐观的结论。

## 6. 三方(mainline)抽样验证

**做法**:拉取`github.com/gregkh/linux`(stable树镜像)的`v6.18.21`标签,对`socinfo.c`/`pmic_glink.c`做三方diff。
**证据**:QLI1侧与mainline逐字节相同;QLI2侧`pmic_glink.c`有77行增量(对应FROMGIT的SOCCP remoteproc通道支持)。
**落到结论**:"同源性结论"节"最底层同源,置信度高"的判断,并明确声明这只是抽样(两个具体文件),不能外推为整个`drivers/soc/qcom/`目录的同源比例。

## 7. mmrm全链路缺口核实

**做法**:`git log --all -i --grep=mmrm`跨全部bitbake层及QLI2.0内核完整git历史。
**证据**:零命中,唯一字符串命中是AMD GPU寄存器命名`gc_*_offset.h`里的`mmRM...`巧合子串,与多媒体资源管理器无关。
**落到结论**:"影响与风险"节"确认是真实功能缺口而非尚未搜索到"的判断。

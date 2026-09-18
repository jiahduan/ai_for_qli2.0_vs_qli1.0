# RT 规则执行逻辑细节报告

本文档记录`RT.md`当前内容是怎么从源码证据一步步推导出来的——按`rules/System_Architecture/RT.md`"RT专属取证要点"逐条复盘,每一条"做了什么→得到什么证据→落到最终结论的哪一行"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../RT.md`。

## 1. RT内核独立recipe存在性与接线状态核实

**做法**:核对downstream(maili)`poky/meta/recipes-kernel/linux/linux-yocto-rt_6.6.bb`是否被任何bb/machine接线;核对QLI2.0`linux-qcom-rt_6.18.bb`(`require linux-qcom_6.18.bb`)与`linux-qcom-next-rt_git.bb`。
**证据**:downstream(maili)侧确认是上游样板,未被任何bb/machine接线,`rt-tests`同样未接线;QLI2.0侧确认两个独立recipe真实存在且有require关系。
**落到结论**:对比总览表"RT内核独立recipe"行。

## 2. CONFIG_PREEMPT_RT实际赋值全量核查

**做法**:对downstream(maili)`arch/arm64/configs/{defconfig,gki_defconfig,*.fragment}`及各`build.config`全量grep,并扩展核查`poky/meta-qti-distro`全目录(含`qti-distro-camerastack-debug.conf`及其include链)grep`CONFIG_PREEMPT_RT`/`rt-tests`;对QLI2.0读取`linux-qcom-rt_6.18.bb`里`KBUILD_CONFIG_EXTRA:append:aarch64`引用的`arch/arm64/configs/rt.config`,并在构建产物`build/tmp/work-shared/iq-9075-evk/kernel-source/arch/arm64/configs/rt.config`验证真实合并进`.config`。
**证据**:downstream(maili)侧全量检索0命中;QLI2.0侧`CONFIG_EXPERT=y`/`CONFIG_PREEMPT_RT=y`确认真实生效(不是仅存在于recipe声明层面,而是在构建产物里验证过)。
**落到结论**:对比总览表"CONFIG_PREEMPT_RT实际赋值"行。

## 3. RT运行时调优cmdline框架核实

**做法**:读取`meta-qcom/conf/machine/include/qcom-common.inc`,核对`QCOM_RT_CPU`/`QCOM_IRQAFF`/`QCOM_RCU_NOCBS`/`QCOM_RCU_EXPEDITED`/`QCOM_CPUIDLE_OFF`五个变量如何拼装为`isolcpus`/`irqaffinity`/`rcu_nocbs`/`rcupdate.rcu_expedited`/`cpuidle.off`cmdline参数,并读取该文件第74行注释"Default values (machines override these)"确认五个变量默认值均为空字符串。
**证据**:机制上是"默认不生效,按机型显式opt-in"的设计。
**落到结论**:对比总览表"RT运行时调优框架"行,"关键差异"节"是刻意区分而非遗漏"的判断。

## 4. 已赋实值机型清单逐一核对

**做法**:逐一核对`meta-qcom`全部19个machine conf(含`require`链)是否设置`QCOM_RT_CPU`。
**证据**:统计出≥9个已赋值机型(IQ工控评估板/机器人核心套件族),以及2个同族未赋值机型(`iq-x5121-evk`、`rb1-core-kit`/`qrb2210-rb1-core-kit`)。
**落到结论**:对比总览表"已赋实值机型"行,"影响与风险"节"两个具体缺口"的判断——这条结论的价值在于逐一核对了全部19个machine conf,而不是只列出已知的几个正面案例,能同时给出"谁被覆盖了、谁被遗漏了"两侧清单。

## 5. downstream(maili)仓库外分支历史边界核查

**做法**:对`kernel_platform/soc-repo`(remote`quic/qcom-6.18`)与`kernel_platform/common`(remote`quic/keystone/android17-6.18-keystone-qcom-release`)两仓库跑`git log --all -p`,对`arch/arm64/configs/*`路径做`CONFIG_PREEMPT_RT=y`全文匹配,分别135万+/141万+条commit可达。
**证据**:确认本地可见全部历史均零命中,即不仅当前checkout,这两个仓库本地镶像到的分支在全部历史版本里也从未在defconfig里置过这一项。
**证据边界说明**:每个仓库本地只镶了1条远程分支,代码侧线索已用尽,但这只能证明"这两个本地镜像看不到",不能排除仓库外其他分支或私有构建启用过该特性。这是如实反映证据能到达的边界,不是"初步判断被推翻"意义上的纠错——该主题的判断从始至终都是"本地可见历史零命中",只是补充说明这个证据的覆盖范围有限。
**落到结论**:"待确认"节"downstream(maili)在仓库外分支/私有构建是否启用过PREEMPT_RT"这一开放问题,确认步骤指向需向downstream(maili)内核/BSP团队做最后确认。

## 纠错记录说明

本主题`rules/System_Architecture/RT.md`"已知易错点/纠错记录"栏标注为"(暂无纠错记录)"。上文第5条的"证据边界说明"性质是对证据局限性的如实说明,不是某个先前判断被后续证据推翻,因此不计入纠错记录,与原文标注一致。

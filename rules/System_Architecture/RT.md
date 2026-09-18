# RT —— 规则

> 本文件对应产出文档 [output/System_Architecture/RT/RT.md](../../output/System_Architecture/RT/RT.md),与全部33份主题规则文件按本次目录重构选择的方式各自完整独立(7条强制规则全文一致,不做共享继承,变更时需同步维护;背景见[Scope_Section_Design.md](../../Scope_Section_Design.md))。全局工作流/与README关系见根目录[Methodology.md](../../Methodology.md)。

## 强制规则

以下规则对所有主题文档硬性生效,不因主题不同而放宽。

### 1. 证据引用标准

任何结论性陈述必须能追溯到以下至少一种证据:
- 具体文件路径(尽量带行号),如`meta-qcom/classes-recipe/image_types_qcom.bbclass`第127-136行
- 检索命令及其实际输出,如`grep -rln "abctl|libabctl" meta-qcom meta-qcom-distro meta-updater`零匹配
- git commit hash / `git log`/`git describe`输出
- 官方文档原文引用(需注明来源与核实方式,见规则6)

**禁止**仅凭目录名或关键字搜索为空就断言"某功能已消失"——必须展示实际检索命令及零命中证据,并在可能时交叉检索多个关键字变体(如同时检索`abctl`与`libabctl`)。

### 2. 统一文档结构

每个主题文档必须按以下顺序包含章节(可在中间插入主题专属章节,但首尾两类不可省略):

0. `## 对比范围` — 三个固定字段,必须都出现:
   - **覆盖**:本文实际比较的子项列表,每项标明双侧目录/文件锚点。单条bullet的"锚点+说明"过长(经验值:超过约150字/接近一整段)时,拆成更细的子bullet,不要塞成一段长文字,保持列表可扫读
   - **明确排除**:本主题名义上涉及、但结论归属别的文档的项——不要求"正文已经字面提到过才能排除",只要读者可能预期在本文找、但实际该去别的文档找,就该排除。每条只写"项名 ——见[YY](相对路径/YY.md)",不展开排除理由(理由留给目标文档自己交代,或在本文正文引用处简要说明,不塞进这一行);用markdown链接而非书名号,保持和README索引表一致的可点击引用风格;有多条时每条单独一行列出(子bullet),不要用分号堆在同一行——方便脚本按行解析,也方便人工审阅
   - **待定边界**:暂时定不下来该归哪篇、先记录别漏掉的项;为空写"(无)"——如果是"核实过确认没有"而非"没检查",可以写成"(无,已核实XX)"这种形式简要说明核实范围,不算违反"为空写(无)"的要求;随本文档下次修订顺带复核,不单开复核周期;若长期悬而未决,同步进README《待拍板事项汇总》

   本节是文字化元信息(管辖边界、目录锚点、排除去向),不重复下面《对比总览》表已有的对比结论;《对比总览》也不解释某项为何不在表里——两节不互相转述。
1. `## 对比总览` — 一张`维度 | downstream(maili) | QLI2.0`表格,是文档骨架,让读者10秒内看到全貌
2. (可选)主题专属深挖章节 — 追踪表、抽样统计、专项验证等
3. `## 关键差异` — 综合性洞察,**不是对总览表的复述**,要回答"这些差异放在一起意味着什么"
4. `## 影响与风险` — 对下游团队/决策的具体影响,不做纯技术总结

### 2.1 RT源码级分析方法论(7步,替代默认的"分类专属取证指引"取证起点)

以架构师视角做source-level分析,不满足于"是否支持RT"这种抽象产品维度判断,按下面顺序找证据:

1. **定位RT能力的物理载体**:哪个recipe/kernel provider承载PREEMPT_RT——downstream(maili)`poky/meta/recipes-kernel/linux/linux-yocto-rt_6.6.bb`(上游样板);QLI2.0`meta-qcom/recipes-kernel/linux/linux-qcom-rt_6.18.bb`(`require linux-qcom_6.18.bb`)/`linux-qcom-next-rt_git.bb`;先确认该recipe是否真的被`PREFERRED_PROVIDER_virtual/kernel`接线到任何实际构建,不能只看recipe文件存在。
2. **看CONFIG_PREEMPT_RT核心变量的实际赋值点,并下沉到构建产物验证**:不满足于recipe/config片段声明层面,要在真实生成的`.config`里核实是否真的合并进去——QLI2.0在`arch/arm64/configs/rt.config`(`KBUILD_CONFIG_EXTRA:append:aarch64`引用)声明`CONFIG_PREEMPT_RT=y`,并在具体机型的构建产物`.config`里验证(默认provider下应为"is not set",RT provider片段本身应为"=y");downstream(maili)侧对defconfig/fragment/build.config全量grep之外,还要下沉到具体机型的真实构建产物`.config`二次确认。
3. **区分"内核能力层"与"机型调优层"两层机制,不要混为一谈**:
   - 内核能力层:`PREFERRED_PROVIDER_virtual/kernel`从`linux-qcom`切到`linux-qcom-rt`决定`CONFIG_PREEMPT_RT`是否`=y`,这一层的门槛是recipe的`COMPATIBLE_MACHINE`(`linux-qcom_6.18.bb`声明`"(qcom)"`,覆盖全部meta-qcom机型,不分族);
   - 机型调优层:`qcom-common.inc`定义的`QCOM_RT_CPU`/`QCOM_IRQAFF`/`QCOM_RCU_NOCBS`/`QCOM_RCU_EXPEDITED`/`QCOM_CPUIDLE_OFF`五个变量拼装`isolcpus`/`irqaffinity`等cmdline参数,默认空字符串,只有具体机型conf显式赋值才生效,覆盖面窄于内核能力层。
   - "某机型未设置cmdline调优变量"不等于"该机型无法编译出`CONFIG_PREEMPT_RT=y`的内核"——这是判断"缺口"性质时必须分清的两个不同维度,不能笼统合并成一句"该机型不支持RT"。
4. **cmdline拼装机制具体核实**:`qcom-common.inc`第74-91行,五个变量→五个cmdline参数(`isolcpus`/`irqaffinity`/`rcu_nocbs`/`rcupdate.rcu_expedited`/`cpuidle.off`)的映射关系,及"Default values (machines override these)"注释确认的opt-in设计。
5. **精确到两/三个具体机型的对比链**(不做抽象产品覆盖度调查,是本方法论最核心的一步):
   - downstream(maili):**pebble** —— `MACHINE=pebble`(`poky/meta-qti-bsp/conf/machine/pebble.conf`)+内核目标`build.config.msm.pebble.le`(`MSM_ARCH=pebble_le`,`kernel_platform/temp_out_dir/super_kernel/build.config.msm.pebble.le`)——已从`build-qti-distro-camerastack-debug/conf/auto.conf`的`DISTRO ?= "qti-distro-camerastack-debug"`/`MACHINE ?= "pebble"`实测确认是真实构建组合;构建产物`kernel_platform/temp_out_dir/super_kernel/.config.old`第120行实测`# CONFIG_PREEMPT_RT is not set`(`kernel_platform/temp_out_dir/soc-repo/.config`同样命中),是比"仅grep源码定义文件"更深一层的构建产物级证据。
   - QLI2.0已启用:**iq-9075-evk** —— `meta-qcom/conf/machine/iq-9075-evk.conf`第41-46行直接赋值`QCOM_RT_CPU="7"`/`QCOM_IRQAFF="0-6"`/`QCOM_RCU_NOCBS="7"`/`QCOM_RCU_EXPEDITED="1"`/`QCOM_CPUIDLE_OFF="1"`(注释"Isolate rt cpu");本地实际构建走默认`linux-qcom`(非RT)provider,已从构建产物`build/tmp/work/iq_9075_evk-qcom-linux/linux-qcom/6.18.30/build/.config`实测`# CONFIG_PREEMPT_RT is not set`反向确认默认关闭;官方CI`meta-qcom-distro/.github/workflows/build-yocto.yml`第191-198行给该机型专属额外配置了`qcom-next-rt`验证job(其他机型没有这条额外entry),是官方CI矩阵里被特别对待的RT旗舰机型。
   - QLI2.0未获机型级调优:**iq-x5121-evk** —— `meta-qcom/conf/machine/iq-x5121-evk.conf`及其`require`链`qcom-purwa.inc`均未出现`QCOM_RT_CPU`等5个变量,继承`qcom-common.inc`空字符串默认值;但`meta-qcom/.github/workflows/build-yocto.yml`第221-338行的`compile`job machine矩阵包含`iq-x5121-evk`(第234行),kernel矩阵含`type: rt-6.18-distro-kvm`(第263-265行),`exclude`列表(第266-297行)未把它排除在这一RT kernel交叉编译组合之外——即内核能力层未被门槛排除,只是机型调优层缺失,不是"完全没有RT"。
6. **用官方CI矩阵交叉验证机型×kernel组合的真实性与特殊对待**:哪个机型在CI matrix里有专属额外entry(如`qcom-next-rt`),哪个机型即使未获cmdline调优也仍被纳入RT kernel交叉编译组合而未被exclude规则排除,这是判断"官方是否真的验证过这个组合"的关键证据,不能只看recipe/conf文件本身是否存在。
7. **确认RT不是通过DISTRO_FEATURES标志实现,而是通过kernel provider切换**:全树grep相关DISTRO_FEATURES未发现`rt`标志,默认kernel provider(`qcom-armv8a.conf`)仍为`linux-yocto`/`linux-qcom`(非RT),RT需显式切换provider。

每一步的产出最终收敛进"专属取证要点",再由取证要点收敛成正文的关键差异/影响与风险——取证要点是证据,正文是结论,不能反过来倒推。

### 3. 抽样声明

涉及大规模内容(补丁、commit、recipe)无法逐一核对时,必须:
- 明示抽样范围与方法(如"随机抽样`meta-qti-gst`全部144个补丁中的6个,按recipe分布统计")
- 明确抽样结论的局限,不得直接外推为总体结论而不加限定语(如用"存活率约9%"而非"补丁基本都丢了")

### 4. 纠错记录

当先前判断被新证据推翻时,禁止静默覆盖旧结论,必须:
- 在该主题文档内保留"初步判断 → 核实后结论"的对照(可用小节或表格形式,如Patch_Management.md的补丁总量纠正)
- 若纠正的结论足够重要(影响其他文档的判断或曾写入README汇总表),同步更新README.md《曾纠正过的结论》表

### 5. 风险分级

任何写入README《安全/合规风险清单》或《待拍板事项汇总》的发现,必须标注优先级:

| 等级 | 判定依据 |
|---|---|
| P0 | 影响范围广且不可逆(如安全校验机制整体消失、需要重建服务端基础设施) |
| P1 | 影响范围较大或需要专项决策,但有明确规避/替代路径 |
| P2 | 影响范围有限,属于工程执行层面的既定工作 |
| P3 | 边缘case或低优先级遗留问题 |

分级依据是"影响范围 × 不可逆性",不是主观感受;同一发现在不同产品线/团队视角下等级可能不同,应在文档中说明判定理由而非只写等级本身。

### 6. 交叉验证

当本地代码库证据不足以支撑结论(尤其是"上游行为是否符合规范""是否遵循最佳实践"类判断)时:
- 必须查找官方文档/release notes/迁移指南等权威来源(如对应的`reference/`子目录下的存档页面)交叉验证
- 明确标注验证状态:"已用XX来源核实"或"未能核实,标注为推测,待后续验证"
- 若本地环境网络受限无法直连官方站点,应将需要的页面存档到本主题的`reference/`子目录后再核实,而非跳过验证直接下结论

### 7. 范围交叉一致性

任何文档《对比范围》里的"明确排除",必须能在被指向的文档的"覆盖"字段里找到对应项;反之,任何"待定边界"项,不得同时被两篇文档都排除或都不提及。写完/改完一篇文档的《对比范围》后,必须检查它指向或被指向的文档是否需要同步更新。可用`scripts/check_scope_links.sh`辅助抓悬空引用(字符串级别粗检查,不能替代人工判断措辞是否准确)。

## System_Architecture 专属取证指引

系统级基础设施与硬件子系统对比。优先证据来源:
- 版本字符串:distro/layer的`.conf`文件(如`poky.conf`的`DISTRO_VERSION`)、`layer.conf`的`LAYERSERIES_COMPAT_core`
- 构建产物内版本信息:`bitbake`/内核源码内`git describe`、`__init__.py`等版本常量
- 子系统专有栈 vs 开源栈的判定:优先搜对应服务/驱动的顶层recipe与依赖(如Display看HWC/Composer vs DRM/KMS+Mesa,Audio看AudioReach源码树 vs meta-audioreach+PipeWire)
- 安全类结论(如SELinux策略)需要给出规则数量级对比(如"661文件"vs"约3个策略点"),不能只写"有/无"

## RT专属取证要点(按2.1节7步方法论组织)

- **1.物理载体**:downstream(maili)`poky/meta/recipes-kernel/linux/linux-yocto-rt_6.6.bb`——上游样板,未被任何bb/machine接线,`rt-tests`同样未接线;QLI2.0`meta-qcom/recipes-kernel/linux/linux-qcom-rt_6.18.bb`(`require linux-qcom_6.18.bb`)、`linux-qcom-next-rt_git.bb`(`require linux-qcom-next_git.bb`)——两个独立recipe真实存在且有require关系,已确认接线状态。
- **2.核心变量赋值点(含构建产物验证,本次新增)**:
  - downstream(maili):`arch/arm64/configs/{defconfig,gki_defconfig,*.fragment}`及各`build.config`全量grep`CONFIG_PREEMPT_RT`/`rt-tests`零命中,`poky/meta-qti-distro`全目录(含`qti-distro-camerastack-debug.conf`及其include链)同样零命中;**本次新增构建产物级证据**——pebble机型对应真实生成的`kernel_platform/temp_out_dir/super_kernel/.config.old`第120行`# CONFIG_PREEMPT_RT is not set`,`kernel_platform/temp_out_dir/soc-repo/.config`(remote`quic/qcom-6.18`)同一行同样命中;全仓库对`*.config`/`*.fragment`/`defconfig`/`gki_defconfig`跑`grep -rn "CONFIG_PREEMPT_RT"`,唯一命中就是这两处"is not set",无任何"=y"命中。
  - QLI2.0:`linux-qcom-rt_6.18.bb`里`KBUILD_CONFIG_EXTRA:append:aarch64`引用的`arch/arm64/configs/rt.config`,内容`CONFIG_EXPERT=y`/`CONFIG_PREEMPT_RT=y`(已在`build/tmp/work-shared/iq-9075-evk/kernel-source/arch/arm64/configs/rt.config`验证真实存在);**本次新增反向验证**——iq-9075-evk本地实际默认构建走`linux-qcom`(非RT)provider(`build/conf/local.conf`第39行`PREFERRED_PROVIDER_virtual/kernel = "linux-qcom"`),其构建产物`build/tmp/work/iq_9075_evk-qcom-linux/linux-qcom/6.18.30/build/.config`实测`# CONFIG_PREEMPT_RT is not set`,证明"默认provider下RT关闭"不是理论推测,是本地真实构建产物验证的事实。
- **3.内核能力层 vs 机型调优层(本次新增独立小节)**:`linux-qcom_6.18.bb`第9行`COMPATIBLE_MACHINE = "(qcom)"`覆盖全部meta-qcom机型,不分族(决定能否切provider拿到`CONFIG_PREEMPT_RT=y`);`meta-qcom/conf/machine/include/qcom-common.inc`第75-79行`QCOM_RT_CPU`/`QCOM_IRQAFF`/`QCOM_RCU_NOCBS`/`QCOM_RCU_EXPEDITED`/`QCOM_CPUIDLE_OFF`五变量默认空字符串,仅按机型显式opt-in(决定能否拿到isolcpus/irqaffinity等cmdline调优)——两层容易被混为一谈,已用CI矩阵证据(见第6条)证明"未获cmdline调优"不等于"内核能力层被机型门槛排除"。
- **4.cmdline拼装**:`meta-qcom/conf/machine/include/qcom-common.inc`第74行注释"Default values (machines override these)",第82-91行`RT_ARGS_ISOL/IRQ/NOCBS/EXP/IDLE`分别拼装`isolcpus=${QCOM_RT_CPU}`/`irqaffinity=${QCOM_IRQAFF}`/`rcu_nocbs=${QCOM_RCU_NOCBS}`/`rcupdate.rcu_expedited=${QCOM_RCU_EXPEDITED}`/`cpuidle.off=${QCOM_CPUIDLE_OFF}`。
- **5.两/三个具体机型的对比链(本次新增,已实测确认,是本主题最核心的证据)**:
  - **pebble(downstream(maili))**:`MACHINE=pebble`——`poky/meta-qti-bsp/conf/machine/pebble.conf`;内核目标`MSM_ARCH=pebble_le`(`kernel_platform/temp_out_dir/super_kernel/build.config.msm.pebble.le`,链到`soc-repo/build.config.common`+`build.config.aarch64`);已从`build-qti-distro-camerastack-debug/conf/auto.conf`(`DISTRO ?= "qti-distro-camerastack-debug"`/`MACHINE ?= "pebble"`)实测确认是真实构建组合,与Distro_Version主题使用的同一机型锚点;构建产物`.config.old`第120行`# CONFIG_PREEMPT_RT is not set`,非猜测。
  - **iq-9075-evk(QLI2.0,已启用)**:`meta-qcom/conf/machine/iq-9075-evk.conf`第41-46行——`# Isolate rt cpu`注释下直接赋值`QCOM_RT_CPU="7"`/`QCOM_IRQAFF="0-6"`/`QCOM_RCU_NOCBS="7"`/`QCOM_RCU_EXPEDITED="1"`/`QCOM_CPUIDLE_OFF="1"`;官方CI`meta-qcom-distro/.github/workflows/build-yocto.yml`第161-163行给它配了标准`rt-6.18`kernel交叉编译entry,第191-198行**额外**给它加了仅此机型独有的`qcom-next-rt`(`ci/linux-qcom-next-rt.yml`)验证job,是官方CI矩阵里被特别对待的RT旗舰验证机型。
  - **iq-x5121-evk(QLI2.0,未获机型级调优)**:`meta-qcom/conf/machine/iq-x5121-evk.conf`及其`require`链`meta-qcom/conf/machine/include/qcom-purwa.inc`均grep`QCOM_RT_CPU`/`QCOM_IRQAFF`/`QCOM_RCU_*`/`QCOM_CPUIDLE_OFF`零命中,继承空字符串默认值;但`meta-qcom/.github/workflows/build-yocto.yml`第221-338行`compile`job的machine矩阵包含该机型(第234行),kernel矩阵含`type: rt-6.18-distro-kvm`(第263-265行,`ci/linux-qcom-rt-6.18.yml`+`ci/qcom-distro-kvm.yml`),`exclude`列表(第266-297行)只排除了`glymur-crd`/`qcom-armv8a`/`rb3gen2-core-kit`在`default`kernel类型下的组合,**没有任何规则把`iq-x5121-evk`排除在这一RT kernel交叉编译组合之外**——即该机型内核能力层未被门槛排除,只是拿不到cmdline级CPU隔离/IRQ亲和性调优。
  - 已重新逐一核对`meta-qcom`全部19个machine conf(及`require`链):直接赋值`QCOM_RT_CPU`的machine conf恰为9个(`iq-615-evk`/`iq-8275-evk`/`iq-9075-evk`/`iq-x7181-evk`/`qcm6490-idp`/`qcs615-ride`/`qcs8300-ride-sx`/`qcs9100-ride-sx`/`rb3gen2-core-kit`);另有3个通过`require`继承已赋值机型的变体(`iq-9075-evk-open-fw`→require`iq-9075-evk.conf`,`qcs6490-rb3gen2-core-kit`/`rb3gen2-core-kit-open-fw`→require`rb3gen2-core-kit.conf`);未赋值机型为`iq-x5121-evk`(→`qcom-purwa.inc`)、`rb1-core-kit`/`qrb2210-rb1-core-kit`(→`qcom-qcm2290.inc`)及`glymur-crd`/`kaanapali-mtp`/`sm8750-mtp`/`qcom-armv7a`/`qcom-armv8a`(消费类评估板/基础架构conf,非IQ工控/机器人族)。
- **6.CI矩阵(本次补充具体行号锚点)**:`meta-qcom/ci/linux-qcom-rt-6.18.yml`(`local_conf_header`设`PREFERRED_PROVIDER_virtual/kernel = "linux-qcom-rt"`)、`linux-qcom-next-rt.yml`(`meta-qcom-robotics-sdk`/`meta-qcom-distro`下同名副本);`meta-qcom-distro/.github/workflows/build-yocto.yml`第161-163行(标准rt-6.18交叉编译)/191-198行(iq-9075-evk专属qcom-next-rt entry);`meta-qcom/.github/workflows/build-yocto.yml`第229-244行machine矩阵(含iq-x5121-evk)/256-265行kernel矩阵(含rt-6.18-distro-kvm)/266-297行exclude列表(未排除iq-x5121-evk)。
- **7.DISTRO_FEATURES/默认provider**:全树grep`rt`相关DISTRO_FEATURES未发现;`qcom-armv8a.conf`默认`PREFERRED_PROVIDER_virtual/kernel`仍为`linux-yocto`(非RT);`qcom-minimal-image.bb`RT provider下自动装`rt-tests`。
- **已验证的检索方式**
  - 全目录grep`CONFIG_PREEMPT_RT`/`rt-tests`,遍历`arch/arm64/configs`全部defconfig/fragment/build.config及`poky/meta-qti-distro`全include链,确认零命中;本次已重新跑一遍确认结论不变,并补充了构建产物`.config`级证据(见第2条)
  - 对`kernel_platform/soc-repo`与`common`两仓库跑`git log --all -p`,对`arch/arm64/configs/*`路径做`CONFIG_PREEMPT_RT=y`全文匹配(分别135万+/141万+条commit可达),确认全部历史版本均零命中
  - 逐一核对`meta-qcom`全部19个machine conf(及`require`链)是否设置`QCOM_RT_CPU`,统计已赋值机型清单(直接赋值9个+继承3个,均为IQ工控评估板/机器人核心套件族)
- **已知易错点/纠错记录**:(暂无需走Methodology规则4纠错流程的错误;但需注意一个易被混淆的精确化点——"某机型未设置`QCOM_RT_CPU`等cmdline调优变量"不能等同于"该机型无法启用`CONFIG_PREEMPT_RT`"。`linux-qcom-rt_6.18.bb`的`COMPATIBLE_MACHINE = "(qcom)"`门槛覆盖全部meta-qcom机型,不区分机型族;已实测确认`meta-qcom/.github/workflows/build-yocto.yml`的官方CI矩阵里`iq-x5121-evk`同样被排入`rt-6.18-distro-kvm`kernel交叉编译组合、未被任何exclude规则排除。判断"哪些机型有RT缺口"时,必须区分"内核能力层"(recipe/provider门槛,覆盖全部机型)与"机型调优层"(cmdline变量赋值,按机型族opt-in)两个维度,不能笼统合并成一句"该机型不支持RT"。)

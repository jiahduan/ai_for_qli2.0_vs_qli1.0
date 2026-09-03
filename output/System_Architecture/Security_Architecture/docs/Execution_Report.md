# Security_Architecture 规则执行逻辑细节报告

本文档记录`Security_Architecture.md`当前内容是怎么从源码证据一步步推导出来的——按`rules/System_Architecture/Security_Architecture.md`"Security_Architecture专属取证要点"逐条复盘,每一条"做了什么→得到什么证据→落到最终结论的哪一行"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Security_Architecture.md`。

## 1. SELinux覆盖范围判断——纠错记录(本文档取证重点)

**初步判断**:按`.te`/`.fc`/`.if`扩展名对QLI2.0全量检索,仅命中6个mariadb自带的通用可选策略文件,与Qualcomm定制无关,据此判断"QLI2.0侧SELinux策略完全空白"。

**核实过程**:改用`git log`排查`meta-qcom/dynamic-layers/selinux`目录的提交历史,逐条读commit message定位真实策略点,而不是依赖文件扩展名搜索。

**核实后结论**:确认QLI2.0的Qualcomm定制策略并不以独立`.te/.fc/.if`文件形式存在,而是以patch形式内嵌进`meta-qcom/dynamic-layers/selinux/`下的refpolicy-targeted源码树——这正是按扩展名搜索必然漏判的根本原因。确认存在3个真实策略点:相机测试工具域`qcom_nhx`(246行)、TrustZone/QTEE的`tee_supplicant_qtee`、曾有的pd-mapper backport(已因上游可用而清理)。对应QLI1.0覆盖范围(661个`.te/.fc/.if`文件)差距在两个数量级以上,但绝非"零"。

**落到结论**:文档开头"纠错记录:SELinux覆盖范围判断纠正"表格,已同步更新README.md《曾纠正过的结论》表(SELinux行:"QLI2.0完全空白"→"有真实但规模远小的雏形")。下方各节(Git提交历史、关键差异、影响与风险)均基于核实后结论展开,这条纠错的教学意义在于:检索方法本身(按扩展名 vs 按提交历史)决定了能否发现以非常规形式存在的定制内容,方法论盲区比证据本身更容易被忽视。

## 2. Qualcomm定制策略Git提交历史与落后主线情况核实

**做法**:对`meta-qcom/dynamic-layers/selinux`跑`git log`梳理完整提交时间线;跑`git log HEAD..origin/wrynose -- dynamic-layers/selinux`核实本地checkout落后主线的commit数及其中SELinux相关路径差异。
**证据**:本地checkout(HEAD=`ef0004df`)确认落后于`origin/wrynose`(整体落后317个commit,但SELinux相关路径只有3条,均已体现在提交历史表);两条revert/drop提交原文说明证明团队按标准流程推上游后清理本地patch。
**落到结论**:"Qualcomm定制策略Git提交历史"表格,"关键差异"节"QLI2.0团队有清晰的推动修复上游合并、上游可用后清理本地patch的工程实践"判断。

## 3. 替代隔离机制排查

**做法**:grep`apparmor`/`firejail`/`seccomp`/IMA相关recipe,核实是否被任何qcom镜像IMAGE_INSTALL引用。
**证据**:AppArmor/Firejail存在于`meta-security`层recipe但未被引用,属"层里有、没人用"的死代码;seccomp 110个文件命中均为qemu/docker/systemd等标准软件包自带固有属性,非Qualcomm团队主动安全设计;IMA为上游原样内容,无Qualcomm定制迹象。
**落到结论**:"替代隔离机制排查结果"表格,"无证据表明安全团队选择了这些机制替代SELinux MAC"的结论。这是与第1条纠错记录不同性质的独立排查动作——第1条是"先误判为空、后发现有真实雏形",本条从头到尾都是"排查后确认没有替代机制",不构成纠错。

## 4. 量产环境实际生效的refpolicy provider变体核实

**做法**:把`poky/meta-qti-distro/conf/distro/`下全部30个变体的provider声明逐一核实(含被`require`的.inc链);进一步核实`release/crm/PACK.TXT`与`release/syncbuild.sh`两份release侧文件指向的产线。
**证据**:camerastack/fullstack/rb三条产线统一硬编码`refpolicy-mls-robotics`,xr走条件生成的`refpolicy-mls-xr`,base-debug/perf是`refpolicy-mls-generic`,其余变体落到meta-selinux默认provider;两份release侧文件均指向`refpolicy-mls-robotics`家族。
**落到结论**:"关键差异"节provider声明逐一核实的判断,以及"待确认"节明确说明"这仍是代码声明,不等于各SKU量产时实际选用的变体清单"这一证据边界。

## 5. 合规声明机制对照

**做法**:对`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`全目录grep`cd.xml`/`compliance`关键字;交叉核实`SPDX_INCLUDE_KERNEL_CONFIG ?= "1"`及实际构建产物`build/tmp/deploy/spdx/3.0.1/`。
**证据**:`cd.xml`/`compliance`0命中;但确认存在真实生效的替代物——oe-core标准`create-spdx-image-3.0.bbclass`已开启且在实际构建产物里能看到真实生成的`.spdx.json`文件。
**落到结论**:"影响与风险"节"合规声明流程在QLI2.0没有代码侧承接……但已确认存在一个真实生效、非custom的替代物"的判断,是"零命中不代表真的空白,需要进一步确认是否有等效替代机制"这一方法论在合规领域的具体应用。

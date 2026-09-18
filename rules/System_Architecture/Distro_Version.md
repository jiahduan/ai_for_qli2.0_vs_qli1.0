# Distro_Version —— 规则

> 本文件对应产出文档 [output/System_Architecture/Distro_Version/Distro_Version.md](../../output/System_Architecture/Distro_Version/Distro_Version.md)——产出文档本身已搬进`Distro_Version/`子目录存放(仅这一处例外,背景见[Scope_Section_Design.md](../../Scope_Section_Design.md)),但本规则文件仍留在`rules/`默认位置,与全部33份主题规则文件按本次目录重构选择的方式各自完整独立(7条强制规则全文一致,不做共享继承,变更时需同步维护)。全局工作流/与README关系见根目录[Methodology.md](../../Methodology.md)。

## 强制规则

以下规则对所有主题文档硬性生效,不因主题不同而放宽。

### 1. 证据引用标准

任何结论性陈述必须能追溯到以下至少一种证据:
- 具体文件路径(尽量带行号),如`meta-qcom/classes-recipe/image_types_qcom.bbclass`第127-136行
- 检索命令及其实际输出,如`grep -rln "abctl|libabctl" meta-qcom meta-qcom-distro meta-updater`零匹配
- git commit hash / `git log`/`git describe`输出
- 官方文档原文引用(需注明来源与核实方式,见规则6)

**禁止**仅凭目录名或关键字搜索为空就断言"某功能已消失"——必须展示实际检索命令及零命中证据,并在可能时交叉检索多个关键字变体(如同时检索`abctl`与`libabctl`)。

### 2. 统一文档结构(Distro_Version专属例外——见下方"Distro_Version输出格式")

Distro_Version.md不follow全仓库其余32篇的默认结构(对比范围/对比总览/关键差异/影响与风险),改用下方定义的`Comparison`极简格式,是本主题唯一的、经用户明确确认的例外。规则1/3/4/5/6/7(证据标准/抽样声明/纠错记录/风险分级/交叉验证/范围交叉一致性)照常生效——只是不追求"对比范围"这个字段级容器,证据仍要经得起追溯,只是不在正文里逐条铺陈。

**Distro_Version输出格式**:

```markdown
# System Architecture — Distro Version

## Comparison
downstream(maili)(8950-pebble) vs QLI2.0(iq-9075-evk)

| 维度 | downstream(maili) | QLI2.0 |
|---|---|---|
| <维度1> | <值,带关键锚点> | <值,带关键锚点> |
...

优势：
• <bullet,QLI2.0相对downstream(maili)在本主题下的具体优势,每条一句话>
...

影响：
• <bullet,该差异对下游团队/迁移工作的具体影响,每条一句话>
...
```

- 表格是"重要对比"的定量/事实呈现,每行一个维度,双侧值要带关键锚点(文件名/变量名),不要只写结论性形容词
- 优势/影响两个bullet列表是表格之上的解读总结,不逐行复述表格——回答"这些差异放在一起意味着什么",不是"表格第N行说了什么"(呼应其余32篇"关键差异不是对总览表的复述"的同一原则)
- 表格行数不强制,但建议覆盖2.1节8步方法论里能落到具体维度的部分(物理载体/核心变量/变体组织/构建变量/安全开关/OTA绑定/机型override/成熟度),没有实质对比内容的步骤可以不单独成行
- 表格/优势/影响里出现的每一个具体值(锚点/数字/判断)都必须能倒推回具体证据,但**不在文档正文里展开完整证据链**——证据留在`rules/System_Architecture/Distro_Version.md`的"专属取证要点"里,正文只呈现结论
- 不写"对比范围/对比总览/关键差异/影响与风险"这几个标准标题,不出现《对比范围》三字段
- 其余32篇主题文档不受此例外影响,仍严格执行标准的0-4号章节结构(见Methodology.md关于`rules/`目录一一对应关系的说明)

### 2.1 Distro_Version源码级分析方法论(8步,替代其余主题默认的"分类专属取证指引"取证起点)

以架构师视角做source-level分析,不是从抽象产品维度出发,按下面顺序找证据:

1. **定位物理载体**:distro层身份由哪个顶层layer/conf承载——downstream(maili)是`meta-qti-distro`,QLI2.0是`meta-qcom-distro`;确认该层在`bblayers.conf`里如何被引用。
2. **看Yocto规范核心变量的赋值点**:`DISTRO`/`DISTRO_VERSION`/`DISTRO_CODENAME`/`DISTRO_FEATURES`(新旧两套机制:`_BACKFILL`/`_BACKFILL_CONSIDERED`/`_DEFAULT`老写法 vs `_DEFAULTS`/`_OPTED_OUT`新写法),要落到具体`.conf`文件的赋值行,不能只讲概念。
3. **看变体矩阵的物理组织方式**:downstream(maili)是一批静态`.conf`文件(数量、命名规则、`require`/`include`链),QLI2.0是精简conf+kas yaml拼装,要具体数文件、追链路。
4. **看发行版级构建变量是否被覆盖/锁定**:`PACKAGE_CLASSES`/`TCLIBC`/`GCCVERSION`等,具体哪一行`.conf`覆盖了默认值。
5. **看安全/能力开关在distro层的绑定方式**:SELinux、TPM、加密等能力是硬编码在base.inc,还是拆成独立overlay conf按需`require`,看`inherit`链和`DISTRO_FEATURES`具体赋值语句。
6. **看OTA/更新机制与distro conf的绑定点**:哪个conf`inherit`了哪个更新相关bbclass,这是升级方案选型在源码里的落地证据。
7. **精确到两个具体机型的distro conf链**(不做抽象产品线覆盖度调查):
   - downstream(maili):**8950-pebble** —— `MACHINE=pebble`(`poky/meta-qti-bsp/conf/machine/pebble.conf`)+ `DISTRO=qti-distro-camerastack-debug`(`poky/meta-qti-distro/conf/distro/qti-distro-camerastack-debug.conf`,`require conf/distro/include/qti-distro-fullstack.inc`)——已从`build-qti-distro-camerastack-debug/conf/auto.conf`的`DISTRO ?= "qti-distro-camerastack-debug"`/`MACHINE ?= "pebble"`实测确认,非猜测。
   - QLI2.0:**iq-9075-evk** —— `MACHINE=iq-9075-evk`(`meta-qcom/conf/machine/iq-9075-evk.conf`)+ `DISTRO=qcom-distro`(`meta-qcom/ci/qcom-distro.yml`)——已从`meta-qcom-distro/.github/workflows/build-yocto.yml`真实CI矩阵条目`{machine: iq-9075-evk, distro: {name: qcom-distro, yamlfile: ':ci/qcom-distro.yml'}}`实测确认这是官方CI真实构建的组合,非随意选择。
   - 逐项核对这两个具体机型各自实际生效的DISTRO_FEATURES、PACKAGE_CLASSES、SELinux开关、OTA方案是否一致,有无机型级override覆盖distro层默认值。
8. **用git历史佐证成熟度**:新distro层的commit时间跨度/提交频次,判断是刚起步的草案还是已验证、被其他产品线复用的稳定范式。

每一步的产出最终收敛进"专属取证要点",再由取证要点收敛成正文的优势/影响bullet——bullet是结论,取证要点是证据,不能反过来倒推。

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

## Distro_Version专属取证要点(按2.1节8步方法论组织)

- **1.物理载体**:downstream(maili)`poky/meta-qti-distro`;QLI2.0`meta-qcom-distro`(均已在各自`bblayers.conf`确认被引用)
- **2.核心变量赋值点**:`qti-distro-base.inc`(DISTRO_FEATURES专有追加:`eabi ipv6 ipv4 largefile thumb-interwork xattr selinux emmc-boot qti-wifi qti-ab-boot`) vs `qcom-base.inc`(`DISTRO_FEATURES:append`:`efi glvnd kvm minidebuginfo opencl overlayfs pam pni-names polkit security tpm2 virtualization wifi x11`);两侧字段列表已逐项diff,确认专有追加项完全不重叠
- **3.变体矩阵组织方式**:downstream(maili)`meta-qti-distro`(30个`qti-distro-{base,fullstack,camerastack,xr,vnm,rb,host}-*.conf`变体);QLI2.0`meta-qcom-distro`(`qcom-distro.conf`/`qcom-distro-selinux.conf`/`qcom-distro-sota.conf`/`qcom-distro-catchall.conf`4个)+`meta-qcom-robotics-sdk`(`qcom-robotics-distro-{catchall,selinux,sota}.conf`)+`meta-qcom-distro/ci/`(35个kas yml,如`debug.yml`/`performance.yml`);已遍历`meta-qcom-distro/ci/`全部35个yml及`meta-qcom/ci/`,检索`camerastack`/`xr`/`vnm`/`host`对应kas片段,确认零命中——即8950-pebble所在的camerastack产品线在QLI2.0侧目前没有对应distro conf,不是漏找,是真实排查结论
- **4.发行版级构建变量**:`qti-distro-base.inc`未覆盖PACKAGE_CLASSES(默认继承`poky.conf`的`package_rpm`) vs `qcom-distro.conf`显式声明`PACKAGE_CLASSES="package_rpm"`;GCCVERSION锁定方式:`qti-distro-base.inc`二次锁定`GCCVERSION="13.4%"` vs QLI2.0未二次锁定、继承`tcmode-default.inc`的`15.%`(TCLIBC两侧均未覆盖,默认glibc,picolibc新增选项细节归Toolchain.md)
- **5.安全/能力开关**:`qti-distro-camerastack-debug.conf`里`PREFERRED_PROVIDER_virtual/refpolicy="refpolicy-mls-robotics"`(downstream(maili)侧硬编码在具体distro conf);QLI2.0`qcom-distro-selinux.conf`独立overlay,`DEFAULT_ENFORCING ?= "enforcing"`,是否生效取决于该机型build是否`require`此conf——已核实QLI2.0当前实际构建`qcom-robotics-ros2-jazzy`未`require` `qcom-distro-selinux.conf`,即默认不启用SELinux,这是"按需选配"在真实构建里的具体落地结果,不是理论推测
- **6.OTA绑定点**:downstream(maili)`qti-ab-boot`;QLI2.0`qcom-distro-sota.conf`(OSTree+aktualizr)
- **7.两个具体机型的distro conf链(本次新增,已实测确认,是本主题最核心的证据)**:
  - **8950-pebble(downstream(maili))**:`MACHINE=pebble`——`poky/meta-qti-bsp/conf/machine/pebble.conf`(`BASEMACHINE="pebble"`,`MSM_KERNEL_VERSION="6.18"`);`DISTRO=qti-distro-camerastack-debug`——`poky/meta-qti-distro/conf/distro/qti-distro-camerastack-debug.conf`,`require conf/distro/include/qti-distro-fullstack.inc`,`DISTROOVERRIDES=."qti-distro-debug:qti-distro-camera:"`;两值均从`build-qti-distro-camerastack-debug/conf/auto.conf`(`DISTRO ?= "qti-distro-camerastack-debug"`/`MACHINE ?= "pebble"`)实测读出,非猜测
  - **iq-9075-evk(QLI2.0)**:`MACHINE=iq-9075-evk`——`meta-qcom/conf/machine/iq-9075-evk.conf`;`DISTRO=qcom-distro`——`meta-qcom/ci/qcom-distro.yml`(`distro: qcom-distro`,引入`meta-qcom-distro`/`meta-openembedded`/`meta-virtualization`/`meta-audioreach`/`meta-selinux`等repo);组合来自`meta-qcom-distro/.github/workflows/build-yocto.yml`真实CI矩阵条目`{machine: iq-9075-evk, distro: {name: qcom-distro, yamlfile: ':ci/qcom-distro.yml'}}`,是官方CI实际构建的组合,非随意选取
  - 两个机型均未见machine级override覆盖distro层的PACKAGE_CLASSES/SELinux/OTA默认值(已grep两侧machine conf确认无重复赋值)
- **8.成熟度佐证**:`meta-qcom-distro`git创建(2023-07-18)/首次实质提交(2024-01-25)至今582个commit;"base+selinux开关+sota开关+catchall"4-conf模式已在`meta-qcom-robotics-sdk`层原样复制一遍,是刻意设计的可复制范式
- **已知易错点/纠错记录**:(暂无纠错记录;需注意`meta-qcom`/`meta-qcom-robotics-sdk`两层CI的`ci/base.yml`本身声明`distro: nodistro`,真正的`qcom-distro`/`qcom-robotics-distro`是通过与产品级yml组合kas文件才生效,不要误读base.yml就以为默认DISTRO是nodistro)

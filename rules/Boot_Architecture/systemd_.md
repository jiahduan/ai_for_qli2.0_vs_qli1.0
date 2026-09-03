# systemd_ —— 规则

> 本文件对应产出文档 [output/Boot_Architecture/systemd_/systemd_.md](../../output/Boot_Architecture/systemd_/systemd_.md),与全部33份主题规则文件按本次目录重构选择的方式各自完整独立(7条强制规则全文一致,不做共享继承,变更时需同步维护;背景见[Scope_Section_Design.md](../../Scope_Section_Design.md))。全局工作流/与README关系见根目录[Methodology.md](../../Methodology.md)。

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
1. `## 对比总览` — 一张`维度 | QLI1.0 | QLI2.0`表格,是文档骨架,让读者10秒内看到全貌
2. (可选)主题专属深挖章节 — 追踪表、抽样统计、专项验证等
3. `## 关键差异` — 综合性洞察,**不是对总览表的复述**,要回答"这些差异放在一起意味着什么"
4. `## 影响与风险` — 对下游团队/决策的具体影响,不做纯技术总结

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

## Boot_Architecture 专属取证指引

启动链各阶段对比。优先证据来源:
- 按启动阶段拆解成表格(PBL→XBL/SBL→TZ/HYP→主Bootloader→内核→用户态),逐阶段找组件对应
- Bootloader/内核镜像格式的判定依据具体recipe(如`abl-squashfs.bb`/`u-boot-qcom_git.bb`)及其`inherit`/`UBOOT_CONFIG`等关键变量,**注意区分默认配置与可选配置**(如同一机型`.conf`可能因firmware变体而走不同路径,需明确写清"仅在XX配置下成立")
- cmdline/分区依据类结论需要说明生成时机(构建期静态 vs 运行时动态),这直接影响可审计性判断

## systemd专属取证要点

- **关键双侧目录/文件锚点**
  - QLI1.0:`systemd_255.21.bb`(源`git://github.com/systemd/systemd-stable.git` branch `v255-stable`,`SRCREV`70500d37`即tag`v255.21`)、`Disable-unused-mount-points.patch`(改`src/shared/mount-setup.c`,注释掉securityfs挂载)、`fstab-generator-Honor-verity-enabled-cmdline.patch`(改`src/fstab-generator/fstab-generator.c`)、`sd-bus-Allow-extra-users-to-communicate.patch`(改`src/libsystemd/sd-bus/bus-convenience.c`的`sd_bus_query_sender_privilege()`,硬编码放行uid 1000/1001)
  - QLI2.0:`systemd_259.5.bb`(源`git://github.com/systemd/systemd.git`主线仓库tag`v259.5`)、`0001-boot-stub-honor-PE-SectionAlignment...patch`(与`FIT_DTB_MKIMAGE_EXTRA_OPTS ?= "-E -B 8"`呼应)、`format-tee-partition.service`(meta-qcom*唯一unit)、meta-updater层6个unit(`aktualizr.service`、`aktualizr-secondary.service`、`aktualizr-serialcan.service`、`slcand@.service`、`createtoken.service`、`clean-connman-symlink.service`)、`meta-qcom/conf/machine/iq-9075-evk.conf`(`MACHINE_FEATURES`含`tpm2`)、`build/conf/bblayers.conf`(确认`meta-integrity`未被收录)
- **已验证的检索方式**
  - 全局检索`securityfs`,范围限定实际参与构建的层(`meta-security`本体、`meta-security/meta-tpm`、`meta-qcom*`、`oe-core/meta`)——零命中;另有命中的`meta-integrity`需额外核对`build/conf/bblayers.conf`是否收录(未收录)才能定论
  - 全局检索`verity=enabled`、`arg_usr_verity`——零匹配,用于判定dm-verity cmdline支持补丁是否被吸收
  - 全局检索`sender_uid == 1001`——零匹配,用于判定sd-bus特权uid补丁是否被吸收
  - 对两侧SRCREV对应的确切NEWS文件(systemd-stable `v255.21` vs systemd主线 `v259.5`)做逐行diff,统计新增行数(~4117行),再逐条筛与本BSP启动路径直接相关的变化(而非泛泛引用release notes)
  - 检索`meta-qcom*`范围内`journald.conf`级`Storage=`覆盖,判断v259默认`persistent`存储模式是否被显式改回
- **已知易错点/纠错记录**
  - 本文档自身没有"初步判断→核实后结论"式的纠错记录,README《曾纠正过的结论》表也未收录systemd_专属条目
  - 但本文档"dm-verity相关补丁消失"结论与Bootargs.md(cmdline无verity参数)、Partition_Layout.md(Android安全分区消失)构成同一条三方证据链,而Bootargs.md/Boot_Flow.md所属的"UKI签名"结论曾被README纠正(初步误判为"已签名",核实后为"未签名")——复核本文档时应同步关注该纠错是否影响这条证据链的措辞

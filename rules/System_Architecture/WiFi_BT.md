# WiFi_BT —— 规则

> 本文件对应产出文档 [output/System_Architecture/WiFi_BT.md](../../output/System_Architecture/WiFi_BT.md),与全部33份主题规则文件按本次目录重构选择的方式各自完整独立(7条强制规则全文一致,不做共享继承,变更时需同步维护;背景见[Scope_Section_Design.md](../../Scope_Section_Design.md))。全局工作流/与README关系见根目录[Methodology.md](../../Methodology.md)。

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

## System_Architecture 专属取证指引

系统级基础设施与硬件子系统对比。优先证据来源:
- 版本字符串:distro/layer的`.conf`文件(如`poky.conf`的`DISTRO_VERSION`)、`layer.conf`的`LAYERSERIES_COMPAT_core`
- 构建产物内版本信息:`bitbake`/内核源码内`git describe`、`__init__.py`等版本常量
- 子系统专有栈 vs 开源栈的判定:优先搜对应服务/驱动的顶层recipe与依赖(如Display看HWC/Composer vs DRM/KMS+Mesa,Audio看AudioReach源码树 vs meta-audioreach+PipeWire)
- 安全类结论(如SELinux策略)需要给出规则数量级对比(如"661文件"vs"约3个策略点"),不能只写"有/无"

## WiFi_BT专属取证要点

- **关键双侧目录/文件锚点**
  - QLI1.0:`meta-qti-wlan`(`qcacld32-ll-vienna-le.bb`/`qcacld-hl_git.bb`/`qcacld30-ll_git.bb`/`wcnss_git.bb`)、`meta-qti-wlan-prop`(`cnss-daemon_git.bb`/`qcacld-utils_git.bb`/`hal-proxy-daemon_git.bb`/`qsaharaservice.bb`/`ftm_git.bb`/`wlan-services_git.bb`/`wlan-prima_git.bb`)、`meta-qti-bt`(`fluoride_4.1.bb`/`btvendorhal_4.1.bb`/`hidl-client_4.1.bb`)、`meta-qti-bt-prop`(`hci-qcomm-init_4.1.bb`/`bttransport_4.1.bb`/`xpan_4.1.bb`)、`packagegroup-qti-wifi.bb`、`db845c_gki.fragment`
  - QLI2.0:`ath10k`/`ath11k`/`ath12k`(随`linux-qcom`内核编译)、`linux-firmware_20260410.bb`/`linux-firmware_20260519.bb`、`sigma-dut_git.bb`(`github.com/qualcomm/sigma-dut`)、`meta-qcom-distro/recipes-connectivity/bluez5/bluez5_%.bbappend`、`meta-qcom/recipes-bsp/firmware/firmware-ath6kl_git.bb`、`packagegroup-machine-essential.bb`、`meta-qcom/recipes-test/diag-router_1.0.2.bb`+`libdiag_1.0.5.bb`、`board-2.bin`(ath11k/WCN6750多variant容器)、`qrb2210-rb1.dts`(`Thundercomm_RB1`)/`qcs6490-rb3gen2.dts`(`Qualcomm_rb3gen2`)/`talos-evk-som.dtsi`(`QC_QCS615_Ride`)
- **已验证的检索方式**
  - `MACHINE=qcom-armv8a bitbake-getvar MACHINE_ESSENTIAL_EXTRA_RRECOMMENDS`实测变量解析结果,核对与`packagegroup-rb1/rb2/rb3gen2/rb5-firmware`等静态声明是否一致
  - 对`kernel_platform/common`仓库(remote`quic`)跑`git log --all`核实`db845c_gki.fragment`历史提交作者(全部是`@google.com`/`@linaro.org`)
  - 解包`linux-firmware_20260519.tar.xz`,读取`board-2.bin`内`bus=ahb,qmi-chip-id=N,qmi-board-id=M[,variant=NAME]`分段结构;对`ath11k`/`ath12k`全部136个固件文件名做`utf`/`test`/`ftm`关键词检索,确认零命中
  - grep`qcom,calibration-variant`属性跨多机型dts,确认已声明variant清单(Thundercomm_RB1/Qualcomm_rb3gen2/QC_QCS615_Ride/QC_SA8775P_Ride)
  - WebFetch核实`github.com/qca/ath6kl-firmware/commits/master.atom`确认上游最后提交日期(2014-06-17)
- **已知易错点/纠错记录**:有(文档内部,未写入README)——文档专设"关于'QLI1.0=全专有驱动'的核实"一节,核实发现QLI1.0内核树客观携带完整可编译的`ath10k`/`ath11k`/`ath12k`源码及`db845c_gki.fragment`(仅被Google/Linaro touch,未被Qualcomm产品链路挂接)。修正结论:"QLI1.0所有已知量产机型的packagegroup均强制选择QCACLD"(镜像级/产品级结论)成立,但"QLI1.0代码库完全没有ath代码"(代码库级结论)不成立,是过度简化。

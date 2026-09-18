# Display —— 规则

> 本文件对应产出文档 [output/System_Architecture/Display/Display.md](../../output/System_Architecture/Display/Display.md),与全部33份主题规则文件按本次目录重构选择的方式各自完整独立(7条强制规则全文一致,不做共享继承,变更时需同步维护;背景见[Scope_Section_Design.md](../../Scope_Section_Design.md))。全局工作流/与README关系见根目录[Methodology.md](../../Methodology.md)。

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

## Display专属取证要点

- **关键双侧目录/文件锚点**
  - downstream(maili):`meta-qti-display`(`display-hal-linux_git.bb`/`sdm-comp-linux_git.bb`/`mmdlkm_git.bb`/`displaydlkm_git.bb`)、`meta-qti-display-prop`(`display-noship-linux_git.bb`/`display-ship`/`display-fw`)、`gbm_21.1.1.bb`、`weston_13.0.1.bbappend`、`src/display/{hardware,vendor}`
  - QLI2.0:`mesa.bbappend`(启用freedreno+A704支持补丁)、`msm-gbm-backend`(`git://github.com/qualcomm-linux/gbm-msm-backend.git`)、`wayland/weston_15.0.0.bbappend`、`qcom-adreno_1.855.5.bb`、glvnd产物`10_adreno.json`/`50_mesa.json`(`build/tmp/sysroots-components/armv8-2a/mesa/usr/share/glvnd/egl_vendor.d/`)、libglvnd源码(`build/downloads/git2_gitlab.freedesktop.org.glvnd.libglvnd.git.tar.gz`的`src/EGL/libeglvendor.c`/`libegl.c`)、多输出dts:`lemans-evk.dts`(`mdss0_dp0`/`mdss0_dp1`)、`hamoa.dtsi`(`mdss_dp0`~`mdss_dp3`)
- **已验证的检索方式**
  - 全库检索`sdm|displayengine|libdisplayconfig|display-hal|display composer`关键词,零命中,据此判定SDM Composer/HWC合成服务层整体消失
  - 读取`mesa.bb`默认`PACKAGECONFIG`是否经`DISTRO_FEATURES`纳入`glvnd`+`meta-qcom/recipes-graphics/mesa/mesa.bbappend`是否追加`freedreno`
  - 读取`libeglvendor.c`的`LoadVendorsFromConfigDir()`(按文件名字典序scandir加载全部`*.json`)与`libegl.c`的`GetPlatformDisplayCommon()`(按vendor list顺序调用、首个成功者绑定)源码逻辑,确认多vendor共存/绑定机制
  - 对多机型kernel dts做`mdss`节点及多路DP/eDP声明扫描,核实是否为真实多输出硬件配置
- **已知易错点/纠错记录**:非严格的"初步判断→核实后结论"两栏记录,但文中有一处假设被核实推翻——最初可能被当作"单一输出场景故不需要"关注并发多显示拓扑,经对iq-9075-evk(lemans-evk,双路eDP)、hamoa-iot-evk(四路DP)、sm8550-hdk(HDMI+DP)等dts核实,该假设不成立,这些板级是真实多输出硬件配置。

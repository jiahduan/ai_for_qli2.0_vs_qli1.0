# Patch_Management —— 规则

> 本文件对应产出文档 [output/Code_Composition/Patch_Management.md](../../output/Code_Composition/Patch_Management.md),与全部33份主题规则文件按本次目录重构选择的方式各自完整独立(7条强制规则全文一致,不做共享继承,变更时需同步维护;背景见[Scope_Section_Design.md](../../Scope_Section_Design.md))。全局工作流/与README关系见根目录[Methodology.md](../../Methodology.md)。

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

## Code_Composition 专属取证指引

代码组织与协作机制对比。优先证据来源:
- 代码同步:repo manifest / kas yaml等声明式配置文件
- 补丁统计:先确认统计口径(是否含第三方noise文件、工作目录残留),`find`/`grep`前先排除已知噪声源,避免规则1提到的"目录名/关键字搜索"类误判在此处以"总数虚高"的形式出现
- 分支管理:命名规则、跨仓补丁机制(如kas的`patches:`字段与消费方patches目录关系)
- 补丁抽样需按层/按recipe分别统计密度(如患病率≈存活补丁数/原补丁数),不能只看单个recipe就外推整层结论(参见规则3)

## Patch_Management专属取证要点

- **关键双侧目录/文件锚点**:
  - QLI1.0补丁统计口径:`poky/`4,858个;`src/`5,083个(其中噪声`external/bazelbuild-bazel-central-registry` 4,890、`external/rust` 156、`external/zlib` 19、`external/bazelbuild-rules_rust` 5、`external/bazelbuild-rules_python` 4、`u-boot/tools`patman自测fixture 3、`external/elfutils`/`bazel-skylib`/`rules_cc`各1;真实补丁仅`vendor/qcom/proprietary/video/noship/v4l-utils`3个);`disregard/`废弃备份38个(`meta-qti-agm`/`meta-qti-audio`/`meta-qti-arpal`/`meta-qti-qmmf`);`build-qti-*`构建残留554个(`tmp-glibc/sysroots-components`,如perl-cross-native);真实内核补丁6个在`poky/meta-qti-bsp*/recipes-kernel/`
  - QLI2.0补丁统计口径(按层):`meta-openembedded/` 2,416;`meta-ros/` 1,044;`oe-core/` 1,116;`meta-virtualization/` 121;`meta-security/` 90;`meta-selinux/` 77;`meta-qcom/` 61;`meta-qcom-robotics-sdk/` 43;`meta-qcom-distro/` 18;`meta-updater/` 8;`meta-audioreach/` 1
  - 跨仓补丁机制样例:`meta-qcom/patches/meta-oe/0001-mariadb-fix-building-for-the-ARMv8.3-A-and-later-sys.patch`;补丁治理脚本`meta-qcom-robotics-sdk/ci/yocto-patchreview.sh`
  - Systemd补丁去向追踪三例:`Disable-unused-mount-points.patch`、`fstab-generator-Honor-verity-enabled-cmdline.patch`、`sd-bus-Allow-extra-users-to-communicate.patch`
  - gstreamer抽样:`meta-qti-gst`(144个,按recipe`gstreamer1.0-plugins-good` 60、`plugins-bad` 29、`plugins-base` 26、`gstreamer1.0-omx` 11、`qti-patches` 8、`gstreamer1.0-libav` 3、核心4、`gstd` 2、`gstreamer-vaapi` 1);QLI2.0对应`meta-qcom/recipes-multimedia/gstreamer/gstreamer1.0-plugins-base_%.bbappend`及3个bbappend共13个补丁
  - 内核commit标签体系:`FROMLIST:`、`BACKPORT:`、`QCLINUX:`、`PENDING:`、`WORKAROUND:`(抽样约3000条统计出488/102/41/32/11)
- **已验证的检索方式**:
  - `find <目录> -iname "*.patch" | wc -l`按目录逐项统计补丁数量的标准模板
  - 排噪思路模板:先分"第三方vendored库/patman测试噪声" vs "真实专有补丁" vs "废弃备份layer" vs "构建期materialize残留"四类,再分别用`find`/`grep`定位每一类的具体路径,不能拿到总数就直接当作"真实补丁数"
  - 按补丁subject文本逐条比对两侧同名/近义补丁是否存在(gstreamer案例:核对Q08C/Q10C压缩格式、GAP buffer、colorimetry优先级等补丁标题是否在两侧都能找到)
  - 全局字符串检索验证某补丁修复的功能是否有等价代码留存,如`verity=enabled`、`arg_usr_verity`、`sender_uid == 1001`零匹配
  - 抽样统计内核commit标签前缀频次(`git log`配合`FROMLIST:`/`BACKPORT:`/`QCLINUX:`/`PENDING:`/`WORKAROUND:`分类计数)
- **已知易错点/纠错记录**(本主题在README《曾纠正过的结论》表中有"补丁总量"条目,是全库最完整的纠错案例):
  - 初步判断:"补丁总量,src下约5,083个"(且最初总计曾报10,533个)
  - 核实后结论:src中约5,080个是第三方vendored库/patman测试噪声,真实仅3个(v4l-utils);另有6个真实内核补丁实际在`poky/meta-qti-bsp*`(此前误记为"从src中筛出",与src口径重复计入,现已订正为不重复计数);`disregard/`废弃备份38个、`build-qti-*`构建残留554个均需排除;QLI1.0全量补丁纠正后约4,861个
  - 抽样对象的二次纠偏:最初以为要看`meta-qti-bsp-prop`和`meta-qti-core`两层的patch密度,后发现这两层实际patch数为0(全用`SRC_URI="file://xxx"`整树拷贝私有源码),遂改为扫描全部`meta-qti-*`层patch密度,才定位到`meta-qti-gst`(144个,最高)作为抽样对象——提示"选抽样对象前先验证该层是否真的有patch文件",不能凭layer名称猜测

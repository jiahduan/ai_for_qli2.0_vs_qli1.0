# Toolchain —— 规则

> 本文件对应产出文档 [output/Build_Architecture/Toolchain/Toolchain.md](../../output/Build_Architecture/Toolchain/Toolchain.md),与全部33份主题规则文件按本次目录重构选择的方式各自完整独立(7条强制规则全文一致,不做共享继承,变更时需同步维护;背景见[Scope_Section_Design.md](../../Scope_Section_Design.md))。全局工作流/与README关系见根目录[Methodology.md](../../Methodology.md)。

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

## Build_Architecture 专属取证指引

构建体系与工具链对比。优先证据来源:
- 工具链版本:对应recipe文件名与内嵌版本号(如`glibc_2.43.bb`、`binutils_2.46.bb`)
- distro层是否二次锁定版本(如`GCCVERSION`覆盖),避免只看oe-core默认值就下结论
- 工具链是否被"默认"还是"仅可选/仅特定机型"使用,需要用`grep`扫描机型/recipe级override(如`TOOLCHAIN="clang"`)后再下结论,不能仅凭层是否存在判断使用范围
- 涉及Yocto版本跳跃(如中间版本被跳过)时,必须按规则6交叉官方migration guide确认breaking change,并逐条核实本仓库是否受影响(而非假设受影响或假设不受影响)

## Toolchain专属取证要点

- **关键双侧目录/文件锚点**:
  - 用户态工具链版本:`tcmode-default.inc`(GCC 13.%)、`binutils_2.42.bb`/`binutils_2.46.bb`、`glibc_2.39.bb`/`glibc_2.43.bb`
  - distro层二次锁定:`qti-distro-base.inc`(`GCCVERSION="13.4%"`)vs`qcom-base.inc`(未二次锁定)
  - `TC_CXX_RUNTIME`唯一赋值点:`bitbake.conf`(`TC_CXX_RUNTIME ??= "gnu"`)
  - QLI1.0 meta-clang层:`poky/meta-clang`(`LLVMVERSION="18.1.6"`)
  - 内核构建强制clang的recipe:`linux-msm_5.4.bb`(sa410m/sa515m,`TOOLCHAIN="clang"`/`RUNTIME="llvm"`)、`linux-msm_5.10/5.15.bb`/`linux-msm_6.%.bb`/`linux-common_6.12.bb`/`linux-common-soc_6.18.bb`(其余主流机型,`KERNEL_CC=.../clang/bin/clang`无条件)
  - clang来源载体:`kernel-toolchain_{5.10,5.15,6.%}.bb`(provider,原样打包`kernel_platform/prebuilts/clang/host/linux-x86/`AOSP预编译clang,与meta-clang层无关)
  - QLI2.0 clang等价物合并进oe-core:`oe-core/meta/recipes-devtools/clang/{clang_git.bb, llvm_git.bb, libcxx_git.bb, compiler-rt_git.bb, compiler-rt-sanitizers_git.bb, lld_git.bb, lldb_git.bb, clang-crosssdk_git.bb, clang-cross_git.bb, libclc_git.bb}`、`oe-core/meta/classes/toolchain/clang.bbclass`
  - QLI2.0仅两处recipe级clang override:`meta-openembedded/meta-oe/recipes-devtools/perfetto/perfetto.bb`、`meta-ros/meta-ros-common/recipes-devtools/ogre-next/ogre-next_2.2.7.bb`(实际构建路径解析到不带override的`ogre-next_2.3.3.bb`)
  - 孤立clang消费者:`meta-qti-gfx-prop/recipes/adreno/clangtblgen.bb`
  - 安全加固基线对比:两侧`security_flags.inc`,QLI1.0`meta-qti-distro/conf/distro/include/security_flags.inc`高风险组件清单(`npu`/`ebtables`/`audiohal`/`setools`/`gps-utils`/`loc-hal`/`loc-core`/`bt-app`/`libbt-vendor`/`media`/`lib32-qmmf-sdk`)
  - migration依据存档:`reference/System_Architecture/Yocto/Migration notes for 6.0 (wrynose)`
- **已验证的检索方式**:
  - 全文件类型限定搜索`TC_CXX_RUNTIME`赋值点,区分"唯一赋值"与"条件判断",确认全树是否有machine/distro conf把它改成llvm/android
  - `grep -rn PREFERRED_TOOLCHAIN`扫描全部machine/distro层(meta-qcom/meta-qcom-distro/meta-qcom-robotics-sdk/meta-security/meta-updater/meta-virtualization/meta-selinux/meta-audioreach/meta-ros/meta-lts-mixins),确认零override
  - `grep -rln 'TOOLCHAIN[[:space:]]*=[[:space:]]*"clang"'`全层扫描recipe级override,再逐个核实是否真的进入镜像依赖链:①`grep -rl <recipe名>`在meta-qcom系列+meta-ros层查有无依赖方引用;②核对各`PREFERRED_VERSION_<pkg>`及distro yml(`DISTRO_FEATURES:append`/`distro:`)实际选择的版本,排除"存在override但从未被构建路径选中"的假阳性
  - 读取`reference/`下"Migration notes for 6.0 (wrynose)"存档页面breaking change清单,核实GCC/glibc/binutils版本号跳跃本身是否属于Yocto强制迁移动作(结论:不属于,是oe-core逐release的recipe版本迭代)
  - 读取两侧`security_flags.inc`逐字节对比`SECURITY_CFLAGS`/`SECURITY_STACK_PROTECTOR`/`_FORTIFY_SOURCE`默认逻辑,再grep核实QLI1.0清单里的专有组件名(`npu`/`audiohal`/`gps-utils`/`loc-hal`/`loc-core`/`bt-app`/`libbt-vendor`/`qmmf-sdk`)在QLI2.0是否存在
- **已知易错点/纠错记录**:README《曾纠正过的结论》表收录本主题条目——"clang使用范围":初步判断"仅是可选项"(默认GCC,clang只是可选路径);核实后结论:该判断仅对用户态包成立,内核构建层面QLI1.0现役主流机型(pineapple/kalama/sun/mdm9607/cinder/qcm2290-mtp/qrb5165-rb5/trustedvm系列/seraph/pebble等)实际强制走AOSP预编译clang,这条路径与meta-clang层无关,体量远大于最初判断的"仅可选项"。

# Source_Code_Structure 执行报告

本文档复盘`../Source_Code_Structure.md`的结论是怎么从取证要点(见`rules/Code_Composition/Source_Code_Structure.md`"Source_Code_Structure专属取证要点"节)一步步落地的——按锚点/检索方式逐条展开"做了什么检索→得到什么证据→支撑了哪个结论"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Source_Code_Structure.md`。

## 1. QLI1.0顶层`src/`汇聚目录的坐实与构建残留的剔除

**做法**:`find src -maxdepth 1 -mindepth 1 -type d`统计QLI1.0顶层`src/`子目录数量与名单。
**证据**:实测35个子目录,其中1个(`build-qti-distro-camerastack-debug`)经核实是构建工作目录残留,不是专有源码组件,剔除后剩34个真实组件目录(`adsprpc`、`android_compat`、`security`、`mdm-ss-mgr`、`OTA`、`kernel-6.18`等)。
**落到结论**:对比总览表"顶层src/汇聚目录"行——这个"35个中剔除1个构建残留"的处理,是规则1"禁止仅凭目录名断言"精神的延伸应用:不能看到目录存在就直接计入统计,要先核实这个目录本身是不是真实的专有源码组件。

## 2. QLI2.0顶层无同名汇聚目录的坐实

**做法**:`find <QLI2.0根目录> -maxdepth 1 -iname "src"`。
**证据**:无输出。
**落到结论**:对比总览表"顶层src/汇聚目录"行QLI2.0一侧——这是零命中式的否定性证据,取证要点明确记录了这条命令,确保"顶层不存在src/"这一结论有明确的检索动作支撑,不是凭印象判断。

## 3. 按需拉取模式的具体样例

**做法**:读取具体recipe文件的`SRC_URI`/`SRCREV`字段,以`meta-qcom/recipes-multimedia/camx/camx-dlkm_1.0.3.bb`为例。
**证据**:`SRCREV="56b463cba50c1db1f2cc53ddd8790730f14bd8a8"`——即该组件的源码不是预先落地在某个固定目录,而是recipe自带版本锁定字段,构建时才被fetcher拉取。
**落到结论**:对比总览表"落地方式"行、"获取模式"行——单个具体recipe的证据被用来代表"按需拉取"这一整体模式的典型样例,《对比范围》"覆盖"字段明确标注这是"以...为例",不是穷举式证据,符合规则3对抽样声明的要求。

## 4. `src/security/*`与`src/mdm-ss-mgr`去向的关键字排查——留白处理

**做法**:在`meta-qcom`/`meta-qcom-distro`/`meta-security`/`meta-updater`等层检索`securemsm`/`mink-transport`/`subsys_modem`/`ssreq`/`pdc.daemon`/`trustedui`。
**证据**:均无命中(与Layer_Architecture.md逐层核实结果一致)。
**落到结论**:《待确认》节如实保留"这两块专有组件的用户态/上层部分是否仍以未纳入本次交付快照的私有kas overlay形式存在"为开放问题——取证要点明确说明这不是被推翻的结论,而是本地静态分析已到极限、需要人工询问安全/BSP团队的事实性开放问题。本报告据此不虚构一个"已查明去向"的结论,如实保留这一留白,并注明这与Code_Sync_Method.md核实kas私有仓库接入机制是"同一类问题的不同侧面"(kas机制层面已确认支持私有仓库接入,但这不能反过来证明这个具体的私有overlay确实存在)。

## 本主题无纠错记录的说明

取证要点明确标注本文档"暂无纠错记录";`src/security/*`与`src/mdm-ss-mgr`的确切承载方式在文档中标注为"待确认",是需要人工询问的开放问题,不是被推翻的旧结论——本报告不虚构一个"最初判断错了、后来纠正"的过程,如实反映这是"一开始就诚实标注为未知"的情形。

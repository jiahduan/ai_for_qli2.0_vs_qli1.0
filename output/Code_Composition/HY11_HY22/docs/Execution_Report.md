# HY11_HY22 执行报告

本文档复盘`../HY11_HY22.md`的结论是怎么从取证要点(见`rules/Code_Composition/HY11_HY22.md`"HY11_HY22专属取证要点"节)一步步落地的——按锚点/检索方式逐条展开"做了什么检索→得到什么证据→支撑了哪个结论"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../HY11_HY22.md`。

## 1. 功能定位的坐实——读脚本原文而非猜测

**做法**:直接读取`release/populate_prebuilt.sh`,核对`-v variant`参数说明及`if [ "$variant" == "HY11" ] || [ "$variant" == "HY22" ]; then ...`分支逻辑。
**证据**:脚本注释明确"`-v variant    CRM variant (e.g. HY11, HY22, ...)`",用法示例`populate_prebuilt.sh -t mdm9650 -v HY11`。
**落到结论**:对比总览表"脚本证据"行、"功能定位"行——这是本主题唯一的、最基础的证据来源,后续所有结论都建立在"这确实是一个CRM variant打包脚本"这一事实之上。

## 2. QLI2.0侧零匹配的坐实——全树扫描而非单点检索

**做法**:全树扫描(含`.bb`/`.bbappend`/`.conf`/`.md`/`.txt`/`.inc`/`.yml`/`.yaml`,排除build产物)检索"HY11"/"HY22"字符串。
**证据**:零匹配。
**落到结论**:对比总览表"关键字命中"行"全树扫描...零匹配"——遵循规则1"禁止仅凭目录名或关键字搜索为空就断言"的要求,扫描范围明确覆盖了配置/文档/脚本等多种文件类型,不是只搜了`.bb`就下结论。

## 3. 两变体业务差异的坐实——git历史+文件diff双重交叉验证

**做法**:读取`release`仓库git log(2954条commit,最早`f0a9f24`2009年);执行`diff crm/noship_common_HY11 crm/noship_common_HY22`;读取`poky/meta-qti-distro/conf/distro/qti-distro-rb-debug.conf`的`DISTRO_NAME`与`DISTRO_FEATURES`。
**证据**:git历史显示HY11对应`build-qti-distro-fullstack-debug/perf`,HY22对应`build-qti-distro-rb-debug/perf`;`qti-distro-rb-debug.conf`开启`ros2`/`vslam`/`librealsense2`,坐实HY22=机器人参考栈变体;`diff`结果显示HY22独有条目集中在`mdm-ss-mgr/{diag-reboot-app,pdc-daemon}`/`qmi`/`mbim`/`gps`等调制解调器路径。
**落到结论**:对比总览表"变体实际差异"行、《影响与风险》"HY11=通用应用处理器fullstack变体,HY22=机器人参考栈变体且额外打包蜂窝/调制解调器相关组件"这一具体结论——这是三种独立证据(commit历史、文件diff、DISTRO_FEATURES配置)交叉印证得出的结论,不是单一证据外推。

## 4. HY编号命名沿革的追溯——从"字面搜索为空"到"扩大到完整commit历史"

**做法**:`release`仓库`git log --all --grep`跨2009年至今全部历史搜索HY编号命名沿革,而非只搜当前文件内容。
**证据**:commit`7ce9ab4`(Add HY33 variant)、`429fe67`(hy33: Initial noship_common_HY33 for WebOS)、`3f2123c`(Rename HY33 to HY31 per target team request)。
**落到结论**:《影响与风险》"补充追溯HY编号的历史起源"整段——这一证据把"HY编号是什么"这个问题从"猜测"变成了"由release团队的target team按需分配、可重命名,不是固定语义编码"这一可坐实结论。这体现了取证方式的一次主动升级:单纯字面关键字检索无法回答命名沿革问题,必须把检索范围扩大到完整git历史(含2009年WebOS相关commit)才能坐实。

## 5. "HY"缩写全称——排查到位但如实标注未能查明,不强行下结论

**做法**:检索"HY"在"handset"/"hearable"/"hybrid"等常见Qualcomm产品线缩写模式附近的用法;`release`仓库2954条commit历史全文搜索;`crm/noship_common_HY11`/`HY22`/`HY31`/`HY33`文件内容检索。
**证据**:仅命中`x-ship`/`dest-branch`里大量`*-handset.lnx.*`分支名,与HY编号是两套独立标签体系,无缩写派生关系证据;字面缩写全称在全部可及范围内均未找到。
**落到结论**:《待确认》节如实保留为开放问题,不虚构一个查无实据的"全称"。取证要点特别提示"复核时勿把关键字搜索为空误判为该编号无历史记录"——本报告据此强调:命名沿革(HY33→HY31)已经查明,只有字面缩写本身未查明,这两者是不同层次的问题,不能因为其中一层查明了就误以为另一层也已解决。

## QLI2.0替代分发机制的坐实

**做法**:`grep -rn "softwarecenter.qualcomm.com" meta-qcom --include=*.bb --include=*.bbappend --include=*.inc`。
**证据**:命中`qwes_1.1.bb`、`diag-router_1.0.2.bb`、`firmware-qcom-boot-qcs9100.inc`等recipe。
**落到结论**:《关键差异》第三条"QLI2.0并非完全没有闭源预编译分发,而是把这件事...改造成了每个闭源组件的recipe直接从softwarecenter.qualcomm.com按组件名+版本拉取"——这是Principles.md第2节强调的"区分标签消失与能力消失"这一分析原则的具体落地证据:标签(HY11/HY22)确实消失,但分发能力(闭源二进制按需交付)并未消失,只是换了实现方式。

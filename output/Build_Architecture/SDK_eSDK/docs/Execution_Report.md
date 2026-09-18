# SDK_eSDK 规则执行逻辑细节报告

本文档记录`SDK_eSDK.md`当前结论的取证过程——按`rules/Build_Architecture/SDK_eSDK.md`"专属取证要点"逐条复盘。原理性背景见同目录`Principles.md`,具体差异结论见`../SDK_eSDK.md`。

## 逐条取证过程

### 1. 底层标准SDK类与二次封装class确认
**做法**:确认底层标准类(`populate_sdk_base.bbclass`/`populate_sdk_ext.bbclass`/`testsdk.bbclass`)两侧均未改动,再分别定位两侧的下游二次封装class。
**证据**:downstream(maili)`poky/meta-qti-bsp/classes/populate_sdk_qti.bbclass`(`inherit populate_sdk_ext`);QLI2.0`meta-qcom-robotics-sdk/classes/psdk-image.bbclass`(`addtask do_generate_qirp_sdk after do_populate_sdk`)。
**落到结论**:对比总览表前两行,《关键差异》"若审计报告只搜`do_populate_sdk`关键字本身,会得出两侧完全一样的错误结论"一段——差异隐藏在下游二次封装层,必须往下追层才能发现。

### 2. 产品线活跃度取证
**做法**:`find`确认downstream(maili) 4条产品镜像(`qti-multimedia-image.bb`/`qti-robotics-image.bb`/`qti-xreality-image.bb`/`qti-xreality2-base-image.bb`)均存在且都`inherit populate_sdk_qti`;读取`qti-xreality2-image.bb`的`require qti-xreality2-base-image.bb`引用链确认xreality2同样在用该机制;对每个recipe文件用`git log`取最后一次真实改动时间(剔除本地`[DNM]`临时commit)。
**证据**:`qti-multimedia-image.bb`2026-07-27、`qti-xreality2-base-image.bb`2026-05-27均近3个月内活跃;`qti-robotics-image.bb`2025-07-28约13个月未改动;`qti-xreality-image.bb`2023-01-09距今约3年7个月,是4条里明显最久未改动的一条。
**落到结论**:对比总览表"覆盖产品线"行,《影响与风险》"`qti-xreality`……是4条SKU里唯一长期无代码变更、事实上处于停止维护状态的一条"结论。

### 3. QLI2.0覆盖产品线排查
**做法**:grep核实meta-qcom/meta-qcom-distro/meta-security/meta-updater/meta-virtualization全层是否存在multimedia/networking/container-orchestration专属SDK打包的TODO/WIP痕迹。
**证据**:结果为无;唯一命中`do_populate_sdk`关键字的`meta-virtualization/.../vcontainer-tarball.bb`核实为上游通用容器打包recipe,与Qualcomm产品线规划无关。
**落到结论**:对比总览表"覆盖产品线"行QLI2.0一侧描述,《影响与风险》"是否要为multimedia/networking/container-orchestration线补一条专属打包/发布流程,属产品发布策略决策"结论。

### 4. SDK_VERSION管理对照
**做法**:分别核对`meta-qcom-robotics-sdk/classes/psdk-image.bbclass`硬编码值与`meta-qcom-distro/conf/distro/include/qcom-base.inc`的`${DISTRO_VERSION}`引用,并用`git log`分别取两者的赋值变更历史,判断是否同一时间段各自独立变化。
**证据**:`qcom-base.inc`里`DISTRO_VERSION`自2025-03-03显式设为`"2.0"`后至今42次相关commit里没有一次改动;`psdk-image.bbclass`的`SDK_VERSION`从2025-10-27的`"2.4.0"`,经多次修改在2026-06-23由专门commit改到`"2.7.0"`。
**落到结论**:对比总览表"SDK_VERSION管理"行——坐实qirp-sdk走的是与固件/distro版本完全脱钩的独立发布节奏,是有意为之而非疏漏。

## 纠错记录

本主题取证要点未记录纠错项(暂无先前判断被推翻的情况)。

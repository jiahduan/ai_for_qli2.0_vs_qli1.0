# Graphics 规则执行逻辑细节报告

本文档记录`Graphics.md`当前内容是怎么从源码证据一步步推导出来的——按`rules/System_Architecture/Graphics.md`"Graphics专属取证要点"逐条复盘,每一条"做了什么→得到什么证据→落到最终结论的哪一行"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Graphics.md`。

## 1. kgsl内核驱动分发链路核实

**做法**:核对QLI1.0`graphicsdlkm_git.bb`的`SRC_URI=file://vendor/qcom/opensource/graphics-kernel`本地编译方式,与QLI2.0`kgsl-dlkm_1.0.4.bb`的`SRC_URI="git://github.com/qualcomm-linux/kgsl.git;..."`。
**证据**:两侧`LICENSE`均为`GPL-2.0-only`,但QLI1.0即使目录名带"opensource"字样,实际仍是内部vendor源码树本地编译,并非真正对外公开的拉取源;QLI2.0改为公开GitHub仓库、SRCREV锁定。
**落到结论**:对比总览表"GPU内核驱动(kgsl)"行,"关键差异"节"功能上大体延续,但分发链路真正开源化"的判断。

## 2. GPU用户态3D驱动仍为专有二进制的核实

**做法**:核对QLI1.0`adreno_6.0.bb`(`LICENSE="Qualcomm-Technologies-Inc.-Proprietary"`,内部编译)与QLI2.0`qcom-adreno_1.855.5.bb`(`LICENSE="LICENSE.qcom-2"`,从qartifactory URL下载)的LICENSE字段与SRC_URI来源。
**证据**:两侧均为专有二进制黑盒,仅下载渠道从内部编译变为qartifactory下载。
**落到结论**:对比总览表"GPU用户态3D驱动"行,"关键差异"节"在两侧均为专有二进制黑盒,未发生开源化"的判断。

## 3. glvnd多vendor共存机制核实(与Display.md共用底层证据)

**做法**:读取`msm-gbm-backend.bb`确认它本身不注册glvnd vendor,只是mesa的`libgbm`在msm平台dlopen的GBM后端插件;进而确认真正与`qcom-adreno`竞争EGL vendor身份的是mesa自身(`mesa.bb`经`DISTRO_FEATURES`纳入`glvnd`+`mesa.bbappend`追加`freedreno`);读取`libeglvendor.c`的`LoadVendorsFromConfigDir()`与`libegl.c`的`GetPlatformDisplayCommon()`源码逻辑。
**证据**:`10_adreno.json`与`50_mesa.json`均会被加载,不互斥;按文件名字典序、首个成功者绑定的规则下adreno默认胜出。
**落到结论**:"影响与风险"节glvnd共存机制段落。本文档说明这份证据与Display.md共用同一次源码阅读,但本文档的分析落点是"GPU用户态驱动与开源mesa如何共存",不重复Display.md"显示合成/多输出场景"的落点。

## 4. A704新GPU代际支持核实

**做法**:读取`mesa.bbappend`里`0001-freedreno-Add-support-for-A704.patch`,确认backport自mesa上游commit`8055fefea12c0e0527f425306617bb40fafc466a`;对linux-qcom 6.18.30内核里hamoa/lemans/monaco/sar2130p/talos等全部已知机型dts做`qcom,adreno-*` compatible字符串扫描。
**证据**:补丁内容显示A704被归入A6xx家族分组(与QRB2210 RB1所用FD702同组),chip_id命名方式与FD702"无speedbin fallback"写法同构,是尚未绑定具体产品speedbin的通用占位ID;全部已知机型dts扫描均未发现A704声明。
**落到结论**:"关键差异"节"新增对A704等新GPU代际的支持"判断,以及"待确认"节"A704对应的具体SKU/评估板"这一开放问题——代码/公开渠道线索已用尽(公开渠道也查不到"Adreno 704"对应产品名),确认步骤指向需联系Qualcomm GPU团队。

## 5. 离线shader编译工具clangtblgen遗留状态核实

**做法**:读取`clangtblgen.bb`的`SRC_URI`/cmake target(`Oxili`);全树检索确认无其他recipe依赖它。
**证据**:该recipe自带独立LLVM副本(`adreno200/llvm`),专为2010年代Adreno 200生成shader工具,与meta-clang层、AOSP预编译clang均无关；QLI2.0侧无对应recipe,全树未见依赖。
**落到结论**:对比总览表"离线shader编译工具"行"遗留/未激活代码"的判定。

## 纠错记录说明

本主题`rules/System_Architecture/Graphics.md`"已知易错点/纠错记录"栏标注为"(暂无纠错记录)"。本次复核未发现某个先前判断被后续证据推翻的情况,如实按原文标注处理,不编造纠错过程。

# Distro_Version 规则执行逻辑细节报告

本文档记录`Distro_Version.md`当前内容(Comparison表格+优势/影响)是**怎么从源码证据一步步推导出来的**——按`rules/System_Architecture/Distro_Version.md`第2.1节定义的8步方法论逐步复盘,每一步"做了什么→得到什么证据→这个证据落到最终结论的哪一行"。原理性背景(Distro层是什么、为什么这样分工)见同目录`Principles.md`,具体差异结论本身见`../Distro_Version.md`。

## 执行时间线(本主题经历的格式迭代)

Distro_Version在本仓库里不是一次成型的,经过了几轮明确的用户决策调整,记录下来避免后人误以为当前格式是"从一开始就这么设计的":

1. 初版:和其余32篇一样,走标准的《对比范围/对比总览/关键差异/影响与风险》四段式,证据密集、逐条罗列。
2. 用户要求"完全取代现有结构",改成`Comparison`极简格式(仅优势/影响两个bullet列表),面向非技术读者。
3. 用户要求"重要对比以表格形式呈现"——在优势/影响之上,新增`维度|QLI1.0|QLI2.0`表格承载事实性对比,bullet降级为"表格之上的解读",不逐行复述表格。
4. 用户要求"逐个分析,先重新读取规则文件,再重新定义"——推动重新梳理了一遍分析方法论,从"抽象产品维度"收敛到"8步source-level分析法",第7步进一步精确到两个具体机型(8950-pebble/iq-9075-evk)而非抽象产品线覆盖度调查。
5. 执行"取证要点是否全覆盖"核查,发现4处证据缺口(PACKAGE_CLASSES/GCC锁定悬空引用旧表格、DISTRO_FEATURES具体值未落锚点、camerastack无对应结论缺检索证据、SELinux实际不启用缺具体构建证据),补齐。
6. 用户要求把产出文档挪进`Distro_Version/`子目录、配套规则文件也挪进去合并存放,后又要求把规则文件挪回`rules/`默认位置——最终态是**只有产出文档(`Distro_Version.md`)搬进子目录,规则文件留在原位**,是全仓库唯一的目录例外。
7. 本次:在`docs/`子目录新增本报告与原理文档。

## 8步方法论逐步执行记录

### 步骤1:定位物理载体
**做法**:确认distro层身份由哪个顶层layer承载,并检查`bblayers.conf`是否真的引用了它(不能只看layer目录存在)。
**证据**:QLI1.0`poky/meta-qti-distro`、QLI2.0`meta-qcom-distro`,均已在各自`bblayers.conf`确认被引用。
**落到结论**:表格第1行"Distro层物理载体"。

### 步骤2:核心变量赋值点
**做法**:在两侧`*.inc`文件里找`DISTRO_FEATURES`的具体赋值/追加语句,而不是只说"两侧都有DISTRO_FEATURES"这种空话。
**证据**:`qti-distro-base.inc`追加`eabi ipv6 ipv4 largefile thumb-interwork xattr selinux emmc-boot qti-wifi qti-ab-boot`;`qcom-base.inc`追加`efi glvnd kvm minidebuginfo opencl overlayfs pam pni-names polkit security tpm2 virtualization wifi x11`;逐项diff后确认两侧专有追加项**完全不重叠**(零交集,不是"大部分不同")。
**落到结论**:表格第8行"DISTRO_FEATURES专有项",以及优势第4条、影响第3条。

### 步骤3:变体矩阵组织方式
**做法**:数文件、追`require`/`include`链,并且反过来验证"某产品线是否真的没有承接"要靠遍历检索,不能靠"没搜到就是没有"的默认假设。
**证据**:QLI1.0 30个静态`.conf`;QLI2.0 4个conf+`meta-qcom-robotics-sdk`专属conf+35个kas yml;遍历全部35个yml及`meta-qcom/ci/`,检索`camerastack`/`xr`/`vnm`/`host`对应kas片段,**确认零命中**——这是一次真实排查得到的结论,不是"没提到就当作没有"的偷懒判断(呼应Methodology规则1的禁止性要求)。
**落到结论**:表格第3、10行,优势第1条,影响第1条。

### 步骤4:发行版级构建变量
**做法**:找`PACKAGE_CLASSES`/`GCCVERSION`在distro conf里是否有显式赋值行。
**证据**:`qti-distro-base.inc`未覆盖`PACKAGE_CLASSES`(继承`poky.conf`默认`package_rpm`);`qcom-distro.conf`显式声明`PACKAGE_CLASSES="package_rpm"`;GCCVERSION:QLI1.0二次锁定`13.4%`,QLI2.0未二次锁定继承`tcmode-default.inc`的`15.%`。
**执行中的返工**:这两个值最初在"专属取证要点"里只写了"详见旧版对比总览表",而旧版对比总览表在步骤2(格式迭代)时已被删除——这是"全覆盖"核查环节抓出来的悬空引用,后补上了具体`.conf`文件锚点。
**落到结论**:表格第4、5行,影响第2条。

### 步骤5:安全/能力开关绑定方式
**做法**:不能停在"overlay conf文件存在"就下结论,要看具体某次构建是否真的`require`了它。
**证据**:`PREFERRED_PROVIDER_virtual/refpolicy="refpolicy-mls-robotics"`硬编码在`qti-distro-camerastack-debug.conf`;QLI2.0`qcom-distro-selinux.conf`是独立overlay,`DEFAULT_ENFORCING?="enforcing"`;进一步核实QLI2.0当前实际构建`qcom-robotics-ros2-jazzy`**未`require`**该overlay,即真实构建里SELinux默认不启用。
**执行中的返工**:"当前实际构建默认不启用"这个具体结论最初也没有落到取证要点(只停在"overlay是可选的"这个机制层面描述),同样是"全覆盖"核查时补上的。
**落到结论**:表格第6行,优势第2条,影响第4条。

### 步骤6:OTA绑定点
**做法**:找哪个conf`inherit`了哪个更新相关bbclass。
**证据**:QLI1.0`qti-ab-boot`(A/B分区);QLI2.0`qcom-distro-sota.conf`(OSTree+aktualizr)。
**落到结论**:表格第7行,优势第3条,影响第5条。

### 步骤7:两个具体机型的distro conf链(本主题证据链的核心)
**做法**:不满足于"产品线抽象覆盖度",要求钉死两个真实存在、且有官方证据支撑其组合合法性的机型。
**证据链**:
- QLI1.0侧:先`find`定位到`poky/meta-qti-bsp*/conf/machine/pebble.conf`,确认`MACHINE=pebble`;再从`build-qti-distro-camerastack-debug/conf/auto.conf`的`DISTRO ?= "qti-distro-camerastack-debug"`/`MACHINE ?= "pebble"`实测读出这对组合是**真实用过的构建配置**,不是凭空指定的搭配。
- QLI2.0侧:先`find`定位到`meta-qcom/conf/machine/iq-9075-evk.conf`;但发现`meta-qcom/ci/base.yml`本身声明`distro: nodistro`,并不能直接证明"iq-9075-evk配qcom-distro"——进一步查`meta-qcom-distro/.github/workflows/build-yocto.yml`的真实CI矩阵,才找到官方证据`{machine: iq-9075-evk, distro: {name: qcom-distro, yamlfile: ':ci/qcom-distro.yml'}}`,确认这是官方CI**实际构建**的组合。
**中间的一次自我纠正**:一开始查到`base.yml`写`distro: nodistro`时,差点误以为"iq-9075-evk默认不带distro概念";多查了一层产品级workflow才发现nodistro只是CI base层的占位,真实构建走的是与产品级yml组合后的`qcom-distro`——这一教训已写进取证要点的"已知易错点"提醒。
**落到结论**:Comparison标题行的机型标注,表格第2、9行。

### 步骤8:成熟度佐证
**做法**:用git创建/首次提交/commit总量判断这是刚起步的草案还是已验证范式,并用"是否被其他产品线复用"做交叉印证(单看commit数量本身说服力有限)。
**证据**:`meta-qcom-distro`git创建2023-07-18、首次实质提交2024-01-25,至今582个commit;"base+selinux开关+sota开关+catchall"4-conf模式已在`meta-qcom-robotics-sdk`层原样复制一遍。
**落到结论**:优势第5条。

## 交叉一致性校验记录

- 全局脚本`scripts/check_scope_links.sh`已确认:Distro_Version相关的所有排除/被排除关系均无悬空引用(目标文档均真实存在)。
- Distro_Version.md本身因使用`## Comparison`而非`## 对比范围`,会被脚本持续报告为"[缺节]"——这是已知的、经用户确认的例外,不通过改脚本抑制,靠人工记忆即可(见2026年相关决策记录)。
- 曾短暂将配套规则文件(`Rules.md`)一并移入`output/System_Architecture/Distro_Version/`子目录,验证时发现全局脚本会把它误判为待回填的产出文档(因其递归扫描`output/`整棵树);用户随后决定该文件不移动,已还原至`rules/System_Architecture/Distro_Version.md`原位,脚本未做改动。

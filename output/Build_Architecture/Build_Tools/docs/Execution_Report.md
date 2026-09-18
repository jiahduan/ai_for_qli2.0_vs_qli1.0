# Build_Tools 规则执行逻辑细节报告

本文档记录`Build_Tools.md`当前结论的取证过程,尤其是"谁是真正的整机构建主入口"这一判断经历的纠错——按`rules/Build_Architecture/Build_Tools.md`"专属取证要点"逐条复盘。原理性背景见同目录`Principles.md`,具体差异结论见`../Build_Tools.md`。

## 逐条取证过程

### 1. kas作为整机构建入口的文件分布判定
**做法**:全树`find -iname '*kas*'`,人工排除误报。
**证据**:downstream(maili)命中全部为误报(boringssl的`KAS-ECC-SSC`/`KAS-FFC-SSC`测试向量、Linux内核`skas`/`sys_mikasa.c`/`kasprintf.c`、devicetree binding`asahi-kasei,ak*.yaml`);QLI2.0侧计数`meta-qcom/ci`(46个yml)、`meta-qcom-distro/ci`(36个)、`meta-qcom-robotics-sdk/ci`(19个)、`meta-security/kas`(21个)、`meta-updater/kas`(10个)。
**落到结论**:对比总览表"kas文件分布"行。

### 2. 主入口层误判的发现与纠正
**最初判断**:题目最初指向的目录是`meta-security/kas`、`meta-updater/kas`,若只停在这两个目录统计文件数,容易得出"kas在QLI2.0只是零星测试用途"的结论。
**核实过程**:用`git remote -v`核实这两层各自是独立git checkout——`meta-security`指向官方`git.yoctoproject.org/meta-security`,`meta-updater`指向`github.com/uptane/meta-updater`,均为`wrynose`分支;结合读取这两处`kas/`目录内容,确认是面向`qemux86-64`等仿真机型的oe-selftest自测配置,与整机构建无关,是上游社区层自带的CI产物,不是QLI2.0团队自己添加的。
**修正结论**:进一步读取`meta-qcom/ci/base.yml`(确认repos/machine/target/local_conf_header声明结构)及各机型yml(如`rb3gen2-core-kit.yml`),确认真正承载"一键搭建整机"职责的是`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`系列层的`ci/*.yml`;进一步核实`meta-qcom`是唯一有"Quick build"命令行示例的官方文档化主入口,`meta-qcom-distro`只是被前者`includes`引用的distro配置片段层,二者非并列入口。
**落到结论**:对比总览表"主入口层判定"行,《影响与风险》"题目最初指向的目录……实际是上游社区层自带的自测配置"一段。

### 3. kas工具自身机制核实
**做法**:读取本机安装kas 5.5包的`kas/schema-kas.json`与`kas/repos.py`/`libkas.py`。
**证据**:`repos:`条目schema字段严格限定在`name`/`url`/`type`/`commit`/`branch`/`tag`/`refspec`/`signed`/`allowed_signers`/`path`/`layers`/`patches`,且`additionalProperties: false`;认证方式靠`SSH_AUTH_SOCK`等环境变量透传,不在yaml里存token。
**落到结论**:《影响与风险》"kas原生没有能直接承载downstream(maili) manifest扩展属性的位置"一段。

### 4. 生成产物与声明的对应关系核对
**做法**:逐条比对kas yml的`repos:`/`layers:`声明集合与实际生成的`build/conf/bblayers.conf`的BBLAYERS列表,以及`local_conf_header`字典键与`build/conf/local.conf`分段是否逐条对应。
**证据**:两者精确对应,证明该工程确实通过`kas build`一步生成,不是脚本拼装的巧合结果。
**落到结论**:对比总览表"repos声明与目录对应"行,《关键差异》"声明式可复现vs脚本式动态发现"一段。

## 纠错记录

本主题的核心纠错就是上面第2条"主入口层误判"——初步判断范围(仅看`meta-security`/`meta-updater`两个目录)得出的结论方向是错的,核实后确认这两层是上游自带的自测配置,真正主入口在`meta-qcom`系列层。该纠错已写入产出文档《影响与风险》一节,不是静默覆盖。

# Distro_Version 原理文档

本文档解释"Distro"在Yocto/OpenEmbedded体系里到底是什么、它管什么、为什么要按"两个具体机型"而不是抽象产品线去对比——这是理解`Distro_Version.md`Comparison结论的前置知识,不涉及QLI1.0/QLI2.0具体差异结论(结论见`../Distro_Version.md`)。

## 1. Distro层是什么

Yocto/OpenEmbedded的构建配置分三层,各管一件事,互不越权:

| 层 | 变量入口 | 管什么 | 典型例子 |
|---|---|---|---|
| **Distro层** | `DISTRO`,对应`conf/distro/<DISTRO>.conf` | "这次构建出来的系统是什么样的发行版"——策略/合规/安全基线/软件包管理器/init系统等**跨机型统一**的选择 | `qti-distro-camerastack-debug`、`qcom-distro` |
| **Machine层** | `MACHINE`,对应`conf/machine/<MACHINE>.conf` | "跑在什么硬件上"——芯片型号、内核版本、启动方式等**硬件相关**的选择 | `pebble`、`iq-9075-evk` |
| **Local/Layer层** | `local.conf`/`bblayers.conf` | 具体一次构建临时用什么层、什么覆盖 | `build-qti-distro-camerastack-debug/conf/*` |

一次真实构建 = `DISTRO`×`MACHINE`的组合生效结果。这就是为什么"只看Distro层"或"只看Machine层"都不足以下结论——必须钉死一对具体的`DISTRO`+`MACHINE`组合,才能谈"这次构建实际生效的配置是什么"。这正是本主题分析方法论第7步"精确到两个具体机型"的原理依据:脱离具体机型讨论"distro优势",讨论的是一个从未真实构建过的假设组合,容易失真。

## 2. Distro层管的核心变量

- **`DISTRO`/`DISTRO_NAME`**:发行版标识本身。
- **`DISTRO_VERSION`/`DISTRO_CODENAME`**:发行版版本号/代号——**注意这不是本主题的分析对象**,这两个变量描述的是"这个distro基于哪个Yocto release"(如wrynose/scarthgap),属于Yocto release本身的版本对齐问题,归`Yocto.md`(《对比范围》"明确排除"第一条已声明此边界)。本主题只管"distro层这个配置容器本身"的组织方式与内容,不管它挂的Yocto release版本号。
- **`DISTRO_FEATURES`**:发行版级能力开关的集合,决定哪些能力面(安全/虚拟化/网络协议等)默认参与构建。Yocto对这个变量的处理机制经历过两代:
  - 老机制:`DISTRO_FEATURES_BACKFILL`(全局默认值)+`DISTRO_FEATURES_BACKFILL_CONSIDERED`(哪些默认值继续保留)+`_DEFAULT`
  - 新机制(5.1+引入):`DISTRO_FEATURES_DEFAULTS`+`DISTRO_FEATURES_OPTED_OUT`,语义更直接("默认给什么"+"主动去掉什么"),QLI2.0的`qcom-distro-sota.conf`用的就是新机制的`OPTED_OUT`写法
- **`PACKAGE_CLASSES`**:软件包格式(rpm/deb/ipk),是distro级的统一选择,不是逐包可选。
- **各类`PREFERRED_PROVIDER_virtual/*`**:同一虚拟能力(如`virtual/refpolicy`)在distro层指定用哪个具体实现,是distro层"选型权"的典型体现。

## 3. 为什么会有"变体矩阵"

同一个产品往往需要debug/release、含安全加固/不含、含虚拟化/不含等多种构建形态,每种形态就是一个"变体"。Yocto本身不强制"一个产品一个distro conf",工程组织方式有两种路线:

- **穷举式**:每种维度组合各写一份完整`.conf`文件——QLI1.0`meta-qti-distro`的30个`qti-distro-{产品线}-{模式}[-开关].conf`就是这条路线,文件数=维度组合数,新增一个维度就要成倍增加文件。
- **拼装式**:少量基础conf+外部声明式片段(kas yaml)按需组合——QLI2.0`meta-qcom-distro`的4个conf+35个kas yml就是这条路线,基础配置只写一份,变体差异表达在拼装层,不放大文件数。

这不是QCOM专属发明,是kas工具本身推广的Yocto工程实践演进方向(用声明式yaml替代人工维护的conf矩阵)。理解这一点,才能判断"变体数量从30降到4"是不是真的"能力变少了"——不是,是同样的组合能力换了一种更省文件的表达方式。

## 4. Distro层的"覆盖"意味着什么

Distro conf里对某个变量赋值,本质是"用distro层的选择覆盖上游默认值"。判断一个变量"是否被distro层管控",要看：

1. 该变量在`conf/distro/include/*.inc`或`.conf`里有没有出现赋值/`?=`/`.=`；
2. 有赋值,才算"distro层管控";没有,就是"继承上游/oe-core默认值,distro层没管这件事"。

这是为什么"GCC版本锁定方式改变"(QLI1.0 distro层二次锁定`13.4%` vs QLI2.0未锁定)是一条有意义的差异,而不是噪音——它意味着"谁对编译器版本负责"这件事的责任主体变了,不是版本号本身的变化。

## 5. 为什么SELinux这类能力要看"是否真的被引用",不能只看"文件存在"

Distro conf通常按"基础conf + 可选overlay conf"组织,可选overlay要被某次具体构建`require`才生效。这是Methodology.md规则1"禁止仅凭目录名断言"在Distro_Version主题下的具体体现:`qcom-distro-selinux.conf`文件存在,不代表任何构建都启用了SELinux——必须看某个具体`MACHINE`+`DISTRO`组合的构建脚本/CI矩阵是否真的`require`了它。这也是为什么"专属取证要点"第5条要额外核实"当前实际构建`qcom-robotics-ros2-jazzy`未`require`此conf"这一具体事实,而不是停在"该overlay conf存在"就下结论。

## 6. 与其他主题文档的分工边界(原理层面,非具体排除清单)

- Distro层"用哪个OTA机制"(选型事实)归本主题;OTA机制"具体怎么实现"(OSTree/aktualizr工作原理、镶像完整性校验细节)归`OTA_Mechanism.md`。
- Distro层"SELinux开关方式"(硬编码vs可选)归本主题;SELinux"策略规则本身有多少条、机型对应关系"归`Security_Architecture.md`。
- Distro层"kas yaml拼装"这个组织方式事实归本主题;kas工具本身的语法/CI矩阵结构细节归`Build_Tools.md`。

判断原则:**"distro conf层选了什么"归本主题,"选出来的东西内部怎么运作"归对应专题文档**——这条原则可以类推判断任何新出现的交叉话题该归哪篇,不需要每次都重新讨论。

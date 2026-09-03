# Bootargs 原理文档

本文档解释"cmdline/bootargs"这个概念在启动链体系里到底是什么、为什么值得单独拿出来对比、它和相邻主题的分工边界原理是什么——不涉及QLI1.0/QLI2.0具体差异结论(结论见`../Bootargs.md`)。

## 1. cmdline是什么、管什么

Linux内核启动时通过`/proc/cmdline`接收一串由bootloader传入的参数字符串,用于告知内核:根设备在哪(`root=`)、用什么方式挂载(`rw`/`ro`)、控制台在哪个串口(`console=`)、是否启用某些内核子系统的运行模式(如`verity=enabled`触发dm-verity相关路径)。cmdline本身不是一段可执行代码,是"内核启动时读取的一份配置清单",但这份清单的**内容从哪来、什么时候定下来**,直接决定了系统的可预测性和可审计性。

## 2. 为什么要对比这个主题

cmdline的生成方式(运行时动态拼接 vs 构建期静态烘焙)决定了两个现实工程问题:
- **可审计性**:如果cmdline是bootloader运行时根据分区表/槎位状态动态拼出来的(如QLI1.0的ABL+abctl读取`SLOT_SUFFIX`),仅凭Yocto源码仓库无法还原出设备上实际生效的完整cmdline,必须结合实机抓取;如果cmdline是构建期完全确定并写入镜像(如QLI2.0的`UKI_CMDLINE`),看配置就能还原,但代价是运行时灵活性下降。
- **安全语义**:cmdline里是否携带`verity=enabled`一类的参数,决定了内核初期挂载根设备时是否要求走完整性校验路径;这个参数从"有"到"消失"不是孤立的字符串变化,而是背后一整套校验机制是否还存在的外部体现。
一个具体config变量的取值差异,能牵出整条链路机制层面的差异,这是本主题存在的意义。

## 3. 与相邻主题的分工边界原理

- **与Boot_Flow的边界——为什么UKI签名结论的权威归属是Boot_Flow,不是Bootargs**:
  cmdline是被**打包进**UKI的一项内容(UKI = 内核+initrd+cmdline三者被`uki.bbclass`打成一个已签名或未签名的PE可执行文件)。secure boot签名(`UKI_SB_KEY`/`UKI_SB_CERT`/`sbsign`)是对**整个UKI容器**的完整性操作,一次签名同时覆盖kernel/initrd/cmdline三者,不存在"只签cmdline部分"这种颗粒度。而"UKI是什么、由哪个机制封装"这件事的定义权在Boot_Flow(它负责"内核镜像封装格式"这一启动链环节,`esp-qcom-image.bb`的`inherit uki uki-esp-image`、`oe-core/meta/classes-recipe/uki.bbclass`的签名钩子定义都归Boot_Flow取证)。按照"谁定义容器、谁就是容器级安全属性判定的权威来源"这一原则,UKI是否签名这件事的取证与结论应该只在Boot_Flow出现一次,Bootargs只引用其结论用于解释"cmdline构建期固化"的安全含义(见本主题《关键差异》),不重复取证——否则两篇文档各自维护一份`UKI_SB_KEY`零命中的证据,一旦上游补签名,容易出现只改一处、另一处漏改的不一致。
- **与systemd_的边界**:cmdline里`verity=enabled`一类参数"是否出现"归本主题取证;这些参数出现后systemd的`fstab-generator`具体怎么识别、改哪行源码,归systemd_——因为那是"消费cmdline内容的下游组件的内部实现",不是cmdline内容本身。
- **与Partition_Layout的边界**:cmdline里`root=`语法(隐式A/B slot vs 显式静态PARTLABEL)归本主题;但"到底存在哪些安全相关分区、消失了多少个"是分区层的静态清点工作,归Partition_Layout。cmdline只回答"内核挂载根设备时读到的是什么字符串",不回答"这个字符串背后对应的分区体系长什么样"。
- **与OTA_Mechanism的边界**:根文件系统完整性校验有无替代方案,涉及的是"产品级要不要补一套等价机制"的决策,这属于OTA_Mechanism的产品决策范畴;本主题只负责把"cmdline层面看不到任何完整性校验参数"这一取证事实交付给决策方,不越权下产品结论。

判断原则:**cmdline"写的是什么、什么时候写定"归本主题;这些内容背后依赖的容器机制(UKI)、消费方(systemd)、静态清点对象(分区)、产品决策(OTA)分别归各自专题**——这与Distro_Version.md"conf层选了什么归本主题,选出来的东西内部怎么运作归对应专题"是同一条分工原则的具体应用。

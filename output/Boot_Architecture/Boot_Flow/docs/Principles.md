# Boot_Flow 原理文档

本文档解释"启动链阶段划分"这件事在Qualcomm BSP体系里是什么、为什么要按阶段而不是按组件去对比,以及它作为Boot_Architecture分类"骨架文档"与相邻主题的分工边界原理——不涉及QLI1.0/QLI2.0具体差异结论(结论见`../Boot_Flow.md`)。

## 1. 启动链阶段划分是什么

Qualcomm SoC的启动链是一条严格顺序执行、逐级验证/加载下一级的链条:芯片上电后先执行片内ROM里的PBL(Primary Boot Loader),PBL加载并跳转到XBL/SBL,建立TZ(TrustZone)/HYP(Hypervisor)安全执行环境,再由这层跳转到"主Bootloader"(用户可定制的第一个较完整的软件bootloader),主Bootloader再加载内核镜像(可能经过二级引导层),内核起来后进入用户态。这条链每一级都比上一级更"软件可控",也更接近最终对比的焦点:PBL/XBL/TZ/HYP这几级几乎是SoC芯片固化行为,QLI1.0/QLI2.0在这几级通常没有差异空间;真正的架构选型差异出现在"主Bootloader往后"——用什么bootloader、内核镜像用什么封装格式、有没有二级引导层、initrd机制怎么接入。

## 2. 为什么要对比这个主题,以及它为何是"骨架文档"

Boot_Flow回答的是"整条启动链长什么样、每一级谁负责",这是理解Boot_Architecture分类下其余4个主题(Bootargs/Bootloader/Partition_Layout/systemd_)各自结论的前置坐标系——比如"cmdline在哪个阶段被写定"(Bootargs)、"bootloader自身来源可追溯性"(Bootloader)、"分区表在哪个阶段被读取"(Partition_Layout)、"systemd作为哪一阶段的产物启动"(systemd_),都需要先知道整条链的阶段划分才谈得上。QLI1.0(ABL/EDK2+Android boot.img)与QLI2.0(u-boot+UEFI/systemd-boot+UKI)在"主Bootloader往后"几乎每一级都换了实现,这不只是格式替换,而是把"谁能改启动参数、谁能验证启动产物"这件事从"vendor闭源二进制"整体搬到了"开源社区维护的构建配置"上——这直接决定了后续可审计性、可维护性、安全责任主体的归属,是需要专门梳理的工程问题。

## 3. 与相邻主题的分工边界原理

- **与Bootargs的边界**:Boot_Flow只负责"cmdline在哪个阶段被谁写定"这一机制事实(运行时动态 vs 构建期静态,证据止于`UKI_CMDLINE`变量存在);cmdline逐机型/逐参数的具体取值、verity相关字符串检索,不是"阶段划分"问题,是"内容"问题,归Bootargs。
- **与Bootloader的边界**:Boot_Flow只负责判断"这个bootloader在当前默认配置下是否真的参与了启动流程"(如u-boot在默认闭源固件路径下完全不参与打包,只在`open-fw`配置下才生效);而bootloader二进制**自身**的来源可追溯性、签名机制、板级defconfig矩阵属于"这个artifact本身的属性",不随它在哪条启动链上被使用而变化,归Bootloader。这是"角色 vs 身份"的区分:同一个bootloader换一条启动链角色可能变,但它自己的签名/来源不会因此变。
- **与Partition_Layout的边界**:分区总数、Android安全HAL分区去向是静态清点,不属于"阶段划分"本身,归Partition_Layout。
- **与OTA_Mechanism的边界**:Recovery/OTA触发路径与升级失败SOP是产品级流程决策,归OTA_Mechanism;Boot_Flow只负责说明"启动链本身在正常开机路径上长什么样",不覆盖异常恢复路径的产品决策。
- **为什么UKI签名结论的权威归属是Boot_Flow(而不是Bootargs或systemd_)**:UKI是"内核镜像封装格式"这一启动链环节的具体实现(`esp-qcom-image.bb`的`inherit uki uki-esp-image`),定义"内核镜像用什么格式封装"正是Boot_Flow的管辖范围。secure boot签名(`UKI_SB_KEY`/`UKI_SB_CERT`)是这个封装格式自带的能力钩子(定义在`oe-core/meta/classes-recipe/uki.bbclass`里,属于UKI机制本身的一部分,不是某个使用UKI的机型专属配置),因此"这套机制当前是否被启用(是否配置了签名密钥)"这一判定天然属于"UKI是什么"这个知识范围的延伸,理应由已经在负责阶段/格式取证的Boot_Flow统一给出结论。Bootargs和systemd_都只是"消费"这个已封装好的UKI容器的某个侧面(前者是容器里的一项内容,后者讨论的是与容器相关的NEWS变化),不应各自重新取证同一个事实——否则容易出现两篇文档各存一份`UKI_SB_KEY`零命中证据,一旦上游补签名两处不同步更新的风险。

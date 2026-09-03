# Kernel_Build 原理文档

本文档解释"内核构建"在Yocto/OE体系里管什么范围、为什么要单独对比它——是理解`Kernel_Build.md`具体差异结论的前置知识,不涉及QLI1.0/QLI2.0具体差异结论(结论见`../Kernel_Build.md`)。

## 1. "内核构建"在Yocto里管什么

Yocto对内核相关构建产物的管理分三个独立环节,分别有各自的标准机制:
- **内核镜像本身**:由`linux-yocto`类recipe(`inherit kernel`)编译主线内核树,产出`zImage`/`Image`等。
- **设备树(dts/dtb)**:由`KERNEL_DEVICETREE`变量+相关bbclass驱动,决定哪些dts文件被编译进dtb/FIT image。
- **out-of-tree内核模块(dlkm)**:由`inherit module`(`module.bbclass`)驱动的标准机制,把某个独立源码/独立recipe编译成`.ko`,并配合`kernel-module-split.bbclass`自动按模块拆包、`KERNEL_MODULE_PROBECONF`/`module_conf_<name>`控制加载策略。

本主题管的是这三个环节各自"用什么机制被纳入bitbake构建体系"——是标准Yocto机制,还是自研脚本/工具链搭出来的等价物,不管内核源码本身的补丁/血统治理(那是内核代码本身的问题),也不管dtb生成之后在启动阶段如何被bootloader选择应用(那是运行时行为)。

## 2. 为什么要对比这个环节,现实后果是什么

驱动/内核模块用"标准out-of-tree module recipe+独立git仓库SRCREV"还是"整棵vendor源码树file://拷贝"来组织,直接决定:
- **增量构建/sstate复用粒度**:file://整目录拷贝导致任何改动都让sstate判定整个recipe失效,而独立recipe+SRCREV可以做到逐模块级别的增量判定。
- **升级内核版本时的工作量分布**:同一个kernel_platform树整体repo sync升级,天然保证内核和驱动版本一致;拆成多个独立git仓库后,升级内核大版本需要逐个驱动仓库确认是否已适配新ABI,一致性保证从"目录结构自带"变成"需要人工建立跨仓库兼容性矩阵"。
- **Yocto生态工具可用性**:标准recipe机制下`devtool modify`等工具原生可用;自研脚本封装的机制通常无法直接享受这些工具链能力。

## 3. 与相邻主题的分工边界

- "驱动/模块/dts/dtb怎么被纳入bitbake构建"(build机制本身)归本主题。
- "内核源码补丁怎么打标签、FROMLIST/BACKPORT/PENDING等治理体系"——归[Kernel_Code_Architecture](../../System_Architecture/Kernel_Code_Architecture/Kernel_Code_Architecture.md),因为那是内核源码血统/合规追踪问题,不是构建机制问题。
- "dtb overlay在启动阶段如何被bootloader选择/合并应用"——归[Overlay](../../System_Architecture/Overlay/Overlay.md),因为那是运行时行为,不是构建期产出机制。
- "用什么编译器编译内核"(clang/gcc选择范围)——归[Toolchain](../Toolchain/Toolchain.md),因为编译器选型是独立维度,即便"内核用哪种构建机制"不变,编译器选型也可以独立变化。
- "kernel_platform补丁总量的统计与Code_Composition侧补丁管理体系的完整对照"——归[Patch_Management](../../Code_Composition/Patch_Management/Patch_Management.md),本主题只借用统计结果排除噪声,不重复做补丁管理的完整分析。

判断原则:构建期"怎么把源码变成可部署产物"的机制问题归本主题;源码本身的治理/运行时行为/编译器选型/补丁管理体系分别是四个独立维度,不因为都涉及"内核"就混在一起讨论。

# Toolchain 原理文档

本文档解释"工具链"在Yocto/OE体系里管什么范围、为什么要对比它——是理解`Toolchain.md`具体差异结论的前置知识,不涉及QLI1.0/QLI2.0具体差异结论(结论见`../Toolchain.md`)。

## 1. 工具链在Yocto里管什么

工具链指"用什么编译器/汇编器/链接器/C库组合把源码变成目标产物"这一层选择,核心变量包括:
- **用户态默认工具链**:`tcmode-default.inc`里锁定的GCC版本,`TCLIBC`选择的C库(glibc/musl/newlib/baremetal/picolibc等)。
- **`TC_CXX_RUNTIME`/`PREFERRED_TOOLCHAIN`**:决定默认走GNU工具链还是LLVM/clang工具链,这是可以按recipe/机型override的开关,不是全局一刀切。
- **distro层二次锁定**:distro conf可以覆盖oe-core默认的工具链版本(如`GCCVERSION`),这决定了"谁对最终生效的编译器版本负责"。

工具链是一个可以在多个层级(oe-core默认→distro层→machine层→recipe层)被覆盖的选择,任何一层的override都可能改变某个具体recipe实际用的编译器,这是为什么"判断工具链使用范围"不能只看某一层是否存在,必须做override扫描。

## 2. 为什么要对比这个环节,现实后果是什么

- **ABI/安全默认值兼容性**:编译器/C库版本跳跃可能带来ABI变化或安全加固默认值收紧(如`_FORTIFY_SOURCE`默认级别提升),对预编译二进制blob(常见于专有modem/DSP组件)的兼容性冲击最大。
- **选择范围的现实使用面**:一个可选的编译器路径"存在"不代表它"被使用"——必须确认某个override是否真的进入了某条实际构建的镜像依赖链,否则容易高估或低估某条工具链路径的实际影响面。
- **内核与用户态工具链选择可以脱钩**:内核构建和用户态包构建是两条独立的编译流水线,可以选用不同的编译器,不能因为"用户态默认GCC"就假设内核构建也默认GCC。

## 3. 与相邻主题的分工边界

- "用什么编译器/C库、选择逻辑与override范围"归本主题。
- "Yocto版本跳跃本身逐release的breaking change清单"(工具链版本号提升是否属于Yocto强制迁移动作)——归[Yocto](../../System_Architecture/Yocto.md),本主题只借用其迁移指南核实结论,不重复做逐release分析。
- "内核构建体系本身"(module.bbclass/dlkm recipe/dts-dtb编译/模块黑名单)——归[Kernel_Build](../Kernel_Build/Kernel_Build.md),本主题只回答"内核构建用的是哪个编译器",不回答"内核模块怎么被纳入构建"。

判断原则:编译器/C库本身的选型与生效范围归本主题;这个选型被谁使用(内核构建机制)、这个选型的版本变化是否属于平台级强制迁移,分别是两个更专门的问题,留给对应专题。

## 4. 为什么"是否强制使用"要看override扫描而非层是否存在

`meta-clang`层存在≠clang被默认使用,`TOOLCHAIN="clang"`override存在≠该recipe真的进入镜像构建路径。判断"某条工具链路径的实际使用范围"必须做两层核实:①`grep`扫描是否有override;②核实该override所在的recipe是否被任何`PREFERRED_VERSION`/`DISTRO_FEATURES`选中并真的被其他recipe依赖引用。只做静态存在性判断容易得出方向错误的结论——这正是本主题"内核构建强制clang范围"纠错的方法论基础(见`Execution_Report.md`)。

# SDK_eSDK 原理文档

本文档解释SDK/eSDK在Yocto/OE体系里是什么、管什么范围、为什么要对比它——是理解`SDK_eSDK.md`具体差异结论的前置知识,不涉及downstream(maili)/QLI2.0具体差异结论(结论见`../SDK_eSDK.md`)。

## 1. SDK/eSDK是什么

Yocto标准提供`do_populate_sdk`/`do_populate_sdk_ext`两个任务,把"给平台之外的应用开发者一套可用的跨平台开发环境"这件事标准化:
- **标准SDK**(`populate_sdk_base.bbclass`):产出toolchain+目标sysroot+headers/libs的自解压安装包,面向"只需要编译应用、不需要改BSP/内核"的开发者。
- **扩展eSDK**(`populate_sdk_ext.bbclass`):在标准SDK基础上叠加devtool支持,让开发者可以在SDK环境里对单个recipe做`devtool modify`/增量重建,面向"需要就地改动某个组件源码并重编"的开发场景。

这两者都是bitbake原生任务,产出的是"给SDK使用者的交付物",不是"给平台自己构建镜像用"的机制,这是它和其余Build_Architecture主题(如Toolchain、Kernel_Build关注的是平台自身怎么被构建出来)的根本区别。

## 2. 为什么要对比这个环节

SDK/eSDK的选型本质是"要不要把构建系统的一部分开放给SDK使用者",这决定了:
- **开发者能做什么**:eSDK可以`devtool modify`原地改代码重编,标准SDK的使用者只能拿到固定的toolchain+预编译产物,不能就地重编平台组件。
- **交付形态与体积**:eSDK因为要装下devtool所需的完整开发环境,体积更大、维护成本更高;标准SDK更轻,适合纯发布交付场景。
- **产品线覆盖策略**:是否每条产品线都需要一份专属打包后处理(二次封装class),取决于该产品线的开发者是否需要"拿到SDK之后还能自己改点东西"这一需求强度。

## 3. 与相邻主题的分工边界

- SDK/eSDK"怎么把开发环境打包给外部开发者"(打包机制、devtool集成、产物形态)归本主题。
- "SDK里打包的编译器本身是什么版本、怎么选型"——属于[Toolchain](../Toolchain/Toolchain.md)的范围,SDK/eSDK只是这份工具链的一种交付载体,不重新定义工具链身份本身。

判断原则:凡是"这份交付物内部装的是什么"这类工具链身份问题,交给Toolchain统一回答;本主题只回答"这份交付物是怎么打包出来、开发者拿到手之后能做什么"。

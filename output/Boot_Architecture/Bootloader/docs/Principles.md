# Bootloader 原理文档

本文档解释"Bootloader"作为独立主题在这里具体管什么、为什么这些属性值得单独拿出来看,以及与Boot_Flow"角色定位"式讨论的边界原理——不涉及downstream(maili)/QLI2.0具体差异结论(结论见`../Bootloader.md`)。

## 1. 本主题管什么:artifact自身的身份,不是它在链上的角色

一个bootloader二进制在Yocto recipe里,除了"它在启动链哪个阶段生效"这个运行时角色问题外,还有一组独立于运行时角色的**自身属性**:它的源码从哪来(`SRC_URI`/`PV`/`SRCREV`,是否指向可追溯的公开版本)、编译产物怎么被签名(用什么工具、什么签名模式)、支持哪些板级配置(defconfig矩阵)。这些属性描述的是"这个软件artifact本身是什么、谁能验证它、谁能改它",即使某次构建里这个bootloader暂时不参与打包(如QLI2.0默认闭源固件路径下u-boot不参与启动),它自身的来源/签名属性依然存在且值得记录——这就是本主题存在的意义:把"artifact的身份"和"它在某条具体启动链上扮演的角色"分开看。

## 2. 为什么要对比这个主题

Bootloader的来源可追溯性和签名机制,直接对应两个现实工程问题:
- **供应链可审计性**:`SRC_URI=file://edk2`这种本地打包、无公开版本号的引入方式,意味着无法在仓库外部追溯这份代码的历史变更、无法独立验证其内容;而指向公开GitHub固定commit的引入方式,版本可追溯、可复现、理论上也可以向上游提PR。这个差异决定了安全评审/供应链审计能不能拿到足够信息。
- **签名信任链归属**:签名机制决定"谁有权力认证一个bootloader镜像是合法的、没被篡改的"。downstream(maili)的`sectoolv2_sign_abl`是QTI私有工具链,QLI2.0的`qtestsign`是社区维护工具——但两者目前都只做到测试签名,这意味着"量产签名到底该由谁来提供、接入点在哪"是一个悬而未决、需要单独确认的工程问题,而不是"哪边签名机制更先进"的简单比较。

## 3. 与相邻主题的分工边界原理

- **与Boot_Flow的边界**:Boot_Flow回答"这个bootloader在当前默认配置下是否真的参与了打包/生效"(运行时角色问题);Bootloader回答"这个bootloader二进制本身来自哪里、怎么被签名、支持哪些板级配置"(身份属性问题)。判断原则是:**属性会不会因为"这次构建用不用它"而改变**——来源/签名属性不会变(u-boot的SRCREV无论是否参与打包都是同一个commit),角色会变(同一个u-boot在open-fw配置下参与打包,在默认配置下不参与),会变的归Boot_Flow,不会变的归Bootloader。
- **与Bootargs的边界**:签名/板级配置只覆盖到"谁引导、如何签名"这一层,不涉及cmdline具体取值,cmdline内容归Bootargs。
- **与Partition_Layout的边界**:Android安全HAL分区、AVB/dm-verity完整性校验替代方案属于"分区/校验体系"层面的产品级结论,不是bootloader自身的属性,归Partition_Layout(校验机制本身)与Bootargs(cmdline层面的verity参数)。

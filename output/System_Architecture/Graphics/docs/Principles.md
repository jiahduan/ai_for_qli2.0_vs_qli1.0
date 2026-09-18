# Graphics 原理文档

本文档解释Graphics子系统在Qualcomm Linux BSP体系里管什么、为什么要对比它、以及它与相邻主题的分工原理——这是理解`Graphics.md`具体差异结论的前置知识,不涉及downstream(maili)/QLI2.0具体差异结论(结论见`../Graphics.md`)。

## 1. Graphics管的是"渲染"这一层

延续Display.md原理文档里"渲染 vs 合成"的划分:Graphics本文档管的是GPU内核驱动(kgsl,负责把渲染指令和数据在CPU/GPU之间调度)与用户态3D渲染驱动(GLES/Vulkan/OpenCL,负责把着色器程序编译并在GPU上执行、把每个像素真正算出来)。这两层合起来构成"渲染"阶段,产出的图像帧再交给Display子系统的合成层做进一步处理。

GPU用户态驱动(尤其是移动/嵌入式GPU的专有实现)在整个行业里长期保持闭源黑盒,原因是GPU微架构本身、指令集、驱动内部的调度/功耗管理策略是芯片厂商核心商业机密,不同于CPU指令集早已标准化,GPU厂商普遍不愿公开驱动实现细节。这也是为什么Adreno用户态驱动在downstream(maili)/QLI2.0两代之间都保持专有——这不是QLI2.0迁移不彻底,而是行业现状本身如此。

## 2. 为什么要对比这个主题

Graphics是本次审计里"开源化程度最低"的子系统之一,对比的价值恰恰在于确认这一点:交付形态从"内部源码全量编译"变为"从qartifactory下载预编译二进制",是分发渠道的变化,不是本质开源化;真正开源化的是外围组件(kgsl内核驱动改为公开GitHub仓库拉取,GBM层从厂商fork变为独立开源`msm-gbm-backend`项目)。把渠道变化与本质开源化区分清楚,才能准确评估BSP团队对GPU这一层的实际可控性有没有提升——结论是没有,升级/安全补丁节奏仍完全依赖Qualcomm发布节奏。

## 3. 与相邻主题的分工边界原理

- SDM/HWC合成服务层、DRM/KMS显示管线、Wayland/Weston合成器与多显示拓扑归Display——依据"渲染 vs 合成"的阶段划分,渲染产出的帧数据如何被合成到屏幕上不是本主题范畴。
- GPU专有二进制预编译分发基建的通用机制(qartifactory/`softwarecenter.qualcomm.com`按组件名+版本拉取)归HY11_HY22——因为下载渠道本身是跨子系统通用的分发基建机制(供本主题、Camera的camxlib、Display的相关组件共用),不是GPU技术本身的差异,只在负责产品变体分发的横向文档里讲一次即可。
- GPU内核外置驱动模块(`-dlkm`)编译机制的通用框架(独立git仓库+SRCREV模式、模块黑名单机制)归Kernel_Build——因为这套编译机制覆盖的不止kgsl一个驱动,是内核外置模块的通用构建套路,本主题只承接"kgsl具体走了这套机制、结果是什么"。
- `meta-qti-gfx-kernel`/`meta-qti-gfx-prop`向`meta-qcom`的层归并本身归Layer_Architecture——因为目录结构调整是层组织方式的通用问题,不是GPU驱动技术的实质差异。

判断原则:**GPU渲染技术本身(驱动交付形态、开源程度、代际支持)归本主题;分发渠道、内核外置模块编译框架、层目录结构调整等"承载机制"归各自的横向文档**——与Camera.md采用的分工哲学完全一致:通用机制不因为它服务的对象是GPU就该归入GPU专属文档。

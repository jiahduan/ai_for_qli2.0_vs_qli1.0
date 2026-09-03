# Overlay 原理文档

本文档解释Overlay在Qualcomm Linux BSP体系里管什么、为什么要对比它、以及它与相邻主题的分工原理——这是理解`Overlay.md`具体差异结论的前置知识,不涉及QLI1.0/QLI2.0具体差异结论(结论见`../Overlay.md`)。

## 1. "overlay"这个词在本文档里指两类完全不同的机制

Overlay本文档要先澄清一个容易混淆的前提:"overlay"这个英文词在Linux/嵌入式领域至少对应两类互不相关的机制,只是碰巧共享同一个名字。

- **rootfs层overlayfs**:一种文件系统挂载技术,把只读的基础根文件系统与一层可写目录叠加呈现为一个逻辑上可写的整体,常用于支持只读根文件系统的可维护性(修改可以写在可写层,不污染基础镶像),并常与OTA原子升级/回滚机制配合。
- **设备树dtbo overlay**:内核启动阶段把一份"基础设备树"与若干"叠加片段(overlay)"合并,以便同一份基础内核镶像通过组合不同的dtbo文件适配多种硬件变体,避免为每种硬件配置单独维护一整份设备树。

这两类机制解决的工程问题完全不同(前者关乎存储/更新架构,后者关乎硬件适配的可组合性),但因为工程师日常交流里都简称"overlay",很容易被误认为是同一件事——这正是本主题存在的第一个理由:先讲清楚"这不是一回事"。

## 2. 为什么要对比这个主题

rootfs overlay方案的选择(自研overlay-mounter体系 vs 标准overlayfs-etc/OSTree路线)直接决定OTA升级/回滚的架构基础,升级/回滚/分区布局在不同方案间互不兼容,是一次架构级迁移而非局部调整。dtbo overlay构建链路的选择(动态`merge_dtbs.py`扫描合并 vs U-Boot FIT image声明式`FIT_DTB_COMPATIBLE`映射)决定了新增一种硬件变体组合时的工程成本与灵活性。两者都属于"看起来是小机制,但决定了后续大量日常工程操作的便利程度"的基础设施选择,值得单独拉出来对比,而不能被淹没在其他主题的篇幅里。

## 3. 与相邻主题的分工边界原理

- OTA整体升级机制、分区与镜像格式对比(A/B ext4 vs OSTree+aktualizr)归OTA_Mechanism——因为rootfs overlay只是OTA流程里被消费的一个环节(比如"copy the contents of system overlayfs"这一步骤),OTA机制本身的原子性/回滚保证/镜像签名校验等更大范畴的问题不该被塞进本主题。
- dtbo在存储介质上的分区级布局(是否存在`dtbo_a/b`分区)归Partition_Layout——因为那是"dtbo文件存在哪个分区"的物理布局问题,与"dtbo内容本身怎么产生、怎么合并"是不同问题。
- 显示合成层的硬件overlay/plane能力(SDM/HWC多层合成offload、多显示拓扑)归Display——这是本文档反复强调的"同名不同物"典型案例:合成阶段的硬件overlay/plane指的是屏幕上多个图层的硬件叠加能力,与设备树dtbo overlay毫无关系。
- 参考机型(`qcom-armv8a`/`qcom-armv7a`,走`linux-yocto`+kmeta)与量产机型(走`linux-qcom`)两条独立DTS维护体系的内核provider双轨架构对比归Kernel_Code_Architecture——因为那是内核provider选择本身的治理问题,不是dtbo overlay内容层面的差异。

判断原则:**先辨清"overlay"这个词在当前语境下具体指哪一类机制,再谈归属;文档内部按机制分组(rootfs方案/设备树overlay)呈现,避免因共享名字而被误当作同一件事分析**——这是本轮9个主题里对"警惕名词误导"表述最直接的案例,也呼应了Display.md原理文档中对同一问题的处理方式。

# System Architecture — Overlay

## 对比总览(rootfs / overlayfs方案)

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 实现方式 | 自研`qimage-ext4.bbclass`的`gen_overlayfs()`生成`/overlay/{etc,data,cache}`+专用`overlay-mounter`二进制 | 标准`overlayfs-etc.bbclass`存在但未被meta-qcom调用 |
| 与OTA耦合 | `ab-ota-ext4.bbclass`等在升级时拷贝system overlayfs内容 | 走`meta-updater`(OSTree+aktualizr),`sota` DISTRO_FEATURE驱动,原子部署+`/etc`三方合并 |
| 是否默认启用 | 按机型开关(`read-only-rootfs`) | 当前默认构建均未启用(既无overlay-mounter,也未开sota) |

## 对比总览(设备树Overlay)

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| Overlay源文件规模 | 385个`*-overlay.dts`(`src/display/vendor/qcom/{proprietary,opensource}/{mm,display}-devicetree/`) | 内核自带mainline风格dtbo(如`lemans-evk-emmc.dtbo`) |
| 构建系统归属 | 标准Linux Kbuild(`Makefile`+`Kbuild`,`KBUILD_EXTMOD_DTS`),无Android.bp/mk | 标准内核Kbuild |
| 编译链路 | 独立recipe(`mmdevicetree_git.bb`等)产出`tech_dtbs/` → `qimage.bbclass`的`do_merge_techpack_dtbos`合并`kernel_dtbs`+`tech_dtbs` → `do_makedtbo`产出`dtbo.img` | `linux-qcom-dtbbin.bbclass`(仅处理基础dtb,显式跳过dtbo)+ `dtb-fit-image.bbclass`(声明式`FIT_DTB_COMPATIBLE`映射,`mkimage`产出U-Boot FIT image) |
| 产物格式 | Android式`dtbo.img`,ABL按硬件ID选择 | U-Boot式FIT image |
| 是否真实参与最终镶像 | 已验证:`tech_dtbs/pebble-mm-atp-overlay.dtbo`与源码`pebble-mm-atp-overlay.dts`文件名逐字对应 | 已验证:实际内核构建产出真实dtbo |
| 默认开关 | `BUILD_WITH_TECHPACKS ?= "1"`(pineapple/kalama/pebble显式设为1) | 不适用 |

## 关键差异

- rootfs方案路线切换(自研overlay-mounter+A/B → OSTree/aktualizr)是架构级迁移,升级/回滚/分区布局互不兼容。
- QLI1.0的techpack overlay(display/mm/video/audio/camera/eva各自专属)确认是真实交付内容,非死代码,迁移到QLI2.0需要逐一找到承接方案。

## 影响与风险

- 当前默认构建两边rootfs方案都未真正启用,需确认是过渡态还是最终形态。
- `linux-qcom-dtbbin.bbclass`跳过dtbo,`dtb-fit-image.bbclass`是并行的完整实现,两者是否会同时启用产生冲突需确认。

## 待确认

- `linux-qcom-dtbbin.bbclass`"跳过dtbo"是有意设计还是遗留代码。
- QLI2.0是否有等价的"techpack overlay合并"机制承接display/mm/video/audio/camera/eva各自专属overlay。
- 两侧默认镶像是否真正只读,建议实机验证`mount`输出。
- sota路线是否为官方规划中唯一的未来OTA方案。

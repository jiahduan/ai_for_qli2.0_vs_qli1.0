# System Architecture — Overlay

## 对比范围

- **覆盖**:本文比较两类相互独立、名字都带"overlay"但机制无关的能力——①rootfs层overlayfs方案(自研overlay-mounter体系 vs 标准overlayfs-etc/OSTree路线);②设备树dtbo overlay(techpack overlay构建/合并/是否真实进最终镶像),按机制分组列出双侧锚点:
  - rootfs overlayfs方案:
    - QLI1.0锚点:`poky/meta-qti-bsp/classes/qimage-ext4.bbclass`(`gen_overlayfs()`)、`qimage-squashfs.bbclass`、`overlay-mounter_1.0.bb`专用挂载器、`ab-ota-ext4.bbclass`/`ab-ota-squashfs.bbclass`/`ota-ext4.bbclass`、`poky/meta-qti-bsp/recipes-kernel/linux-msm/files/overlayfs.cfg`(`CONFIG_OVERLAY_FS=y`)、`poky/meta-qti-bsp/recipes-products/images/qti-csm-image.bb`等机型的`read-only-rootfs` IMAGE_FEATURES
    - QLI2.0锚点:`oe-core/meta/classes-recipe/overlayfs-etc.bbclass`(本次复核`grep -rln overlayfs-etc meta-qcom meta-qcom-distro meta-qcom-robotics-sdk`重新确认零处inherit)、`meta-updater`(`sota` DISTRO_FEATURE驱动)、实际构建镶像`build/tmp/deploy/images/iq-9075-evk/qcom-robotics-image-iq-9075-evk.rootfs.ext4`的`/etc/fstab`
    - 本次复核新发现的边界点(未改动正文,仅在此记录锚点):QLI2.0实际构建产物`build/tmp/work-shared/iq-9075-evk/kernel-build-artifacts/.config`里`CONFIG_OVERLAY_FS=m`真实存在(本次重新grep确认),与对比总览表"内核配置"行QLI2.0列"不适用(机制不同)"的表述并非完全等价——内核侧overlay文件系统能力本身存在,只是当前没有任何上层机制(`overlayfs-etc`未被inherit)去使用它
  - 设备树dtbo overlay——源文件与构建链:
    - QLI1.0锚点:385个`*-overlay.dts`(`opensource/display-devicetree`209、`mm-devicetree`96、`proprietary/display-devicetree`52、`mm-devicetree`28)、`mmdevicetree_git.bb`/`displaydevicetree_git.bb`编译recipe、`qimage.bbclass`的`do_merge_techpack_dtbos`(`merge_dtbs.py`)、`BUILD_WITH_TECHPACKS`开关变量(`msm-common.inc`)、`qimage-dtbo.bbclass`(`do_makedtbo`,产物`dtbo.img`)
    - QLI2.0锚点:内核自带`arch/arm64/boot/dts/qcom/Makefile`、`meta-qcom/classes/linux-qcom-dtbbin.bbclass`(基础dtb打包)、`meta-qcom/classes-recipe/dtb-fit-image.bbclass`(`FIT_DTB_COMPATIBLE`声明式映射+`do_generate_qcom_fitimage`)、`qcs615-ride.conf`的`LINUX_QCOM_KERNEL_DEVICETREE`、`fit-dtb-compatible-linux-qcom.inc`
  - 设备树dtbo overlay——是否真实参与最终构建的证据链锚点(对应README《曾纠正过的结论》"Display overlay"一行,本次已重新走一遍核实,结论不变):
    - 实际构建产物锚点:`build/tmp/work/iq_9075_evk-qcom-linux/linux-qcom/6.18.30/image/boot/*.dtbo`(本次复核`find`重新点数,仍为9个:`lemans-staging`/`lemans-evk-emmc`/`lemans-el2`/`lemans-evk-camx`/`lemans-camx-el2`/`lemans-evk-camera-csi1-imx577`/`lemans-evk-sd-card`/`lemans-evk-ifp-mezzanine`/`lemans-evk-staging`)
    - 并行互补关系锚点:`linux-qcom-dtbbin.bbclass`第19-20行`# Skip DTBOs`注释(本次复核重新grep确认原文不变)与`dtb-fit-image.bbclass`的`do_generate_qcom_fitimage`任务
    - machine级配置实值锚点:`meta-qcom/conf/machine/qcs615-ride.conf`第16-18行`LINUX_QCOM_KERNEL_DEVICETREE ?= "qcom/talos-el2.dtbo qcom/talos-staging.dtbo"`(本次复核重新读取原文件确认一致)
    - **机型级精确钉定(本次新增,方法论详见`rules/System_Architecture/Overlay.md`2.1节第6步)**:精确到`iq-9075-evk`(QLI2.0,芯片家族`lemans`/QCS9075/QCS9100)——`meta-qcom/conf/machine/iq-9075-evk.conf`的`KERNEL_DEVICETREE`(1个dtbo)+`LINUX_QCOM_KERNEL_DEVICETREE`(8个dtbo)合计9个,与上一条锚点实际产出的9个`.dtbo`文件逐一对应。已实测确认QLI1.0侧**不存在同芯片家族的直接对应机型**:遍历QLI1.0全部140个`conf/machine/*.conf`,`grep -i "lemans\|qcs9100\|qcs9075\|sa8775"`零命中;但QLI1.0内核源码树`src/kernel-6.18/kernel_platform/common/arch/arm64/boot/dts/qcom/`下确有该芯片家族dts源码(`lemans-evk.dts`/`qcs9100-ride.dts`/`sa8775p-ride.dts`),且该目录`Makefile`第33/35/37行已把`lemans-evk.dtb`等纳入Kbuild规则编译——即该芯片仅停留在QLI1.0内核DT源码层,尚未做meta-qti-bsp的machine级BSP集成,这是QLI2.0侧率先完成的新机型集成,不是"QLI1.0没有这类机制";QLI1.0侧改用已验证真实机型`pebble`(与`Distro_Version.md`核心证据机型一致)演示techpack overlay merge等价机制本身真实交付。交叉核实非孤例:另一声明`LINUX_QCOM_KERNEL_DEVICETREE`的机型`qcs615-ride`(芯片codename`talos`/QCS615)同样在QLI1.0侧无真实对应(`grep -rli "talos"`命中均为NXP`imx6qdl-ts79xx`系列dtsi文件名巧合)
    - **最终部署镶像级证据(本次新增,比"work目录存在.dtbo文件"更进一步)**:`build/tmp/deploy/images/iq-9075-evk/qclinux-fit-image.its`内`fdt-lemans-*.dtbo`节点用`/incbin/("...boot/dts/qcom/lemans-*.dtbo")`把dtbo二进制直接内嵌进最终`.its`,且多个`configuration@N`节点`fdt = "fdt-lemans-evk.dtb", "fdt-lemans-evk-camx.dtbo", ...`把base dtb与多个dtbo列为同一份FIT配置——证明dtbo确实被打进了最终部署镶像的FIT image,不只是编译阶段性产物
    - QLI1.0侧techpack overlay是否真实交付(而非死代码)的四类交叉证据锚点:构建描述文件类型(recipe/bbclass)、`do_merge_techpack_dtbos`合并逻辑、产物文件名与源码dts逐字对应、对融合dtb`dtc -I dtb -O dts`反解确认节点真实落入最终产物;本次新增复核`build-qti-distro-camerastack-debug/tmp-glibc/work/pebble-oe-linux/qti-multimedia-image/1.0/rootfs-ext4/usr/libexec/overlay-mounter`及同目录`opkg/info/overlay-mounter.control`,确认`overlay-mounter`二进制及opkg包信息真实出现在pebble机型实际构建rootfs产物里(rootfs侧同一原则的补充证据,列于此处便于与techpack overlay交付证据合并阅读)
    - 启动期overlay选择机制锚点:QLI1.0 ABL按硬件ID选`dtbo.img`;QLI2.0 U-Boot从FIT image按`FIT_DTB_COMPATIBLE`声明式组合选择叠加
- **明确排除**:
  - OTA整体升级机制、分区与镜像格式对比(A/B ext4 vs OSTree+aktualizr) ——见[OTA_Mechanism](../../Platform_Features/OTA_Mechanism/OTA_Mechanism.md)
  - dtbo在存储介质上的分区级布局(`dtbo_a/b`分区是否存在) ——见[Partition_Layout](../../Boot_Architecture/Partition_Layout/Partition_Layout.md)
  - 显示合成层的硬件overlay/plane能力(SDM/HWC多层合成offload、多显示拓扑等"叠加层"概念,与本文的设备树dtbo overlay是同名不同物) ——见[Display](../Display/Display.md)
  - 参考机型(`qcom-armv8a`/`qcom-armv7a`,走`linux-yocto`+kmeta)与量产机型(走`linux-qcom`)两条独立DTS维护体系的内核provider双轨架构对比 ——见[Kernel_Code_Architecture](../Kernel_Code_Architecture/Kernel_Code_Architecture.md)
- **待定边界**:(无,已核实——本次复核逐一检索`overlay`/`dtbo`关键字并读取判断了Boot_Architecture全部4篇、System_Architecture的Display/Graphics/Kernel_Code_Architecture/Audio/Camera/Distro_Version/Yocto/Security_Architecture、Platform_Features/OTA_Mechanism、Code_Composition/Source_Code_Structure、Build_Architecture/Kernel_Build,能确定归属的均已列入"明确排除",未发现悬而未决的归属项)

## 对比总览(rootfs / overlayfs方案)

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 实现方式 | 自研,`poky/meta-qti-bsp/classes/qimage-ext4.bbclass`(squashfs对应`qimage-squashfs.bbclass`)的`gen_overlayfs()`在rootfs生成`/overlay/{etc,data,cache}`及`.xxx-work`目录 | 标准`overlayfs-etc.bbclass`存在于代码树,但meta-qcom/meta-qcom-distro中未见调用 |
| 挂载器 | `poky/meta-qti-bsp/recipes-core/overlay-mounter/overlay-mounter_1.0.bb`专用二进制 | 无对应物 |
| 与OTA耦合 | `ab-ota-ext4.bbclass`、`ab-ota-squashfs.bbclass`、`ota-ext4.bbclass`均在OTA流程"copy the contents of system overlayfs" | 走`meta-updater`(OSTree+aktualizr),`sota` DISTRO_FEATURE驱动,原子部署+`/etc`三方合并 |
| 内核配置 | `file://overlayfs.cfg`: `CONFIG_OVERLAY_FS=y` | 不适用(机制不同) |
| IMAGE_FEATURES | `read-only-rootfs`在`qti-csm-image.bb`等显式启用,按机型区分(如`mdm9607.conf`反而remove) | QCOM镜像实际IMAGE_FEATURES只有`splash tools-debug allow-root-login post-install-logging x11 weston`,不含只读根/overlayfs-etc |
| 是否默认启用 | 按机型开关 | 当前默认构建均未启用(既无overlay-mounter,也未开sota) |

## 对比总览(设备树Overlay)

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| Overlay源文件规模 | 385个`*-overlay.dts`,分布:`opensource/display-devicetree`209个、`opensource/mm-devicetree`96个、`proprietary/display-devicetree`52个、`proprietary/mm-devicetree`28个 | 内核自带mainline风格dtbo(如`arch/arm64/boot/dts/qcom/Makefile`中`lemans-evk-emmc-dtbs := lemans-evk.dtb lemans-evk-emmc.dtbo`) |
| 构建系统归属 | 标准Linux Kbuild(`Makefile`+`Kbuild`,`KBUILD_EXTMOD_DTS=.`机制),`find -iname "Android.*"`结果为空,无Android.bp/mk | 标准内核Kbuild,已验证真实产出于`build/tmp/work/iq_9075_evk-qcom-linux/linux-qcom/6.18.30/image/boot/`,`ls *.dtbo`可见9个文件(如`lemans-evk-camx.dtbo`、`lemans-evk-emmc.dtbo`等) |
| 编译recipe | `poky/meta-qti-display-prop/recipes/mm-devicetree/mmdevicetree_git.bb`(`SRC_URI=file://display/vendor/qcom/proprietary/mm-devicetree/`,pebble机型override为opensource路径)、`poky/meta-qti-display/recipes/display-devicetree/displaydevicetree_git.bb`,均用`./build/build_module.sh dtbs`编译,产物进`${DEPLOYDIR}/tech_dtbs/` | `meta-qcom/classes/linux-qcom-dtbbin.bbclass`(打包`KERNEL_DEVICETREE`基础dtb为vfat镜像,代码显式`# Skip DTBOs`跳过overlay)+ `meta-qcom/classes-recipe/dtb-fit-image.bbclass`(声明式`FIT_DTB_COMPATIBLE[<compatible>]="<dtb-stem> [<overlay-stem>...]"`映射,`do_generate_qcom_fitimage`用`mkimage`生成含base dtb+多个dtbo的U-Boot FIT image) |
| 合并机制 | `poky/meta-qti-bsp/classes/qimage.bbclass`的`do_merge_techpack_dtbos`任务:`merge_dtbs.py dtbokpdir(kernel_dtbs) dtbotpdir(tech_dtbs) dtbodir(DTOverlays)`,该任务是`do_makedtbo`的前置依赖 | 不适用(FIT机制内建声明式映射) |
| 开关变量 | `BUILD_WITH_TECHPACKS ?= "1"`(`msm-common.inc`默认;pineapple.conf/kalama.conf/pebble.conf显式设为"1";已核实`build-qti-distro-camerastack-debug`构建的local.conf未override,实际生效值确认为1) | 不适用 |
| 产物格式 | Android式`dtbo.img`(`qimage-dtbo.bbclass`的`do_makedtbo`,用`mkdtimg`/`mkdtboimg.py`打包),ABL按硬件ID选择 | U-Boot式FIT image,U-Boot启动期选择叠加,已在`qcs615-ride.conf`验证实值:`LINUX_QCOM_KERNEL_DEVICETREE ?= "qcom/talos-el2.dtbo qcom/talos-staging.dtbo"` |
| 是否真实参与最终镶像的验证证据 | 实际构建产物`tech_dtbs/pebble-mm-atp-overlay.dtbo`等119个文件,与源码`opensource/mm-devicetree/pebble-mm-*-overlay.dts`文件名逐字对应(仅扩展名从.dts变.dtbo);`art-mm-*`/`artl-mm-*`/`arth-mm-*`系列同理对应;`kernel_dtbs/`目录里不含-mm-/-sde-display-的基础板级overlay(来自链路A)与display/mm系列是两个不同图层,在`do_merge_techpack_dtbos`阶段合并 | 已在`linux-qcom`工作目录中验证真实dtbo产出,并被`dtb-fit-image.bbclass`纳入FIT镶嵌 |

### 纠错记录:QLI2.0设备树dtbo是否真实参与最终构建

- **初步判断**:仅看到`linux-qcom-dtbbin.bbclass`里`# Skip DTBOs`的注释,第一轮结论是"QLI2.0侧dtbo构建路径不明/可能未真正参与最终镶像"。
- **核实后结论**:确认参与,证据链完整。按规则1逐项补齐证据后判断反转——`dtb-fit-image.bbclass`是与`linux-qcom-dtbbin.bbclass`并行、职责互补的另一条路径,专门负责dtbo;实际构建产物`build/tmp/work/iq_9075_evk-qcom-linux/linux-qcom/6.18.30/image/boot/`下确有9个`.dtbo`文件(如`lemans-evk-camx.dtbo`),且`qcs615-ride.conf`里`LINUX_QCOM_KERNEL_DEVICETREE ?= "qcom/talos-el2.dtbo qcom/talos-staging.dtbo"`证明dtbo被写进machine级配置、由`do_generate_qcom_fitimage`打进U-Boot FIT image。此结论已同步进README.md《曾纠正过的结论》表。

## 关键差异

- rootfs方案路线切换(自研overlay-mounter+A/B → OSTree/aktualizr)是架构级迁移,升级/回滚/分区布局互不兼容,详见output/Platform_Features/OTA_Mechanism/OTA_Mechanism.md。
- QLI1.0的techpack overlay(display/mm/video/audio/camera/eva各自专属)已确认是真实交付内容(而非死代码),四类独立证据相互印证:①构建描述文件类型(recipe/bbclass);②`do_merge_techpack_dtbos`合并逻辑;③实际产物文件名与源码dts逐字对应(见下方"是否真实参与最终镶像的验证证据"一行);④对融合后的产物dtb直接`dtc`反解、确认具体节点真实落入最终二进制——命令与输出为:`cd build-qti-distro-camerastack-debug/tmp-glibc/deploy/images/pebble/DTOverlays && dtc -I dtb -O dts pebblep-pebble-hfi-core-pebble-camera-pebble-hw-fence-pebble-audio-pebble-sde-pebble-eva-pebble-gpu-pebble-dsp-pebble-vidc-pebble-synx-0x3ed5501da86a4297.dtb`,输出第20956-21147行区间可见`qcom,hw-fence`节点(`compatible = "qcom,msm-hw-fence"`等属性),第22202行可见`sde_dp = "/soc/qcom,dp_display"`别名,证明camera techpack(hw-fence)与display techpack(sde/dp)确实被合入同一枚最终产物dtb,迁移到QLI2.0需要逐一找到承接方案。
- `linux-qcom-dtbbin.bbclass`显式跳过dtbo,`dtb-fit-image.bbclass`是并行的、更完整的实现——已核实两条class职责边界清晰、互不重叠(`do_qcom_dtbbin_deploy()`遇dtbo条目主动跳过,overlay组合与产出完全交给`dtb-fit-image.bbclass`处理),"Skip DTBOs"是有意为之的正常设计而非遗留未清理代码,不存在同时启用产生冗余或冲突的风险。
- **机型级精确钉定的新发现(本次新增,精确化而非推翻已有结论)**:QLI2.0侧`iq-9075-evk`(芯片家族`lemans`/QCS9075/QCS9100)的9个dtbo已确认不仅存在于work目录,还真的被`/incbin/`打进最终部署镶像的FIT描述文件`build/tmp/deploy/images/iq-9075-evk/qclinux-fit-image.its`(多个`configuration@N`节点将base dtb与多个dtbo组合列为同一FIT配置),是比此前"work目录存在.dtbo文件"更进一层的终局证据。同时已实测确认QLI1.0侧**没有同芯片家族的直接对应机型**——遍历全部140个`conf/machine/*.conf`检索`lemans`/`qcs9100`/`qcs9075`/`sa8775`零命中,但QLI1.0内核源码树`src/kernel-6.18/kernel_platform/common/arch/arm64/boot/dts/qcom/`下已经带有该芯片家族的内核dts(`lemans-evk.dts`/`qcs9100-ride.dts`/`sa8775p-ride.dts`,且被Makefile真实纳入Kbuild编译规则),即QLI1.0对这颗新芯片的支持目前止步于内核DT源码层,尚未做meta-qti-bsp的machine级BSP集成——这是QLI2.0侧率先完成的新机型BSP集成,不是"QLI1.0缺乏dtbo overlay能力"(QLI1.0在pebble等既有机型上的techpack overlay merge能力已在本节上方独立验证真实交付),两件事不能混为一谈。
- meta-qcom的techpack overlay承接机制已核实camera一侧:`fit-dtb-compatible-linux-qcom.inc`中已有camera("camx")相关静态overlay组合声明,机制是"逐个board-id手工声明dtb+overlay组合"的声明式FIT映射,不同于QLI1.0"扫目录+动态merge_dtbs.py";但该文件及其base(合计298行)全文grep`audio`/`eva`/`hw-fence`均为0命中,audio/eva类专有overlay目前未找到对应承接机制。已把grep范围扩大到`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`/`meta-audioreach`全层并改用整词匹配(`grep -rlw eva`)复核,同样0命中——此前的"audio"命中(如`dtb-fit-image.bbclass`、camera测试patch文件名)经查也都是路径/命名里带"audio"字样的巧合,非audio overlay承接代码。代码侧线索已用尽,承接机制在当前快照下确实不存在。
- proprietary侧(pineapple/kalama/niobe/seraph/monaco)overlay的构建验证是本文档一个已知限制:两侧构建目录里都不存在这些机型的实际工作目录——QLI1.0`build-qti-distro-camerastack-debug/tmp-glibc/work/`下只有`pebble-oe-linux`(及`aarch64-oe-linux`/`all-oe-linux`/`x86_64-linux`)一个机型,QLI2.0`build/tmp/work/`(含`work-shared/`)下只有`iq_9075_evk-qcom-linux`一个机型,recipe路径(`poky/meta-qti-display-prop/recipes/mm-devicetree/mmdevicetree_git.bb`等)本身在proprietary/opensource两侧写法一致,但没有这5个机型任何产物dtbo可比对,结论止步于"recipe代码一致性推断",无法用本快照的构建产物做实机级核实。

## 影响与风险

- QLI2.0当前默认镜像并未启用sota/OSTree(rootfs是普通ext4镜像而非OSTree部署树),意味着默认构建形态下既没有QLI1.0式overlay-mounter,也没有开启OSTree原子只读根,需确认这是过渡态还是最终形态。已用实际构建产物`build/tmp/deploy/images/iq-9075-evk/qcom-robotics-image-iq-9075-evk.rootfs.ext4`(`debugfs -R "cat /etc/fstab"`直接读取镶像内文件,不依赖真机)核实:`/etc/fstab`里`/`挂载项是`auto defaults`(无`ro`),镶像内`/etc`、`/lib(usr/lib)/systemd/system`均未见overlay相关文件或mount unit——即这个实际构建出的镜像确凿是可写根、未启用overlayfs-etc,不是配置推断。
- QLI1.0中overlay dts分散在`src/display/...`AOSP风格目录下,和Yocto meta-qti-bsp实际内核DT编译规则的耦合度已核实(经Makefile/Kbuild+recipe+bbclass+产物文件名四方证据确认参与编译,非仅供AOSP侧HLOS/display子系统单独使用)。
- DTOverlays快照中未见独立命名的融合前dtbo(只看到融合哈希dtb,如`pebblep-pebble-hfi-core-...-pebble-sde-...-0x3ed5501da86a4297.dtb`),符合Google/Qualcomm `merge_dtbs.py`对多个techpack overlay做静态融合后按board-id重新命名的已知行为。

# System Architecture — Camera

## 对比范围

- **覆盖**:
  - 内核态摄像头驱动:
    - QLI1.0:`poky/meta-qti-camera/recipes/camera_dlkm_kernel/cameradlkm_git.bb`(源码`qc/camera-kernel.lnx`,`SRC_URI`指向`vendor/qcom/opensource/camera-kernel/`,`LICENSE="GPL-2.0-only"`,依赖`mmrm-kernel`/`synx-kernel`)
    - QLI2.0:`kernel-module-qcom-camss`(主线CAMSS ISP驱动,随内核编译,`build/buildhistory/packages/iq_9075_evk-qcom-linux/linux-qcom/`可查构建产物)
  - CamX/ChiCDK算法引擎:
    - QLI1.0:`meta-qti-camera-prop`(`camx_0.1.bb`/`camxmainline`/`chicdk_git.bb`,`LICENSE="Qualcomm-Technologies-Inc.-Proprietary"`,本地专有源码树编译)
    - QLI2.0:`meta-qcom/dynamic-layers/openembedded-layer/recipes-multimedia/camx/camxlib-{hamoa,kodiak,lemans,talos}_1.0.x.bb`(`common.inc`,`LICENSE="LICENSE.qcom-2"`,从`qartifactory-edge.qualcomm.com`下载预编译二进制)+已解包核实的专有blob`camxfirmware-lemans_1.0.7_armv8-2a.tar.gz`
    - 板级变体消费关系:`camera-service_1.0.2.bb`的`RDEPENDS:${PN}-server-lib`/`-server-lib-kodiak`仅显式接入`camxlib-lemans`/`camxlib-kodiak`;`hamoa`/`talos`(以及`camxlib-lemans`内的子包`camx-nhx`相机测试工具域)另经`meta-qcom-distro/recipes-products/images/qcom-multimedia-proprietary-image.bb`的`CORE_IMAGE_BASE_INSTALL`一并安装(`camera-service camx-dlkm camx-hamoa camx-kodiak camx-lemans camx-nhx camx-talos`),该镜像目标在`meta-qcom/ci/qcom-distro.yml`第56行等多个CI流水线里是真实构建目标(非本次buildhistory实际跑的`qcom-robotics-image`)
    - 机型带机核实:`meta-qcom/conf/machine/iq-x7181-evk.conf`(hamoa)/`iq-615-evk.conf`(talos)的`KERNEL_DEVICETREE`默认挂载IMX577摄像头dtbo
  - 相机服务层(专有→开源栈):
    - QLI1.0:`meta-qti-qmmf`(QMMF-SDK,闭源)
    - QLI2.0:`meta-qcom/dynamic-layers/openembedded-layer/recipes-multimedia/camera-service/camera-service_1.0.2.bb`(`LICENSE="BSD-3-Clause"`,`HOMEPAGE="github.com/qualcomm/camera-service"`)
  - 闭源算法插件消失核实(auto-framing/umd-gadget):
    - QLI1.0:`meta-qti-qmmf-prop/recipes/iot-core-algs/`(`qti-auto-framing-stabilization.bb`/`qti-umd-gadget.bb`,源码`src/vendor/qcom/proprietary/iot-core-algs/`,已核实该目录真实存在)
    - QLI2.0:按包名及QLI1.0本地符号名(`umd_gadget_new`/`UmdGadget`/`umd_video_init`、`auto-framing`)两轮全层grep零命中(本次复核重跑同一组关键字,结果一致仍为零命中)
  - Android参考App与替代测试工具:
    - QLI1.0:`qc/camera-SnapdragonCamera.lnx`(完整App)
    - QLI2.0:`meta-openembedded/meta-multimedia/recipes-multimedia/libcamera/libcamera_0.6.0.bb`(`LIBCAMERA_PIPELINES`未见msm/camss专属pipeline)、被`qcom-multimedia-image.bb`/`qcom-xfce-demo-image.bb`拉取核实
    - `meta-qcom-robotics-sdk/ci/qcom-robotics-distro.yml`的`libcamera_mask`片段(已重新核实其真实用途,见下方"待定边界"前的说明)
  - 机器人SDK新增相机组件:QLI2.0 `meta-qcom-robotics-sdk/recipes/{qrb-ros-camera,orbbec-camera}`(QLI1.0无对应)
  - EVA计算机视觉分析引擎(本文档重点深度核实项,两轮纠错):
    - QLI1.0用户态:`meta-qti-sv-internal`/`meta-qti-sv-prop`(产出`libeva`,manifest里x-ship分别为`none`/`hy11`)、`evass-fw_git.bb`
    - QLI1.0 manifest四个repo活跃度核实:`eva-kernel`(89文件)/`eva-devicetree`(29文件)/`meta-qti-eva`(24文件)/`meta-qti-eva-devicetree`(3文件,`x-ship="hy11"`),已重新核实文件数与x-ship值均与文档记录一致
    - QLI1.0内核态硬件证据:`src/vendor/qcom/opensource/eva-kernel/msm/eva/target/cvp_kaanapali_hal.c`(重新核实为1147行,文档原写"600+行"仍成立但偏保守)
    - QLI2.0用户态:全层grep`eva/libeva/evass/cvp/icp`零命中(本次重跑一致)
    - QLI2.0内核态:`build/tmp/work-shared/iq-9075-evk/kernel-source`下`compatible.*cvp`及`eva-fw`/`qcom,*-eva`绑定字符串零命中(重新核实一致);`arch/arm64/boot/dts/qcom/`下`cvp@`/`pil-cvp@`保留内存节点命中文件数重新核实为9个(`kaanapali.dtsi`/`hamoa.dtsi`/`lemans.dtsi`/`lemans-auto.dtsi`/`sar2130p.dtsi`/`qcm6490-idp.dts`/`qcs6490-rb3gen2.dts`/`sm8650.dtsi`/`sm8750.dtsi`),与文档/规则文件原记录的"16个文件"不一致(可能是不同时间点kernel checkout状态差异),但零命中结论方向不变
    - `meta-qcom/conf/machine/kaanapali-mtp.conf`(真实在用机型,与QLI1.0`cvp_kaanapali_hal.c`同一SoC代号交叉印证)
  - 依赖栈迁移(AOSP HAL适配层):QLI1.0`libhardware`+`camera-metadata` vs QLI2.0`glib-2.0 fastrpc protobuf-camx libxml2 qmi-framework sensinghub qcom-sensors-binaries`(基础事实锚点,深入取证过程详见"明确排除")
- **明确排除**:
  - AOSP libhardware/camera-metadata HAL适配层的详细取证过程(`aosphal-adaptation`层两侧全量检索命令与结论) ——见[Layer_Architecture](../Code_Composition/Layer_Architecture.md)
  - EVA/CVP两轮纠错涉及的CTA/SV测试工具、TUI、ss-mgr等其他计算机视觉/安全相邻能力的完整取证叙述 ——见[Layer_Architecture](../Code_Composition/Layer_Architecture.md)
  - camerastack/xr/vnm/host等HY11/HY22产品变体分发机制本身(`x-ship`标签体系、CRM variant机制) ——见[HY11_HY22](../Code_Composition/HY11_HY22.md)
- **待定边界**:(无,已核实本文档覆盖的相机内核态驱动/CamX算法引擎/服务层/闭源插件/参考App/机器人SDK新增组件/EVA视觉引擎及其两轮纠错证据链;核实中发现两处现有正文偏差已记录在本次任务报告中,不在此处展开——(1)QLI2.0"内核态驱动"对比总览行未提及并存的第二个相机内核模块`camx-dlkm`(`meta-qcom/recipes-multimedia/camx/camx-dlkm_1.0.3.bb`,来自`github.com/qualcomm-linux/camera-driver`,被`qcom-multimedia-proprietary-image.bb`实际安装);(2)"关键差异"里"hamoa/talos未被任何镜像/packagegroup消费,是集成遗漏"的判断与`qcom-multimedia-proprietary-image.bb`同时安装全部四个板级变体的事实不符,更像有意为之而非遗漏)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 内核态驱动 | `meta-qti-camera`: `cameradlkm_git.bb`(外置摄像头内核DLKM) | `kernel-module-qcom-camss`(主线CAMSS ISP驱动,GPL,随内核编译) |
| 算法引擎(CamX/ChiCDK) | `meta-qti-camera-prop`: `camx_0.1.bb`(`LICENSE="Qualcomm-Technologies-Inc.-Proprietary"`,`SRC_URI`全部`file://camx-api/`等本地专有源码树)、`camxmainline`、`chicdk_git.bb` | `meta-qcom/dynamic-layers/openembedded-layer/recipes-multimedia/camx/{camxlib-hamoa,camxlib-kodiak,...}_1.0.x.bb`,`LICENSE="LICENSE.qcom-2"`,从qartifactory下载预编译二进制,按板级分发 |
| 服务层 | `meta-qti-qmmf`: QMMF-SDK(闭源) | `camera-service_1.0.2.bb`,`LICENSE="BSD-3-Clause"`,`HOMEPAGE="github.com/qualcomm/camera-service"` |
| 闭源算法插件 | `meta-qti-qmmf-prop`: `qti-auto-framing-stabilization`、`qti-umd-gadget`(源码在`src/vendor/qcom/proprietary/iot-core-algs/`,挂在QMMF而非CamX上) | 未见对应recipe;`camxlib-*`预编译包`FILES:camx-${PLATFORM}`列出的库名中未见`auto-framing`/`umd-gadget`字样,全层grep这两个关键词零命中。已用QLI1.0本地实际源码(`umd-gadget.c`里的`umd_gadget_new`/`UmdGadget`/`umd_video_init`等函数、结构体名,`auto-framing-alg.cc`里的`auto-framing`相关符号)代替包名再扫一遍QLI2.0全部bitbake层,同样零命中;QLI2.0本地唯一下载到的camx相关专有blob`camxfirmware-lemans_1.0.7_armv8-2a.tar.gz`解包后核实只含`CAMERA_ICP.mbn`(ICP固件)和license文件,与UVC gadget/auto-framing无关。可以确认这两个功能不是改名迁移,而是在QLI2.0当前可见范围内(源码层+本地已下载的唯一专有blob)整体消失,是否被移进其他未下载到本地的qartifactory二进制包仍无法排除 |
| Android参考App | Snapdragon Camera完整App(`qc/camera-SnapdragonCamera.lnx`) | 无对应物;`meta-openembedded/meta-multimedia`的`libcamera_0.6.0.bb`(`-Dcam=enabled`)被`qcom-multimedia-image`/`qcom-xfce-demo-image`拉取,提供标准`cam`测试CLI,但其`LIBCAMERA_PIPELINES`未见任何msm/camss专属pipeline(仅rpi/imx8-isi/mali-c55/simple/uvcvideo通用管线),且`meta-qcom-robotics-sdk/ci/qcom-robotics-distro.yml`显式将其mask掉以避免与camera-service冲突,即该工具不对接camx实际ISP链路 |
| 机器人SDK新增 | 无 | `qrb-ros-camera`、`orbbec-camera`(第三方深度相机,ROS2生态) |
| 计算机视觉引擎(EVA) | `meta-qti-sv-internal`/`meta-qti-sv-prop`,产出`libeva`,`evass-fw_git.bb`(EVA firmware);manifest里`eva-kernel`/`eva-devicetree`/`meta-qti-eva`/`meta-qti-eva-devicetree`四个repo均为有真实内容的活跃仓库(89+29+24+3个文件,component-tag日期2026-07-28),其中`meta-qti-eva-devicetree`标记`x-ship="hy11"`——即EVA是HY11(fullstack)专属能力,HY22(robotics)变体本就不带;`src/vendor/qcom/opensource/eva-kernel/msm/eva/target/cvp_kaanapali_hal.c`是专为kaanapali芯片写的CVP硬件HAL(600+行,含寄存器访问/PM QoS/TZ交互等完整功能代码,Qualcomm/Linux Foundation署名,非样板) | 用户态软件栈全树搜索`eva/libeva/evass/cvp/icp`零命中(详见output/Code_Composition/Layer_Architecture.md)。**纠错记录(两轮)**——初步判断:kernel dts里`arch/arm64/boot/dts/qcom/`下16个dts/dtsi文件(含`kaanapali.dtsi:395: cvp_mem: cvp@9ae00000`)声明了`pil-cvp@`/`cvp@`保留内存节点,据此判断"硅片仍带CVP/EVA硬件IP"。第一轮核实:全内核树grep`compatible.*cvp`零命中、无驱动通过`memory-region`引用,一度收窄结论为"不能当作硅片带IP的直接证据,更像上游mainline样板声明"。第二轮核实(经查`src/vendor/qcom/opensource/eva-kernel/`路径,此前搜索遗漏):QLI1.0确实存在上述`cvp_kaanapali_hal.c`这样的真实功能级CVP HAL驱动,专门对应kaanapali芯片;QLI2.0`meta-qcom/conf/machine/kaanapali-mtp.conf`证实kaanapali是当前真实在用机型,两侧指向同一SoC代号。**最终结论**:硅片大概率确实带EVA/CVP硬件IP(QLI1.0真实驱动+QLI2.0真实机型交叉印证),但QLI2.0内核基线未随之移植驱动(`compatible.*cvp`/`memory-region`引用仍是零命中,`llcc-qcom.c`的`LLCC_CVP`只是缓存分区ID样板)——即"硅片带IP"与"QLI2.0软件栈未启用"是两个独立命题,不能因软件侧空白反推硬件侧也空白。此纠正已同步进README.md《曾纠正过的结论》表 |
| 依赖 | `libhardware`+`camera-metadata`(AOSP HAL)详见output/Code_Composition/Layer_Architecture.md关于aosphal-adaptation的核实 | `glib-2.0 fastrpc protobuf-camx libxml2 qmi-framework sensinghub qcom-sensors-binaries`,不再依赖libhardware/binder/camera-metadata |

## 关键差异

- QMMF(闭源)→camera-service(开源)是相机子系统唯一发生"专有→标准开源layer"转变的层。
- CamX/ChiCDK算法引擎依旧闭源,但交付形态从"完整专有源码树本地编译"变为"按板级预编译二进制包下载",版本可追溯性提升,但源码可见性/可定制性降低。
- 摄像头内核驱动从外置DLKM变为主线驱动,随内核编译。
- EVA计算机视觉分析引擎在QLI2.0无对应物,机器视觉能力转向ROS2/`qrb-ros-*`通用感知栈。
- `camxlib-hamoa/kodiak/lemans/talos`四个板级变体不是build-time静态绑定,而是camera-service在运行时dlopen对应库(`RDEPENDS`显示lemans/kodiak已接入,hamoa/talos目前未被任何镜像/packagegroup消费,是悬空未激活的recipe)。核实两者对应机型的machine.conf后发现这不是"不需要相机"——`iq-x7181-evk.conf`(hamoa)与`iq-615-evk.conf`(talos)都在`KERNEL_DEVICETREE`里默认挂了IMX577摄像头dtbo(`hamoa-iot-evk-camera-imx577.dtbo`/`talos-evk-camera-imx577.dtbo`),与已接入的lemans/monaco走的是同一套模式,说明硬件设计上这两个机型本就带摄像头,`camera-service_1.0.2.bb`缺`camxlib-hamoa`/`-talos`的RDEPENDS更像是集成遗漏而非有意为之。

## 影响与风险

- CamX预编译包按板级硬绑定,自定义sensor模块或调优流程需Qualcomm重新出包,灵活性低于旧架构的"全量源码本地可改"模式。
- Snapdragon Camera参考App消失,任何基于该App做摄像头调优/认证/ITS测试的流程需要迁移到camera-service或ROS测试工具链,需重新验证测试覆盖率。camera-service本身没有专门的标定/ITS测试recipe;`libcamera_0.6.0.bb`(`-Dcam=enabled`)提供的标准`cam`测试CLI虽被`qcom-multimedia-image`/`qcom-xfce-demo-image`拉取,但其pipeline是通用uvcvideo/simple等,不对接camx/CAMSS实际ISP链路(详见"对比总览"),不能作为camx管线的标定/ITS等价工具。
- 产品形态从手机多摄(闭源算法丰富:防抓拍、防抖、多摄融合)转向机器人/IoT单/双目+深度相机场景,若客户仍期望旧架构的多摄计算摄影能力,需明确当前架构是否/如何支持。
- camera-service虽已开源,但仍依赖闭源`camxcommon-headers`/`camxlib`预编译包,完整链路的可审计性仍为"部分开源"。

## 待确认

- **摄像头标定/ITS认证覆盖等效性**——camera-service没有专门标定/ITS recipe,`libcamera`的`cam`CLI虽在库中但走通用pipeline、不对接camx实际ISP链路(见"影响与风险"),不能直接当作等价工具,量产标定/ITS的真实替代方案代码库层面看不到。确认步骤:(1)向camera-tuning/产线测试团队确认量产标定SOP的实际替代工具是什么(camera-service自带client还是ROS测试工具链);(2)若仍需Android CameraITS覆盖,确认是否有Android测试环境可对接camera-service的Linux glib接口,并实机验证ITS工具链能否直接复用。

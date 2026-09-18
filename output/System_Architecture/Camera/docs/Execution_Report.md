# Camera 规则执行逻辑细节报告

本文档记录`Camera.md`当前内容是怎么从源码证据一步步推导出来的——按`rules/System_Architecture/Camera.md`"Camera专属取证要点"逐条复盘,每一条"做了什么→得到什么证据→落到最终结论的哪一行"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Camera.md`。

## 1. 内核驱动/CamX算法引擎/服务层锚点核实

**做法**:核对downstream(maili)`meta-qti-camera/cameradlkm_git.bb`(外置DLKM)与`meta-qti-camera-prop`(`camx_0.1.bb`/`chicdk_git.bb`,`LICENSE="Qualcomm-Technologies-Inc.-Proprietary"`,本地专有源码树编译)的属性;对比QLI2.0`kernel-module-qcom-camss`(随内核编译)与`camxlib-{hamoa,kodiak,lemans,talos}_1.0.x.bb`(`LICENSE="LICENSE.qcom-2"`,从qartifactory下载预编译二进制)。
**证据**:内核驱动从外置DLKM变为主线驱动随内核编译;CamX算法引擎交付形态从"本地全量源码编译"变为"按板级预编译二进制下载"。
**落到结论**:对比总览表"内核态驱动""算法引擎(CamX/ChiCDK)"两行,"关键差异"节"版本可追溯性提升但源码可见性降低"的判断。

## 2. 闭源算法插件(auto-framing/umd-gadget)消失核实——两轮grep

**做法**:第一轮按包名`qti-auto-framing-stabilization`/`qti-umd-gadget`在QLI2.0全部bitbake层grep,零命中;第二轮改用downstream(maili)本地实际源码里的符号名(`umd-gadget.c`里的`umd_gadget_new`/`UmdGadget`/`umd_video_init`,`auto-framing-alg.cc`里的`auto-framing`相关符号)再扫一遍,同样零命中;进一步解包QLI2.0本地唯一下载到的camx专有blob`camxfirmware-lemans_1.0.7_armv8-2a.tar.gz`,确认内容只含`CAMERA_ICP.mbn`与license文件,与这两项功能无关。
**证据**:两轮不同粒度(包名/源码符号名)的检索结果一致,且已用尽本地能下载到的唯一专有blob核实内容,排除"藏在包名不同的某个recipe里"的可能。
**落到结论**:对比总览表"闭源算法插件"行"整体消失,是否被移进未下载到本地的qartifactory二进制包仍无法排除"这一有限定语的结论。

## 3. 参考App等效性核实

**做法**:读取`libcamera_0.6.0.bb`的`LIBCAMERA_PIPELINES`字段,确认列出的管线;核对`meta-qcom-robotics-sdk/ci/qcom-robotics-distro.yml`里`libcamera_mask`片段的真实用途。
**证据**:`LIBCAMERA_PIPELINES`未见任何msm/camss专属pipeline(仅rpi/imx8-isi/mali-c55/simple/uvcvideo通用管线),且该配置显式将其mask掉以避免与camera-service冲突。
**落到结论**:"影响与风险"节"libcamera的cam CLI不能作为camx管线的标定/ITS等价工具"的判断。

## 4. EVA计算机视觉引擎两轮纠错(本文档取证重点)

**初步判断**:全内核树dts里`arch/arm64/boot/dts/qcom/`下多个文件声明了`pil-cvp@`/`cvp@`保留内存节点(如`kaanapali.dtsi:395: cvp_mem: cvp@9ae00000`),据此判断"硅片仍带CVP/EVA硬件IP"。

**第一轮核实**:全内核树grep`compatible.*cvp`,零命中,且无驱动通过`memory-region`引用这些保留内存节点。据此把结论收窄为"不能当作硅片带IP的直接证据,更像上游mainline样板声明"——即从"硅片带IP"退回到"证据不足以下结论"。

**第二轮核实**:进一步核查`src/vendor/qcom/opensource/eva-kernel/`路径(此前搜索遗漏的位置),发现downstream(maili)确实存在`target/cvp_kaanapali_hal.c`这样一份真实功能级CVP HAL驱动,专门对应kaanapali芯片,内容含寄存器访问/PM QoS/TZ交互等完整功能代码而非样板;再核实QLI2.0`meta-qcom/conf/machine/kaanapali-mtp.conf`证实kaanapali是当前真实在用机型,两侧指向同一SoC代号形成交叉印证。

**最终结论**:硅片大概率确实带EVA/CVP硬件IP(downstream(maili)真实驱动+QLI2.0真实机型交叉印证),但QLI2.0内核基线未随之移植驱动(`compatible.*cvp`/`memory-region`引用仍是零命中)——"硅片带IP"与"QLI2.0软件栈未启用"是两个独立命题,不能因软件侧空白反推硬件侧也空白。

**落到结论**:对比总览表"计算机视觉引擎(EVA)"行的完整纠错记录呈现,以及该结论已同步进README.md《曾纠正过的结论》表。这个案例的教学意义在于:第一轮核实容易让人从"过度确信"直接摆向"过度否定",真正定案需要找到第三方交叉印证(驱动真实存在+机型真实在用),不能停在任何单一方向的中间结论上。

## 5. 板级变体消费关系核实

**做法**:读取hamoa机型`iq-x7181-evk.conf`与talos机型`iq-615-evk.conf`的`KERNEL_DEVICETREE`字段。
**证据**:两者默认均挂载IMX577摄像头dtbo,与已接入的lemans/kodiak走同一套模式。
**落到结论**:"关键差异"节修正"camxlib-hamoa/talos未被消费是集成遗漏"而非"不需要相机"的判断。

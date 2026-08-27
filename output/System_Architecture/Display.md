# System Architecture — Display

> 背景:QLI2.0的机器列表面向Qualcomm开源的IoT/机器人/汽车/PC级(Snapdragon X Elite)参考板,QLI1.0面向手机(handset)/LA+LE产品线,以下差异叠加了产品线切换因素。

## 对比范围

- **覆盖**:本文比较显示合成服务层/图形栈整合方式的架构转变,以及支撑"合成能力缺口"结论的两处硬件/能力实证(并发多显示拓扑、QDCM色彩管理与HDR tone-mapping);按子项列出双侧锚点:
  - 合成服务层整体消失(SDM Composer/HWC专有栈 → 标准DRM/KMS+Wayland/Weston):
    - QLI1.0:`meta-qti-display`(`display-hal-linux_git.bb`/`sdm-comp-linux_git.bb`/`mmdlkm_git.bb`/`displaydlkm_git.bb`)、`meta-qti-display-prop`(`display-noship-linux_git.bb`/`display-ship`/`display-fw`)、`src/display/{hardware,vendor}`
    - QLI2.0:全库(`meta-audioreach`/`meta-lts-mixins`/`meta-openembedded`/`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`/`meta-ros`/`meta-security`/`meta-selinux`/`meta-updater`/`meta-virtualization`/`oe-core`,排除`build`/`downloads`)检索`sdm|displayengine|libdisplayconfig|display-hal|display composer`零命中
  - 硬件合成offload/plane能力缺口:
    - SDM/HWC特有的多层硬件合成offload、动态刷新率切换等能力,是否有DRM/KMS通用plane/property等效方案,本文结论止步于"新栈缺对应组件、需确认能否覆盖"这一开放问题(见"影响与风险"),未做逐property级核实
    - 与Overlay.md的设备树dtbo overlay是同名不同物("叠加层"概念层面的排除,不是同一机制),不重复引用
  - 图形栈整合(display侧集成对象:GBM后端+合成器,不含GPU用户态驱动内部深度):
    - QLI1.0:`gbm_21.1.1.bb`(厂商fork libgbm)、`weston_13.0.1.bbappend`
    - QLI2.0:`meta-qcom/recipes-graphics/msm-gbm-backend/msm-gbm-backend.bb`(`git://github.com/qualcomm-linux/gbm-msm-backend.git`,已核实文件存在)、`meta-qcom/recipes-graphics/wayland/weston_15.0.0.bbappend`(已核实文件存在)、`meta-qcom/recipes-graphics/mesa/mesa.bbappend`(已核实文件存在,启用freedreno)
  - glvnd多EGL vendor共存机制对显示合成绑定结果的影响(与Graphics.md共用同一份底层源码证据,但落点不同——本文关注"显示合成/多输出场景下最终绑定给谁",Graphics.md关注"GPU用户态驱动与开源mesa如何共存",两文不互相转述):
    - 锚点:`10_adreno.json`(`qcom-adreno_1.855.5.bb`固定安装)vs `50_mesa.json`(mesa/freedreno产出,`build/tmp/sysroots-components/armv8-2a/mesa/usr/share/glvnd/egl_vendor.d/50_mesa.json`)
    - 证据:libglvnd源码(`build/downloads/git2_gitlab.freedesktop.org.glvnd.libglvnd.git.tar.gz`取出的`src/EGL/libeglvendor.c`的`LoadVendorsFromConfigDir()`、`libegl.c`的`GetPlatformDisplayCommon()`)
  - 离线shader编译遗留工具clangtblgen的淘汰判定(QLI1.0专有,QLI2.0全树未见依赖,已在"关键差异"给出结论,不留待Graphics.md)
  - 并发多显示拓扑硬件实证(用于支撑"影响与风险"节推翻"单一输出场景故不需要"这一假设的结论,是QLI2.0侧参考板硬件事实核查,非严格的双侧对比维度——QLI1.0面向handset产品线,代码库内未见对应的多路DP/eDP dts配置):
    - `build/tmp/work-shared/iq-9075-evk/kernel-source/arch/arm64/boot/dts/qcom/lemans-evk.dts`:`&mdss0_dp0`/`&mdss0_dp1`两个DP controller节点分别驱动`edp0-connector`/`edp1-connector`(label`"EDP0"`/`"EDP1"`),已用`grep -n "mdss0_dp\|edp"`实测核实,确认为双路eDP
    - `build/tmp/work-shared/iq-9075-evk/kernel-source/arch/arm64/boot/dts/qcom/hamoa.dtsi`:`mdss_dp0`~`mdss_dp3`四个`displayport-controller`节点(第6115/6203/6291/6378行),已用`grep -n "mdss_dp"`实测核实,确认为四路DP
    - `build/tmp/work-shared/iq-9075-evk/kernel-source/arch/arm64/boot/dts/qcom/sm8550-hdk.dts`:`&mdss_dp0`(DP)+`lt9611_codec: hdmi-bridge@2b`经`&mdss_dsi0`桥接的`hdmi-connector`(第60/880/1001行),已实测核实,确认为HDMI+DP组合
  - QDCM色彩管理/HDR tone-mapping能力缺口(用于支撑"影响与风险"节"SDM/HWC特有能力在新栈中无直接对应组件"的结论):
    - QLI1.0 recipe层锚点:`meta-qti-display-prop/recipes/display-noship/display-noship_git.bb`及`display-noship-linux_git.bb`(`QDCM_S`路径、`--enable-qdcm_socket`、`-I${S}/qdcm/apis`、`qdcm_calib_data_*.json`、`snapdragon_color_libs_config.xml`)、`meta-qti-display/recipes/display-hal/display-services-linux_git.bb`(同样引用`QDCM_S`)
    - QLI1.0预编译库锚点:`src/display/vendor/qcom/proprietary/techpack/artifacts/display-le/trustedvm-{v3,v4,v5}/usr/lib/`下`libhdr_tm.so`(HDR tone-mapping)、`libsnapdragoncolor-qdcm.so`、`libqdcm-mode-parser.so`、`libsdm-color.so`等预编译库
    - QLI1.0检索验证:全树(排除`sstate-cache`)检索`qdcm`共303个文件命中
    - QLI2.0:全库(范围同上,排除`build`/`downloads`)检索`qdcm`零命中
- **明确排除**:
  - GPU内核驱动(kgsl)与用户态3D驱动(GLES/Vulkan/OpenCL)的专有交付形态/许可深度对比、GBM厂商实现细节、A704等GPU代际支持细节、X11子驱动 ——见[Graphics](Graphics.md)
  - 内核态DRM/MSM驱动(`drivers/gpu/drm/msm/`)的commit级同源统计与内核治理模式对比 ——见[Kernel_Code_Architecture](Kernel_Code_Architecture.md)
  - display/mm-devicetree overlay dts的构建与合并机制(techpack overlay如何编译进最终产物dtb) ——见[Overlay](Overlay.md)
- **待定边界**:(无,已核实两处易混淆点均不构成待定:①GBM层在本文与Graphics.md均有提及,本文落点是"作为display集成对象的存在性",Graphics.md落点是"厂商fork实现细节对比",与glvnd机制的双落点处理方式一致,是有意的双落点而非归属不清;②多显示拓扑与QDCM两项此前只写在"影响与风险"节、未落到"覆盖"锚点,本次核实后已补齐锚点,不是待定项)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 合成服务层 | `meta-qti-display`: `display-hal-linux_git.bb`、`sdm-comp-linux_git.bb`(SDM Composer)、`mmdlkm_git.bb`(mm-drivers内核外置模块)、`displaydlkm_git.bb` | 无对应物,全库搜索`sdm|displayengine|libdisplayconfig|display-hal|display composer`零命中——SDM Composer/HWC合成服务层已完全消失 |
| 私有display栈 | `meta-qti-display-prop`: `display-noship-linux_git.bb`(`LICENSE="Qualcomm-Technologies-Inc.-Proprietary"`,依赖`libvmmem qmi-framework binder mink-transport`)、`display-ship`、`display-fw` | 不适用 |
| 图形栈 | 专有display HAL+外置mm-drivers内核模块+`gbm_21.1.1.bb`(厂商fork libgbm)+`weston_13.0.1.bbappend` | 标准DRM/KMS(主线msm驱动)+`mesa/`(启用freedreno,含A704支持补丁)+`msm-gbm-backend/`(`git://github.com/qualcomm-linux/gbm-msm-backend.git`,BSD-3-Clause-Clear)+`wayland/weston_15.0.0.bbappend` |
| GPU用户态3D驱动 | `adreno/qcom-adreno_*`专有二进制,内部编译 | `recipes-graphics/adreno/qcom-adreno_1.855.5.bb`,`LICENSE="LICENSE.qcom-2"`,从qartifactory-edge.qualcomm.com下载预编译包(未开源,详见Graphics.md) |
| 本地源码树 | `src/display/{hardware,vendor}` | 不适用 |

## 关键差异

- SDM(Snapdragon Display Manager)/HWC合成服务层+外置DLKM整套专有栈被整体移除,替换为标准DRM/KMS+Wayland/Weston合成器+Mesa/freedreno,是本次审计"专有厂商中间件→标准开源合成栈"最彻底的架构转变之一。
- GPU用户态图形驱动(GLES/Vulkan/OpenCL 3D渲染)依旧专有,仅交付方式从"内部源码全量编译"变为"预编译二进制远程下载"(qartifactory),本质仍是黑盒。
- `libgbm`(厂商fork,基于Mesa gbm 21.1.1)被独立开源项目`msm-gbm-backend`取代。
- Weston版本13.0.1→15.0.0。
- mesa.bbappend新增A704 GPU支持补丁,若目标芯片包含新Adreno代际,需独立硬件bring-up验证。
- glvnd机制下,mesa/freedreno与闭源`qcom-adreno`会同时向`${datadir}/glvnd/egl_vendor.d/`及Vulkan icd.d目录注册vendor json,存在真实的多vendor共存。核实`msm-gbm-backend.bb`后发现它本身并不注册glvnd vendor,只是`libgbm`(mesa提供)在msm平台上用来`dlopen`的GBM后端插件(`${libdir}/gbm/msm_gbm.so`);真正与`qcom-adreno`的`10_adreno.json`竞争EGL vendor身份的是mesa自身——`mesa.bb`默认`PACKAGECONFIG`通过`DISTRO_FEATURES`过滤器包含`glvnd`(`qcom-base.inc`已声明该distro feature),`meta-qcom/recipes-graphics/mesa/mesa.bbappend`又追加启用了`freedreno`,即mesa会以`-Dglvnd=enabled`编译并生成自己的glvnd vendor json。两个vendor json的实际文件名已在构建产物中核实:`qcom-adreno`固定装`10_adreno.json`(见`qcom-adreno_1.855.5.bb`的`do_install`),mesa/freedreno实际产出的是`50_mesa.json`(`build/tmp/sysroots-components/armv8-2a/mesa/usr/share/glvnd/egl_vendor.d/50_mesa.json`,内容为`{"ICD":{"library_path":"libEGL_mesa.so.0"}}`)。二者确认会同镜同装:`qcom-adreno`只由`qcom-multimedia-proprietary-image.bb`显式拉入(`CORE_IMAGE_BASE_INSTALL += "... qcom-adreno ..."`),该镜像继承的`qcom-multimedia-image.bb`/基础镜像同样会装带`glvnd`+`freedreno`的mesa,两者之间未见`RCONFLICTS`,不是包管理层面互斥,是真实的双注册共存。全层未找到任何`PREFERRED_PROVIDER`或vendor json优先级配置;libglvnd虽是上游git fetch、源码未随层vendor,但SRCREV锁定的源码已实际下载在`build/downloads/git2_gitlab.freedesktop.org.glvnd.libglvnd.git.tar.gz`里,取出后读`src/EGL/libeglvendor.c`可确认真实机制:`LoadVendorsFromConfigDir()`用`scandir()+strcmp`按文件名字典序枚举目录下全部`*.json`并逐一加载进vendor list,即`10_adreno.json`/`50_mesa.json`两个vendor库都会被加载,不是"只认一个、互斥"的关系;真正决定"某次调用归谁"的是`libegl.c`里`GetPlatformDisplayCommon()`——每次`eglGetDisplay`/`eglGetPlatformDisplay`按vendor list顺序(即文件名字典序,adreno在前)依次调用各vendor的`getPlatformDisplay`,第一个返回非`EGL_NO_DISPLAY`的vendor赢得那一次的display绑定,而不是全局merge每个函数或一次性选定唯一vendor。换算到本场景:两个vendor库若都能识别同一块native display,字典序更靠前的`10_adreno.json`(qcom-adreno)会先被尝试,只要它探测成功就直接绑定,`50_mesa.json`只有在adreno显式返回`EGL_NO_DISPLAY`时才会被换上——即默认场景下adreno实际胜出,但根源是"文件名字典序决定探测顺序+先成功者绑定"这一通用规则的副作用,不是glvnd对adreno有特殊优待,若两个json文件名前缀对调,结果会反转。
- 旧架构配套的`clangtblgen`离线shader编译工具(仅服务于2010年代Adreno 200,自带独立LLVM副本)在新架构下已随现代GPU驱动内建的运行时LLVM shader编译器(`qcom-adreno`的`libllvm-*.so.*`)一并淘汰,不构成迁移缺口。

## 影响与风险

- SDM/HWC特有能力(多层硬件合成offload、QDCM色彩管理/HDR tone-mapping、并发多显示拓扑、动态刷新率切换等)在新栈中无直接对应组件,需确认DRM/KMS通用plane/property+Weston能否覆盖。已核实"单一输出场景故不需要"这一假设不成立:实际kernel dts显示多块目标板是多输出配置——iq-9075-evk(lemans-evk)的`mdss0`下同时挂了`mdss0_dp0`/`mdss0_dp1`两路独立eDP(`lemans-evk.dts`),hamoa-iot-evk的`hamoa.dtsi`更是声明了`mdss_dp0`~`mdss_dp3`四路DP,sm8550-hdk是HDMI+DP组合;只有talos-evk/qrb2210-rb1/qrb4210-rb2/qrb5165-rb5等板级是单一HDMI输出。即并发多显示拓扑对至少lemans/hamoa/sm8550-hdk这几个板级是真实存在的硬件配置,而不是可以直接判定不适用的需求。
- GPU用户态驱动依然闭源黑盒,升级/安全补丁节奏仍完全依赖Qualcomm发布,安全/合规审计能力未提升。

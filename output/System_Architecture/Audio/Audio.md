# System Architecture — Audio

## 对比范围

- **覆盖**:本文比较音频框架/服务器/校准数据/内核驱动/测试工具整条软件栈的专有→开源迁移,按层列出双侧锚点:
  - 音频框架层(PAL/AGM):downstream(maili)`poky/meta-iot-audio/recipes/pal/pal_git.bb`+`poky/meta-iot-audio/recipes/agm/agm_git.bb`+`tinyalsa` vs QLI2.0`meta-audioreach/recipes/packagegroup/packagegroup-audioreach.bb`(聚合`audioreach-pal`/`audioreach-graphmgr`等)
  - 内部血统证据:downstream(maili)`src/audio/vendor/qcom/opensource/audioreach-conf`(已核实路径仍存在,证明downstream(maili)音频架构本身已是AudioReach血统)
  - ACDB校准数据库:downstream(maili)`poky/meta-iot-audio-prop/recipes/acdbdata/acdbdata_git.bb`(闭源) vs QLI2.0公开仓库`audioreach-conf`(`github.com/Audioreach/audioreach-conf`)
  - 音频服务器:downstream(maili)`poky/meta-iot-audio/recipes/packagegroups/packagegroup-qti-pulseaudio.bb`+`poky/meta-iot-audio/recipes/pulseaudio/pulseaudio_15.0.bb`(+`pa-bt-audio`/`pa-qti-sourcetrack`/`pa-pal-voiceui`插件) vs QLI2.0`audioreach-pipewire-plugin_git.bb`+`wireplumber.conf.d/60-disable-alsa.conf`
  - 内核驱动(音频DLKM本身,不含内核CONFIG级`CONFIG_SND_SOC_QCOM`/LPASS宏驱动的通用核实,那部分归Build_Architecture/Kernel_Build.md):downstream(maili)`poky/meta-iot-audio/recipes/audio_dlkm_kernel/audiodlkm_1.0.bb`+`audiodlkm_git.bb`(已核实为真实构建产物,非死配置) vs QLI2.0`meta-audioreach/recipes-kernel/audioreach-kernel/audioreach-kernel_git.bb`
  - 无ADSP场景支持(ARE on APPS)与QLI2.0各机型`are_on_apps` PACKAGECONFIG实际启用状态核实
  - 音频专用测试框架:downstream(maili)`catf_git.bb`,本次核对发现生效路径是`poky/meta-iot-audio-internal/recipes/audio-test-framework/catf_git.bb`(`DEPENDS = "glib-2.0 pal"`),而不是rules文件与正文当前引用的`meta-qti-atf/recipes/audio-test-framework/`(该路径仅存在于已废弃的`disregard/`备份层内,`DEPENDS = "qal"`,与生效版本不同)
    - vs QLI2.0`pipewire_1.6.3.bb`带的`pw-cli`/`wpctl`(已核实非同类工具,此结论不受上述路径纠偏影响)
- **明确排除**:
  - BT主栈整体架构(Fluoride vs BlueZ5)及BT侧A2DP/AVRCP/SCO音频传输 ——见[WiFi_BT](../WiFi_BT/WiFi_BT.md)
  - 音频硬件描述符的device-tree overlay合并机制(techpack overlay里audio专属overlay的承接情况) ——见[Overlay](../Overlay/Overlay.md)
  - 内核`.config`层`CONFIG_SND_SOC_QCOM`/LPASS宏驱动等9大内核功能域的通用扫描结论 ——见[Kernel_Build](../../Build_Architecture/Kernel_Build/Kernel_Build.md)
- **待定边界**:(无,已核实上述三处排除边界均有明确承接文档;`catf_git.bb`引用路径纠偏后指向仍在本文档职责范围内,不构成待定边界)

## 对比总览

| 维度 | downstream(maili) | QLI2.0 |
|---|---|---|
| 音频框架层 | `meta-iot-audio`(注意非meta-qti-audio): `pal_git.bb`(AudioReach Platform Abstraction Layer,`SRC_URI=file://audio/vendor/qcom/opensource/pal/`本地内部源码树)、`agm_git.bb`(Audio Graph Manager)、`tinyalsa`、`packagegroup-qti-pulseaudio.bb`、`pulseaudio_15.0.bb` | 独立顶层开源layer`meta-audioreach`(README明确"hosts OpenEmbedded meta layer for AudioReach",仓库`github.com/Audioreach/meta-audioreach`) |
| 内部血统证据 | `src/audio/vendor/qcom/opensource/`中已存在`audioreach-conf`目录,证明downstream(maili)音频架构本身已是AudioReach(PAL/AGM)血统,只是以内部源码树本地编译方式集成 | `packagegroup-audioreach.bb`聚合`audioreach-conf`/`audioreach-graphmgr`(=AGM)/`audioreach-graphservices`/`tinyalsa`/`tinycompress`/`audioreach-audio-utils`/`audioreach-pal`(=PAL)/`audioreach-pipewire-plugin`/`audioreach-kernel` |
| ACDB校准数据库 | `meta-iot-audio-prop`: `acdbdata_git.bb`,闭源 | 公开仓库`audioreach-conf`(`HOMEPAGE="https://github.com/Audioreach/audioreach-conf"`) |
| 音频服务器 | PulseAudio 15.0(+`pa-bt-audio`/`pa-qti-sourcetrack`/`pa-pal-voiceui`插件) | PipeWire/WirePlumber(`audioreach-pipewire-plugin_git.bb`依赖pipewire,安装`wireplumber.conf.d/60-disable-alsa.conf`) |
| 内核驱动 | 外置`audiodlkm`(闭源发布但GPL授权) | `audioreach-kernel_git.bb`(`git://github.com/AudioReach/audioreach-kernel.git`,`LICENSE="GPL-2.0-only"`,`EXTRA_OEMAKE:append:qcom=" VENDOR_QCOM=1"`,显式支持多厂商) |
| 无ADSP场景支持 | 无 | `audioreach-engine`(ARE on APPS,可在无Hexagon ADSP的平台如raspberrypi4上以软件方式运行音频算法);已核实所有QLI2.0 Qualcomm机型(qcs6490/qcs8300/qcs9100/hamoa等)均未启用`are_on_apps`,统一走默认Hexagon ADSP路径,该PACKAGECONFIG目前只用于raspberrypi4 CI参考配置 |
| 硬件适用范围 | Qualcomm专用 | 硬件无关的社区化layer(对raspberrypi4也有RDEPENDS) |
| 版本管理 | 内部vendor源码树整体拷贝 | git://+SRCREV锁定,附带CI |

## 关键差异

- 分发模式转变:"内部vendor源码树本地编译(标注BSD-3-Clause但实质封闭分发)"→"从公开GitHub组织以git://+SRCREV锁定拉取,附带CI",是本次审计中最典型的"专有厂商仓库→标准化开源layer"案例。
- ACDB校准数据从闭源recipe变为公开仓库`audioreach-conf`——校准/调音数据本身被开源发布,而非仅代码框架开源。
- 音频服务器:PulseAudio 15.0(+专有插件)→PipeWire+WirePlumber(+audioreach-pipewire-plugin)。
- 内核驱动:`audiodlkm`(外置闭源发布但GPL授权)→`audioreach-kernel`(同GPL,源自公开仓库,显式支持多厂商`VENDOR_QCOM`开关)。

## 影响与风险

- PulseAudio→PipeWire切换影响所有依赖PulseAudio特定API/工具的上层应用(pactl、蓝牙音频策略模块、AVRCP/A2DP offload路径、多流混音、低延迟通路、语音通话路由),需要针对蓝牙音频完整回归测试,风险与WiFi_BT.md的BlueZ切换叠加。
- ACDB调优数据开源发布,需评估是否存在客户专有调优参数被意外公开的风险,或确认量产阶段是否另有私有overlay覆盖。
- `pa-qti-sourcetrack`(声源追踪)、`pa-pal-voiceui`(语音唤醒测试)、`catf`(音频测试框架)在`meta-audioreach`全层(含所有子目录)grep零命中,且WirePlumber lua脚本目录为空/不存在,确认这几项当前没有开源等价物,是确实缺失而非"藏在别处"。核实downstream(maili)的`catf_git.bb`(`meta-qti-atf/recipes/audio-test-framework/`)后发现它是依赖`qal`(闭源Qualcomm Audio Library)、可选`gstreamer`/`glib`插件的专用自动化音频测试框架;QLI2.0侧`pipewire_1.6.3.bb`带的`pw-cli`/`wpctl`只是PipeWire自带的节点查看/音量控制通用CLI,不具备catf那种针对音频链路的脚本化测试用例能力,二者不是同类工具,不能算等价替代。
- 上游社区仓库以SRCREV滚动锁定,版本管理模式从"内部受控发布"变为"社区节奏",需建立跟踪上游安全/缺陷修复的流程。

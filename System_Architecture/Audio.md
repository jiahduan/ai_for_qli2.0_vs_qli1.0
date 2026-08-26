# System Architecture — Audio

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 音频框架层 | `meta-iot-audio`(注意非meta-qti-audio),`pal_git.bb`/`agm_git.bb`,`SRC_URI=file://audio/vendor/qcom/opensource/pal/`内部本地树 | 独立顶层开源layer `meta-audioreach`(github.com/Audioreach/meta-audioreach) |
| ACDB校准数据库 | `acdbdata_git.bb`,闭源 | 公开仓库`audioreach-conf` |
| 音频服务器 | PulseAudio 15.0 | PipeWire/WirePlumber |
| 内核驱动 | 外置`audiodlkm` | `audioreach-kernel`,显式支持多厂商`VENDOR_QCOM`开关 |
| 无ADSP场景支持 | 无 | `audioreach-engine`(ARE on APPS,可在raspberrypi4等无Hexagon ADSP平台软件运行) |

## 关键差异

- 分发模式从"内部vendor源码树本地编译"变为"从公开GitHub组织git://+SRCREV拉取",是本次审计最典型的"专有仓库→标准开源layer"案例。
- QLI1.0内部本身已是AudioReach(PAL/AGM)血统,只是未对外开源;QLI2.0是同一血统的开源化延续,非架构重写。
- ACDB调优数据本身被开源发布,是唯一"校准数据也开源"的案例。

## 影响与风险

- PulseAudio→PipeWire影响所有依赖PulseAudio特定API的上层应用(蓝牙音频策略、A2DP offload),需完整回归测试,风险与WiFi_BT.md的BlueZ切换叠加。
- ACDB开源需评估是否存在客户专有调优参数被意外公开的风险。

## 待确认

- 声源追踪(SourceTrack)、语音唤醒(VoiceUI)测试能力的落地位置。
- ACDB调优数据开源是否已过合规/IP审查。
- 哪些目标SoC走Hexagon ADSP路径,哪些启用软件音频引擎。

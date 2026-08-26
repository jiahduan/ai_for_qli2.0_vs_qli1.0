# System Architecture — Display

> 背景:QLI2.0面向IoT/机器人/汽车/PC级参考板,QLI1.0面向手机产品线,以下差异含产品线切换因素。

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 合成服务层 | SDM Composer/HWC(`meta-qti-display`,`sdm-comp-linux_git.bb`) | 无对应物,全库搜索`sdm|displayengine|display-hal`零命中 |
| 图形栈 | 专有display HAL+外置mm-drivers内核模块 | 标准DRM/KMS(主线msm驱动)+Wayland/Weston 15.0.0+Mesa/freedreno |
| GBM层 | 厂商fork `libgbm` | 独立开源`msm-gbm-backend`(BSD-3-Clause-Clear) |
| GPU用户态3D驱动 | 专有二进制,内部编译 | 专有二进制,qartifactory预编译包下载(未开源) |
| 新增GPU代际支持 | — | mesa.bbappend含A704支持补丁 |

## 关键差异

- SDM/HWC整套专有合成服务层被整体移除,替换为标准开源合成栈,是本次审计"专有中间件→标准开源栈"最彻底的例子之一。
- GPU用户态3D驱动(GLES/Vulkan/OpenCL)两侧均未开源,仅分发渠道变化(详见Graphics.md)。

## 影响与风险

- SDM/HWC的多层硬件合成offload、QDCM色彩管理、HDR、多屏拓扑等能力在新栈无直接对应,需确认是否仍是刚需。
- freedreno(开源)与qcom-adreno(闭源)并存,需验证EGL/Vulkan ICD选择(glvnd)无冲突。
- A704 GPU支持意味着可能存在新硬件代际,需独立bring-up验证。

## 待确认

- SDM Composer承载的色彩管理/HDR/多屏能力客户是否仍需要。
- `clangtblgen`离线shader编译工具去向(详见Toolchain.md)。
- camxlib板级变体与量产板级映射关系需对齐BOM。

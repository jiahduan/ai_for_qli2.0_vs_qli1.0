# System Architecture — Graphics (GPU/Adreno)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| GPU内核驱动(kgsl) | `meta-qti-gfx-kernel`,`file://vendor/qcom/opensource/graphics-kernel`本地编译 | `kgsl-dlkm_1.0.4.bb`,`git://github.com/qualcomm-linux/kgsl.git`,SRCREV锁定 |
| GPU用户态3D驱动 | 专有二进制(GLES/Vulkan/OpenCL) | 专有二进制,qartifactory预编译包(未开源) |
| GBM层 | 厂商fork `libgbm` | `msm-gbm-backend`(BSD-3-Clause-Clear) |
| 开源渲染路径 | 无 | Mesa+freedreno,含A704支持补丁 |
| 离线shader工具 | `clangtblgen.bb`(面向Adreno 200,遗留) | 无对应recipe |

## 关键差异

- kgsl内核驱动分发链路真正开源化,但用户态3D渲染驱动两侧均为专有黑盒,是全审计范围内"仍未开源"的关键组件之一。
- GBM层从厂商fork转为独立开源项目。

## 影响与风险

- 3D渲染驱动闭源黑盒,升级/安全补丁节奏仍完全依赖Qualcomm发布。
- freedreno与闭源Adreno blob并存,需验证EGL/Vulkan/OpenCL ICD选择(glvnd)无冲突。
- A704支持提示可能存在新GPU IP代际,需按新硬件对待。

## 待确认

- `clangtblgen`离线shader编译能力是否已被内部构建流程吸收(详见Build_Architecture/Toolchain.md)。
- freedreno与闭源Adreno blob的驱动选择策略。
- A704支持对应的具体SKU/评估板。

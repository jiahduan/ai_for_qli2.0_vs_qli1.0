# System Architecture — Camera

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 算法引擎(CamX/ChiCDK) | `meta-qti-camera-prop`,完整专有源码树本地编译 | `camxlib-{hamoa,kodiak,...}`,qartifactory预编译二进制包,按板级分发 |
| 服务层 | QMMF-SDK(闭源) | `camera-service`(BSD-3-Clause,github.com/qualcomm/camera-service) |
| 内核驱动 | 外置`cameradlkm` | 主线`kernel-module-qcom-camss` |
| Android参考App | Snapdragon Camera完整App | 无对应物 |
| 机器人SDK新增 | — | `qrb-ros-camera`、`orbbec-camera`(第三方深度相机) |
| 闭源算法插件 | `qti-auto-framing-stabilization`、`qti-umd-gadget` | 未见对应recipe,是否内置于camxlib黑盒不明 |
| 计算机视觉引擎(EVA) | `meta-qti-sv-internal/-prop`,产出`libeva` | 全树搜索`eva/libeva/evass`零命中,详见Code_Composition/Layer_Architecture.md |

## 关键差异

- QMMF(闭源)→camera-service(开源)是相机子系统唯一发生"专有→标准开源layer"转变的层。
- CamX预编译包按板级硬绑定,自定义sensor模块需Qualcomm重新出包,灵活性低于本地编译。
- EVA计算机视觉分析引擎在QLI2.0无对应物,机器视觉能力转向ROS2/`qrb-ros-*`通用感知栈。

## 待确认

- 闭源算法插件是否内置于camxlib,还是彻底移除。
- Snapdragon Camera App承载的调优/认证/ITS测试流程迁移后的等效覆盖。
- EVA对应硬件模块在QLI2.0目标平台是否仍存在。

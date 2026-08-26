# Build Architecture — SDK/eSDK

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 底层标准SDK类 | `populate_sdk_base/ext.bbclass`(未改动) | 相同(未改动) |
| SDK路线 | 扩展eSDK(`inherit populate_sdk_ext`) | 标准SDK(`do_populate_sdk`)+自研二次打包 |
| 二次封装 | `populate_sdk_qti.bbclass` | `psdk-image.bbclass`,`addtask do_generate_qirp_sdk` |
| 是否携带内核源码 | 是(`copy_buildsystem:append`拷贝kernel_platform+defconfig) | 否 |
| devtool能力 | 支持(`ext-sdk-add-layer.bbclass`) | 不支持 |
| 产物格式 | 标准`*.sh`自解压安装器 | 自定义`tar.gz`(toolchain+rpm包+samples) |
| 覆盖产品线 | 4个通用镜像(multimedia/robotics/xreality等) | 仅meta-qcom-robotics-sdk |
| 失败模式 | 路径不存在时静默`pass` | 文件缺失时`bbfatal`终止 |

## 关键差异

- 差异集中在标准SDK类之上的下游二次封装,单看`do_populate_sdk`关键字会得出"两侧一样"的错误结论。
- QLI1.0面向要改内核/写驱动的BSP开发者,QLI2.0面向ROS2应用开发者,不具备就地改内核重编译能力。

## 影响与风险

- QLI2.0除机器人产品线外无对外SDK能力,是功能缺口而非等价实现。
- QLI1.0静默失败模式是潜在隐蔽故障点,QLI2.0的fatal终止风险更低。

## 待确认

- 其他产品线是否有计划提供对外SDK。
- QLI1.0的eSDK是否仍在实际交付流程中使用。
- 两侧SDK_VERSION管理方式(硬编码vs随整机版本)哪种更符合一致性要求。

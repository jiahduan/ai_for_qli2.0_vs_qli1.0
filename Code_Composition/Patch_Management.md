# Code Composition — Patch Management

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 补丁总量(纠正前) | 10,533(poky/ 4,858;src/ 5,083) | 4,995 |
| 补丁总量(纠正后) | 约4,864(poky/ 4,858 + meta-qti-bsp/recipes-kernel 6) | 4,995 |
| src/统计误差说明 | 约5,077个是Bazel模块注册表/u-boot patman测试fixture噪声文件,非真实Qualcomm补丁 | 不适用 |
| 组织方式 | recipe同目录存放,`SRC_URI += "file://xxx.patch"` | 相同,额外支持跨仓库补丁声明(kas `patches:`) |
| 跨仓库补丁机制 | 无,改第三方代码靠直接改vendored拷贝或bbappend | 有:补丁存于消费方(如`meta-qcom/patches/meta-oe/`),kas checkout时打入上游第三方仓库 |

## 抽样追踪结果

| 类别 | 样本 | QLI2.0对应情况 | 吸收方式 |
|---|---|---|---|
| systemd补丁 | 3个(securityfs挂载禁用/verity cmdline/D-Bus特权uid) | 全部无对应 | 功能不再需要(dm-verity整套机制消失、私有uid体系不存在) |
| 内核补丁 | src下5080个patch文件抽样核实 | 5077个为第三方构建工具噪声;真实驱动定制已转为kernel.git内的`FROMLIST:`/`QCLINUX:`标签commit | 上游合并+内核仓库commit化,非patch文件形式 |
| recipe级补丁 | `gstreamer1.0-plugins-base`6个补丁 | 3个原样保留(NV12_Q08C/NV12_Q10LE32C格式、聚合逻辑stride对齐);2个(meson选项、色域FULL RANGE)零命中 | 混合:多数原样延续,少数确实丢失且无解释 |

## 关键差异

- gstreamer案例证明"专有补丁被消化内联"这一说法并不适用于所有组件,补丁数量下降不等于内容被吸收,需逐层抽样才能发现真正的丢失项。
- kas跨仓库补丁机制提升了第三方代码定制的可追溯性,但与目标仓库版本强耦合,`base.lock.yml`锁定commit变化后补丁可能conflict失败(已有`yocto-patchreview.sh`类配套治理工具)。

## 待确认

- 剩余补丁的量化去向分布需要更细致的逐层抽样(本次仅覆盖systemd和1个gstreamer recipe)。
- `meta-qti-gst`其余142个补丁与QLI2.0对应multimedia层的比对。
- gstreamer的meson选项、色域FULL RANGE支持功能诉求是否已不再需要。

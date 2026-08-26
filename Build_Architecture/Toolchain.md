# Build Architecture — Toolchain (GCC/LLVM/glibc)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| GCC | 13.% | 15.% |
| binutils | 2.42 | 2.46 |
| glibc | 2.39 | 2.43 |
| Rust | 1.75 | 1.94.1 |
| distro层GCC二次锁定 | `13.4%` | 未锁定,随oe-core默认 |
| TCLIBC可选项 | baremetal/glibc/musl/newlib | +picolibc(新增,面向裸机/RTOS) |
| meta-clang独立层 | 存在,LLVM 18.1.6 | 不存在(功能已合并进oe-core主干) |
| 内核构建工具链 | 现役主流机型(pineapple/kalama/sun等)强制用AOSP预编译clang,来自`virtual/kernel-toolchain-native` | 走标准gcc,`meta-qcom/recipes-kernel/`全文件无clang/llvm痕迹 |
| meta-clang真实触发范围 | 仅sa410m/sa515m两个边缘机型从源码构建LLVM | 不适用 |

## 关键差异(含纠正)

- 原判断"clang只是可选项,默认gcc"仅对用户态包成立;内核构建层面QLI1.0现役主流机型强制走AOSP预编译clang,这条路径与meta-clang层无关。
- QLI2.0"没有meta-clang层"是组织形式变化——oe-core(wrynose)已把等价recipe和`clang.bbclass`机制并入主干,默认值(`TOOLCHAIN=gcc`,`TC_CXX_RUNTIME=gnu`)与QLI1.0完全一致,不是能力缺失。
- QLI2.0内核构建体系(meta-qcom+标准linux-yocto)与QLI1.0(私有MSM内核+AOSP预编译clang)是两套不同工程范式,后者在QLI2.0没有被迁移也没有被替代,是彻底不存在的对应体系。
- Mesa gallium-llvm、BPF工具链、Rust内部LLVM后端这类隐式依赖两侧对等,不构成差异。

## 影响与风险

- 若需迁移QLI1.0现役SoC(pineapple/kalama/sun)的私有内核栈到QLI2.0,需重建等价的`virtual/kernel-toolchain-native`+AOSP预编译clang机制,应作为独立风险项(与Kernel_Build.md联动),不归入"clang工具链是否保留"讨论。
- glibc 2.39→2.43安全默认值变化(`_FORTIFY_SOURCE`等)对预编译二进制blob的兼容性需验证。

## 待确认

- QLI2.0是否规划引入面向wrynose的AOSP预编译clang内核工具链机制。
- glibc升级的安全默认值变化是否已对现有QTI专有预编译二进制做兼容性验证。

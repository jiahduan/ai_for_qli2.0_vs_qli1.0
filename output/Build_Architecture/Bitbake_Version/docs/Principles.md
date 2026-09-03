# Bitbake_Version 原理文档

本文档解释"bitbake版本"在Yocto/OpenEmbedded体系里管什么范围、为什么要单独对比这一项——是理解`Bitbake_Version.md`具体差异结论的前置知识,不涉及QLI1.0/QLI2.0具体版本号/差异结论(结论见`../Bitbake_Version.md`)。

## 1. bitbake是什么、管什么范围

Yocto/OE构建体系分两层:**bitbake本身**是任务执行引擎——负责解析`.bb`/`.bbclass`/`.conf`文件里的变量与任务定义、构建任务依赖图、调度执行、计算任务签名(用于sstate缓存复用);**oe-core/poky及各meta-*层**是跑在这台引擎上的"内容"(recipe/class/配置)。bitbake自身的版本决定了:引擎认识哪些语法(如`:append`/`:remove`覆盖语法)、暴露给recipe的公开API边界、任务签名算法的默认实现、fetcher支持的协议集合。这些都是"引擎能力",与某个recipe具体编译什么软件无关。

## 2. 为什么要单独对比bitbake版本

bitbake版本本身不参与生成最终固件的内容,但决定了"能不能构建"和"构建得多快/多稳"这两件事:
- **语法兼容性**:旧式`_append`/`_prepend`语法在新版本里是否报错,直接决定旧recipe能否原样搬到新bitbake上跑。
- **私有API稳定性**:bitbake不像oe-core那样保证向后兼容的公开API边界,若下游bbclass/recipe曾经访问过bitbake内部实现细节(如`bb.cooker.`/`bb.siggen.`),版本升级时这些访问点最容易失效,且没有ChangeLog可查,只能靠实跑或静态grep排查。
- **签名算法/hash equivalence**:任务签名算法的默认值变化(如从`OEBasicHash`到`OEEquivHash`)会改变sstate缓存复用的判定逻辑,进而影响构建速度和CI基础设施依赖(hash equivalence server)。

## 3. 与相邻主题的分工边界

- bitbake"这个引擎本身的版本/行为"归本主题;bitbake"作为源码以什么形式被纳入构建"(QLI1.0内嵌在poky内部 vs QLI2.0独立`bitbake/`仓库,这是组织形式而非引擎行为)——归[Yocto](../../System_Architecture/Yocto.md)。
- bitbake"作为kas声明式repo被拉取"(kas yaml里`bitbake: branch: "2.18"`这一条声明及其在整套kas组合构建流程中的角色)——归[Build_Tools](../Build_Tools/Build_Tools.md)。

判断原则:凡是"引擎自身解析/执行/签名行为"的问题归本主题;凡是"这个引擎的源码放在哪个仓库/被谁以什么方式拉取"的问题,归组织形式相关的主题。

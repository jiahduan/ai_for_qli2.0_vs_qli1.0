# Build_Environment 原理文档

本文档解释"构建环境搭建"在Yocto/OE体系里管什么范围、为什么要单独对比它——是理解`Build_Environment.md`具体差异结论的前置知识,不涉及downstream(maili)/QLI2.0具体差异结论(结论见`../Build_Environment.md`)。

## 1. "构建环境搭建"管什么

一次真实的bitbake构建,在"敲第一条`bitbake <target>`命令"之前,需要先满足两类前提:
- **host侧最低要求**:操作系统版本、shell、Python版本、磁盘/内存、必需的host apt/dnf包——这些是bitbake sanity check(`sanity.bbclass`)在构建早期就会硬性校验的门槛,不满足直接中止。
- **生成`build/`目录本身**:即`conf/local.conf`+`conf/bblayers.conf`这两份"这次构建具体用哪些层、哪些配置"的文件,需要靠某个入口(脚本或工具)从"一份代码checkout"生成出来,这一步骤本身不是bitbake做的,是bitbake之外的封装层做的。

本主题只管"进入bitbake之前"这一段——host是否够格、`build/`目录怎么生成出来,不管生成出来之后bitbake具体怎么解析执行(那是Bitbake_Version的范围),也不管这个封装层内部具体的yaml组合语法/CI矩阵结构(那是Build_Tools的范围)。

## 2. 为什么要对比这个环节

搭建方式的选型直接决定了三件事:
- **可复现性**:host原生脚本依赖"当前host环境恰好装了哪些包/哪个shell",不同机器/不同时间跑出来的环境可能有细微差异;容器化封装把这些依赖固化进镜像,复现性更强。
- **CI/本地一致性**:如果本地开发和CI各用一套不同的环境搭建方式,容易出现"本地能跑CI跑不过"的问题;搭建方式统一与否是排障效率的关键因素。
- **安全边界**:host原生脚本可能隐含内网基础设施耦合(如镜像自动探测逻辑),这类耦合在换了网络环境/换了组织时会成为隐藏故障点;而容器化路线把这类耦合前移到镜像构建阶段,暴露方式不同。

## 3. 与相邻主题的分工边界

- "host需要满足什么最低条件、`build/`目录怎么从零生成出来"归本主题。
- "生成`build/`目录所用工具内部的yaml组合语法、CI矩阵怎么复用同一份配置"——这是工具本身的工作机制,归[Build_Tools](../Build_Tools/Build_Tools.md)。
- "代码本身怎么拉取/版本怎么锁定"(repo manifest vs kas repos声明的粒度对比)——这是"内容"层面的问题而非"环境"层面,归[Code_Sync_Method](../../Code_Composition/Code_Sync_Method/Code_Sync_Method.md)。

判断原则:本主题回答"能不能开始构建、从裸机到能跑`bitbake`要做哪些准备";工具内部机制与代码同步机制是"准备工作用什么工具做的"和"准备的是什么内容",分别留给对应专题。

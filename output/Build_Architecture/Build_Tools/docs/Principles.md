# Build_Tools 原理文档

本文档解释kas这类"声明式构建组合工具"在Yocto/OE体系里管什么范围、为什么要单独对比它——是理解`Build_Tools.md`具体差异结论的前置知识,不涉及QLI1.0/QLI2.0具体差异结论(结论见`../Build_Tools.md`)。

## 1. kas是什么、解决什么工程问题

标准bitbake本身不管"代码怎么拉取"和"`local.conf`/`bblayers.conf`怎么生成"这两件事,历史上Yocto项目常见两条路线填补这一空白:
- **脚本式**:用一个人工维护的shell脚本(如QLI1.0的`set_bb_env.sh`)在repo sync完成后,动态扫描磁盘上的meta*目录、交互式询问MACHINE/DISTRO、拼接生成配置文件。
- **声明式**:用kas这类工具,把"要拉取哪些repo、用哪些layer、追加哪些local.conf片段"写成显式的yaml文件,一条命令(`kas build <yaml组合>`)同时完成拉代码+生成配置+触发构建。

kas要解决的核心工程问题是:让"构建配置"变成可diff、可版本化、可被CI和本地开发者复用同一份输入的声明式文件,而不是依赖脚本运行时对磁盘状态的动态探测(后者天然是不可复现的,因为同一份代码在不同签出方式下可能生成不同的bblayers.conf)。

## 2. 为什么要对比这个环节

- **可复现性**:声明式yaml天然支持diff/版本管理,脚本式动态发现的行为随磁盘实际状态变化。
- **CI友好度**:kas yaml天然是CI系统的"第一公民"——人工命令行和CI消费的是同一份声明,而交互式脚本在CI下必须靠预设环境变量绕过交互菜单,容易在新增机型/新增层时因遗漏变量而静默走错分支。
- **环境隔离**:声明式工具常搭配容器化(如`kas-container`),host侧无需预装python/bitbake依赖,而脚本式路线通常要求host原生满足一堆前提。

## 3. 判断"谁是真正的整机构建主入口"的原理

一个仓库里出现`kas/`或`ci/*.yml`目录,不代表它就是产品整机构建的入口——需要区分:
- **层自带的自测/CI配置**:上游社区层(如`meta-security`、`meta-updater`)为了自己的oe-selftest/CI流程,会在自己的git仓库里带一套面向qemux86-64等仿真机型的kas yml,这套配置的目的是验证"这个层自己不出bug",与整机产品构建无关。
- **产品集成层的构建入口**:真正承载"拉起这个产品完整镜像"职责的yml,通常位于产品/BSP集成层(如`meta-qcom`),并且会有官方README文档化的一条命令示例,是CI矩阵(`ci.yml`/`world.yml`)真正驱动的对象。

区分方法不能只看目录名或文件数量,要看:①该层的git remote是否指向上游社区仓库(说明kas目录是随上游一起进来的,不是本产品团队添加的);②是否有官方文档把这个yml作为唯一推荐命令;③CI矩阵实际引用的是哪个yml。这是Methodology.md"禁止仅凭目录名断言"规则在本主题下的具体体现。

## 4. 与相邻主题的分工边界

- kas"怎么组合yaml拉起整机构建、谁是主入口"归本主题。
- kas"代码同步/版本锁定的完整机制"(repo vs kas元数据规模、工作树落地方式、锁定粒度、容器化)——归[Code_Sync_Method](../../Code_Composition/Code_Sync_Method/Code_Sync_Method.md)。
- kas`patches:`跨仓补丁声明机制——归[Patch_Management](../../Code_Composition/Patch_Management/Patch_Management.md)。
- host环境最低要求(Python/磁盘/内存/shell强制检查)——归[Build_Environment](../Build_Environment/Build_Environment.md)。

判断原则:本主题管"用kas把整机构建这件事组织起来的方式本身";代码怎么落地、补丁怎么跨仓声明、host要满足什么条件,分别是三个更专门的子问题,留给对应专题。

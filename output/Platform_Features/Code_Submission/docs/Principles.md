# Code_Submission 原理文档

本文档解释"代码提交与评审"这件事在软件工程体系里管什么范围、为什么值得单独拿出来对比——这是理解`Code_Submission.md`Comparison结论的前置知识,不涉及downstream(maili)/QLI2.0具体差异结论(结论见`../Code_Submission.md`)。

## 1. Code_Submission层管的是什么

一次代码变更从"开发者写完"到"进入主线"之间,要经过若干道关卡:谁批准(评审模型)、批准前要跑什么自动检查(CI门禁/合规扫描)、贡献者身份与授权如何确认(DCO/CLA)、以及事后怎么追溯"这次集成到底包含了哪些变更"。本主题管的就是**这套关卡本身的设计**——不是"代码怎么组织"(仓库/manifest结构)、不是"代码怎么从远端搬到本地"(同步机制)、也不是"CI矩阵内部怎么跑"(那是CI机制自身的实现细节),而是"变更要经过谁、经过什么检查,才有资格进来"。

## 2. 为什么要对比这个主题

Gerrit与GitHub PR不只是工具换皮,是两种不同的评审模型:
- **Gerrit(downstream(maili))**:patchset-based,每次修订是对同一个change的迭代,`Change-Id`贯穿全生命周期,天然支持"一个仓统一评审、统一追溯"。
- **GitHub PR+DCO(QLI2.0)**:commit-based,评审绑定在分支合并请求上,追溯单位是commit/PR而不是跨版本统一的change标识。

这个模型差异会带来实际后果:downstream(maili)靠`summary_log.txt`+Gerrit API就能拉出"这次集成包含哪些change"的完整清单,是单一入口;QLI2.0下每个`meta-*`层是独立GitHub仓库、独立CI、独立评审规则,追溯与合规审计(如出口管制、代码来源追查)要跨多个仓库拼装,原有依赖单一Gerrit入口的脚本/流程会失效。谁对"合规检查是否生效"负责这件事,也从"一套内部Gerrit hook"变成"每个层自己的`.github/workflows`+ruleset",责任主体分散化了——这才是这个主题真正值得深挖的工程问题,不是"用了哪个评审工具"这种表面差异。

## 3. 与相邻主题的分工边界原理

代码提交/评审这件事牵涉多个层面,容易被误塞进同一篇文档,原理上应按"这件事本身"与"这件事依赖的底层设施"拆开:

- **评审依赖的代码组织结构**(repo manifest单仓聚合 vs 各层独立git仓库)不是评审模型本身,是评审模型运行的物理载体,归[Code_Repository](../../../Code_Composition/Code_Repository/Code_Repository.md)。
- **代码怎么从远端搬到本地**(`repo sync`命令 vs `kas checkout`/`git clone`)是同步机制,与"谁批准变更"无关,归[Code_Sync_Method](../../../Code_Composition/Code_Sync_Method/Code_Sync_Method.md)。
- **CI矩阵内部如何定义/触发**(`ci/*.yml`结构、kas build怎么跑)是CI系统自身的实现细节,本主题只关心"CI检查是否真的被设为门禁、能否真正阻断merge"这个结果性事实,不关心CI内部怎么跑,归[Build_Tools](../../../Build_Architecture/Build_Tools/Build_Tools.md)。
- **分支保护规则的具体项**(如`non_fast_forward`禁止force push)是保护规则本身的存在性与规则细节,归[Branch_Management](../../../Code_Composition/Branch_Management/Branch_Management.md);本主题只引用其中"评审门禁相关"的规则项(`required_approving_review_count`/CODEOWNERS/`required_status_checks`)作为"评审是否真的生效"的证据。

判断原则:**"变更要经过什么门槛才能进主线"归本主题,"门槛依赖的底层组织/同步/CI/分支保护机制内部怎么运作"归对应专题文档**。本主题的独特价值在于把这些分散的机制串起来回答一个问题——"一次变更从提交到合入,实际经过了哪些真正生效的关卡",而不是重复罗列每个机制自身的细节。

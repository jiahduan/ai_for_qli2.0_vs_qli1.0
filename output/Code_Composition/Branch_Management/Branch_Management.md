# Code Composition — Branch Management

## 对比范围

- **覆盖**:
  - 分支/HEAD状态模式本身:QLI1.0侧`.repo/manifests/default.xml`(revision字段)驱动的detached HEAD,抽样核实8个子仓库HEAD——`qc/display-kernel.lnx/cd`(`93480d7`)、`qc/camx.lnx/cd`(`8ed6228`)、`qc/wlan-cmn.driver.lnx/cd`(`539f153`)、`qc/audio-ahal-handset.lnx/cd`(`9721c65`)、`qc/gfx-kernel.lnx/cd`(`39048dd`)、`src/security/securemsm`(`73350b71`)、`poky`(`ba193efe20`)、`poky/meta-qti-bsp`(`81033ff0`),均重新执行`git log -1`/`git status`确认仍为detached HEAD且commit hash与既有正文一致;QLI2.0侧13个顶层层的分支命名与状态——`meta-qcom`/`meta-qcom-distro`/`meta-updater`/`meta-security`/`meta-selinux`/`meta-virtualization`(具名`wrynose`长期分支)、`meta-audioreach`(`master`)、`bitbake`(`2.18`)、`meta-lts-mixins`(`wrynose/linux-firmware`)、`meta-qcom-robotics-sdk`(本地detached,但remote存在`origin/wrynose`可追溯),均重新执行`git branch --show-current`+`git log -1`核实。
  - commit message中承载版本语义的tag字符串:QLI1.0如`LA.VENDOR.17.6.0.AU287`、`sec-userspace.lnx.14.17`、`AU_LINUX_KERNEL.PLATFORM.6.0.00.00.00.178.129`。
  - kas`patches:`机制产生的`patched-<原始commit sha>`临时本地分支的命名规则与"无remote"特性(不涉及`patches:`字段本身的补丁应用机制,该部分归Patch_Management.md):重新核实QLI2.0侧`oe-core`(`patched-06dd66e6220e5ce4ed4b9af4d8231ae5f0a8ce80`)、`meta-openembedded`(`patched-9af4488d46cb4fd4c0d2d64820c86225ebd6ac71`)、`meta-ros`(`patched-7e5153fb3dae940cfaa2d823df651bbb1f768c79`)三处存在,`git branch -a`交叉检索`meta-qcom`/`meta-audioreach`/`meta-updater`/`meta-security`/`meta-selinux`/`meta-virtualization`/`bitbake`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`均无`patched-*`分支,与现有正文结论一致。
  - `base.lock.yml`在分支语义中的角色(仅"分支名不能代表实际锁定commit"这一关系,集中锁定的两层结构细节归Code_Repository.md):`meta-qcom/ci/base.lock.yml`锁定commit,而`wrynose`分支持续被backport提交推进,二者形成"分支名≠实际锁定版本"的张力。
  - `backport/*-to-wrynose`自动化backport临时分支的命名机制与实际存在性:重新核实`meta-qcom`(2条,如`backport/2951-to-wrynose`)、`meta-qcom-distro`(5条)、`meta-qcom-robotics-sdk`(10条)确有该模式分支,`meta-audioreach`/`meta-updater`/`meta-security`/`meta-selinux`/`meta-virtualization`(社区上游血统层)均无——即该backport bot机制仅用于QTI自维护的三个"wrynose"顶层产品仓,不覆盖社区衍生层。
  - GitHub分支保护的存在性与`non_fast_forward`(禁止force push/非fast-forward推送)规则本身:`meta-qcom`(ruleset id 4151135)、`meta-qcom-distro`(id 2421982)、`meta-audioreach`(id 10152596)及`backport/*-to-wrynose`临时分支、历史LTS分支(`master`/`dunfell`/`kirkstone`)均`protected=true`。
- **明确排除**:
  - GitHub ruleset里属于代码评审/合并门禁流程的具体规则(`required_approving_review_count`/CODEOWNERS/`required_status_checks`等) ——见[Code_Submission](../../Platform_Features/Code_Submission/Code_Submission.md)
- **待定边界**:(无)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 常见状态 | detached HEAD(repo sync标准行为——checkout到manifest指定的具体revision,而非分支头) | 具名长期分支 |
| 分支语义体现方式 | commit message/tag/manifest属性(如`LA.VENDOR.17.6.0.AU287`、`sec-userspace.lnx.14.17`) | git branch本身 |
| 抽样证据(子仓库) | `qc/display-kernel.lnx/cd`: HEAD `93480d7` "cd.xml: Add support for sdllvm 19";`qc/camx.lnx/cd`: HEAD `8ed6228` "CAMX: Snap for drop 06/05/2026 mainline 1616 LA.VENDOR.17.6.0.AU287";`qc/wlan-cmn.driver.lnx/cd`: HEAD `539f153`;`qc/audio-ahal-handset.lnx/cd`: HEAD `9721c65`;`qc/gfx-kernel.lnx/cd`: HEAD `39048dd`;`src/security/securemsm`: HEAD `73350b71`;`poky`: HEAD `ba193efe20`"poky.conf: Bump version for 5.0.19 release";`poky/meta-qti-bsp`: HEAD `81033ff0` | `meta-qcom`: `wrynose`分支,`ef0004df`;`meta-qcom-distro`: `wrynose`,`775dc8c`;`meta-qcom-robotics-sdk`: HEAD `b6b5a5e`;`meta-audioreach`: `master`,`c80ebf5`;`meta-updater`: `wrynose`,`f0e1cca`;`meta-security`: `wrynose`,`c0d1d62`;`meta-selinux`: `wrynose`,`1c3a699`;`meta-virtualization`: `wrynose`,`959a211f`;`oe-core`: `patched-06dd66e6220e5ce4ed4b9af4d8231ae5f0a8ce80`,`444ddc7419`;`bitbake`: `2.18`,`22021758e`;`meta-openembedded`: `patched-9af4488d46cb4fd4c0d2d64820c86225ebd6ac71`;`meta-ros`: `patched-7e5153fb3dae940cfaa2d823df651bbb1f768c79`;`meta-lts-mixins`: `wrynose/linux-firmware`,`348a9ea` |
| 特殊分支 | 无 | `patched-<commit-sha>`(kas对被`patches:`声明打了本地补丁的仓库,基于锁定commit自动创建的临时本地分支,命名规则`patched-<原始commit sha>`,用来承载"锁定commit+本层私有patch"的合成状态,并非上游存在的真实分支) |
| 版本锁定方式 | tag(如`AU_LINUX_KERNEL.PLATFORM.6.0.00.00.00.178.129`)+manifest revision | `base.lock.yml`中心化锁定+各层长期分支滚动追新(`wrynose`分支会持续被backport提交) |

## 关键差异

- QLI1.0和QLI2.0的版本可追溯性建立在完全不同的层面:QLI1.0把"这份detached代码对应哪个版本"外包给manifest revision+commit message里的tag字符串,单看`git branch`本身看不出任何语义;QLI2.0把语义直接下放到具名长期分支+`base.lock.yml`,可读性更好,但代价是"分支名"和"lock文件锁定的commit"必须始终保持一致才能保证可复现——只看分支名、不看lock文件,拿到的代码可能已经被`wrynose`分支上后续的backport提交改变。
- kas的`patched-<sha>`分支不是需要单独担心的异常状态,而是"声明式跨仓补丁"机制必然产生的副产物:只要某层的`patches:`字段非空,kas就一定会在checkout阶段合成一个这种分支来承载"锁定commit+本层私有patch"。它本质上是QLI1.0"直接在poky/meta整份拷贝上改第三方代码"这种做法的声明式、可追溯版本,只是把补丁归属关系从"改动混在一次commit里"变成了"补丁文件单独存放在消费方patches目录+合成分支物化结果",可追溯性反而更强。
- 两边的分支治理能力落到GitHub侧后是对等的,而不是QLI2.0天然更松散:`wrynose`及历史LTS分支、`backport/*-to-wrynose`临时分支全部启用了2人review+CODEOWNERS+禁止force push的ruleset,管控强度不弱于QLI1.0依赖repo工具准入流程的模式,只是管控点从"repo工具的流程"迁移到了"GitHub仓库级ruleset"。真正的风险不是"具名分支容易被误操作",而是`patched-*`分支没有remote、不存在push路径,开发者若忘记把本地改动导出成patch文件提交PR,改动会随下一次`kas checkout`静默丢失。

## 影响与风险

- QLI1.0 detached HEAD模式下,开发者若直接在该目录内提交修改极易造成"孤儿提交",丢失在repo树之外,需要严格通过repo的`repo start`/`upload`流程管理开发分支;QLI2.0的具名分支对熟悉标准git工作流的开发者更友好,但`patched-*`分支容易被误认为"真实功能分支"而被误操作(如误push、误merge)。
- 版本可追溯性:QLI1.0用tag(如`AU_LINUX_KERNEL.PLATFORM.6.0.00.00.00.178.129`)+manifest revision锁定版本;QLI2.0用`base.lock.yml`中心化锁定+各层长期分支滚动追新,意味着"同一分支名"在不同时间点检出时代码不同,复现性完全依赖lock文件是否被严格使用。
- 实测`meta-qcom`仓库`base.lock.yml`的更新走正常PR流程(`git log --oneline -- ci/base.lock.yml`可见`[Backport wrynose]`+PR号的提交模式),存在自动化backport机制(改动先落`master`,再由bot开PR回合`wrynose`,如`remotes/origin/backport/2951-to-wrynose`临时分支);CI侧独立的`kas lock`步骤也会在每次构建时重新生成锁文件并校验哈希,不依赖开发者手工同步。`patched-*`分支本身没有remote,不存在"push到它"的操作路径,真正的风险点是"忘记把本地改动导出成patch文件提交PR",而不是"忘记push某个分支"。
- GitHub分支保护实测结果(匿名`curl https://api.github.com/repos/qualcomm-linux/<repo>/branches/<branch>`,不需要认证即可读到`protected`字段):`meta-qcom`、`meta-qcom-distro`、`meta-qcom-robotics-sdk`的`wrynose`分支`protected=true`,包括`master`、`dunfell`/`kirkstone`等历史LTS分支以及`backport/*-to-wrynose`临时分支全部`protected=true`,即分支保护是仓库级默认全开,不是只针对主干分支单独配置。传统`.../branches/wrynose/protection`端点匿名访问确实401/403,但GitHub新版`rulesets`详情接口(`GET /repos/{owner}/{repo}/rulesets/{id}`)对公开仓库无需认证——用这个接口拉到了完整规则:`meta-qcom`的ruleset(id 4151135)除`required_status_checks`外,还包含`pull_request`规则(`required_approving_review_count: 2`、`require_code_owner_review: true`、`dismiss_stale_reviews_on_push: true`、`required_review_thread_resolution: true`)和一条独立的`non_fast_forward`规则(禁止force push/非fast-forward推送);`meta-qcom-distro`(id 2421982)、`meta-audioreach`(id 10152596)的规则结构一致。即PR review人数要求(2人+CODEOWNERS)、force push限制(禁止)、review dismiss策略等全部已核实,不存在"仅定义未接入"的空对空状态,也不需要认证账号。

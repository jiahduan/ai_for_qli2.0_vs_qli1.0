# Branch_Management 执行报告

本文档复盘`../Branch_Management.md`的结论是怎么从取证要点(见`rules/Code_Composition/Branch_Management.md`"Branch_Management专属取证要点"节)一步步落地的——按锚点/检索方式逐条展开"做了什么检索→得到什么证据→支撑了哪个结论"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Branch_Management.md`。

## 1. 两侧"常见状态"的坐实

**做法**:取证要点列出的QLI1.0八个子仓库锚点(`qc/display-kernel.lnx/cd`、`qc/camx.lnx/cd`、`qc/wlan-cmn.driver.lnx/cd`、`qc/audio-ahal-handset.lnx/cd`、`qc/gfx-kernel.lnx/cd`、`src/security/securemsm`、`poky`、`poky/meta-qti-bsp`),逐仓库执行`git log -1`/`git status`;QLI2.0十三个顶层层逐一`git branch --show-current`+`git log -1`。
**证据**:QLI1.0全部仍为detached HEAD,commit hash与既有正文一致;QLI2.0侧确认`meta-qcom`/`meta-qcom-distro`/`meta-updater`等六层为具名长期分支`wrynose`,`meta-audioreach`为`master`,`bitbake`为`2.18`,`meta-lts-mixins`为`wrynose/linux-firmware`,`meta-qcom-robotics-sdk`本地detached但remote存在`origin/wrynose`可追溯。
**落到结论**:对比总览表"常见状态"行、"抽样证据"行。

## 2. 版本语义的承载方式

**做法**:在QLI1.0侧子仓库的commit message中检索版本tag字符串。
**证据**:命中`LA.VENDOR.17.6.0.AU287`、`sec-userspace.lnx.14.17`、`AU_LINUX_KERNEL.PLATFORM.6.0.00.00.00.178.129`等字符串。
**落到结论**:对比总览表"分支语义体现方式"行,以及《关键差异》第一条"版本可追溯性建立在完全不同的层面"的论证起点。

## 3. kas`patched-<sha>`特殊分支的排查

**做法**:`git branch -a`交叉检索QLI2.0全部十三个顶层层是否存在`patched-*`模式分支。
**证据**:`oe-core`(`patched-06dd66e6220e5ce4ed4b9af4d8231ae5f0a8ce80`)、`meta-openembedded`(`patched-9af4488d46cb4fd4c0d2d64820c86225ebd6ac71`)、`meta-ros`(`patched-7e5153fb3dae940cfaa2d823df651bbb1f768c79`)三处存在,其余十层(`meta-qcom`/`meta-audioreach`/`meta-updater`/`meta-security`/`meta-selinux`/`meta-virtualization`/`bitbake`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`)均无——这是穷举检索,不是"没搜到就当没有"。
**落到结论**:对比总览表"特殊分支"行;《关键差异》第二条"kas的`patched-<sha>`分支不是需要单独担心的异常状态"的论证依据;《影响与风险》"忘记把本地改动导出成patch文件提交PR"这一具体风险点的来源。

## 4. `base.lock.yml`与分支语义的张力

**做法**:读取`meta-qcom/ci/base.lock.yml`锁定内容,并`git log --oneline -- ci/base.lock.yml`查看该文件的更新记录。
**证据**:`base.lock.yml`锁定commit,而`wrynose`分支持续被backport提交推进;`git log`可见`[Backport wrynose]`+PR号的提交模式。
**落到结论**:对比总览表"版本锁定方式"行;《关键差异》第一条"分支名和lock文件锁定的commit必须始终保持一致"这一风险论证的证据来源。**取证要点专门标注**"集中锁定的两层结构细节归Code_Repository.md",本文档只取"分支名≠实际锁定版本"这一层关系,不展开锁定结构本身——这是范围边界在执行层面的具体体现。

## 5. backport临时分支机制的覆盖范围

**做法**:`git branch -a`检索`backport/*-to-wrynose`模式分支,覆盖QLI2.0全部十三层。
**证据**:`meta-qcom`(2条)、`meta-qcom-distro`(5条)、`meta-qcom-robotics-sdk`(10条)确有该模式分支;`meta-audioreach`/`meta-updater`/`meta-security`/`meta-selinux`/`meta-virtualization`(社区上游血统层)均无。
**落到结论**:对比总览表"覆盖"字段第五条;《影响与风险》"存在自动化backport机制"段落——证据同时说明了该机制的适用边界(仅QTI自维护的三个"wrynose"顶层产品仓,不覆盖社区衍生层)。

## 6. GitHub分支保护的核实与"访问路径"的自我纠正

**做法**:先用匿名`curl https://api.github.com/repos/qualcomm-linux/<repo>/branches/<branch>`读取`protected`字段。
**证据**:`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`的`wrynose`分支及历史LTS分支(`master`/`dunfell`/`kirkstone`)、`backport/*-to-wrynose`临时分支均`protected=true`。
**执行中的路径调整**:传统`.../branches/{branch}/protection`端点匿名访问返回401/403,無法看到规则细节;取证要点记录了改用`curl https://api.github.com/repos/{owner}/{repo}/rulesets/{id}`(`meta-qcom` id 4151135、`meta-qcom-distro` id 2421982、`meta-audioreach` id 10152596)这一更完整的替代路径,对公开仓库无需认证即可读到完整规则(`required_approving_review_count: 2`、`require_code_owner_review: true`、`dismiss_stale_reviews_on_push: true`、`required_review_thread_resolution: true`、独立的`non_fast_forward`规则)。
**落到结论**:对比总览表"GitHub分支保护"行;《影响与风险》最后一条"分支保护是仓库级默认全开"及"PR review人数要求/force push限制/review dismiss策略等全部已核实"的具体依据。这不是纠错记录(初始结论没有被推翻),而是取证路径本身的一次优化——取证要点"已验证的检索方式"里两个curl命令都保留下来,正是为了记录"哪条路径才能拿到完整信息"这一实操经验。

## 本主题无纠错记录的说明

取证要点明确标注本文档"暂无纠错记录"——`patched-<sha>`分支机制虽然是Patch_Management.md纠错案例中提到的关联产物,但那次纠错(补丁总量订正)发生在Patch_Management主题内部,不构成Branch_Management自身的"初步判断被推翻"案例,因此本报告不虚构此类过程。

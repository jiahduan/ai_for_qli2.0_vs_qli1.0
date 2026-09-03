# Platform Features — Code Submission

## 对比范围

- **覆盖**:
  - 评审系统与提交追溯对比:QLI1.0 Gerrit(`.repo/manifest.xml`第6行`remote fetch="git://git-android.quicinc.com/" name="quic" review="review-android.quicinc.com"`)+`summary_log.txt`(Change-Id清单,轻量核对时重新统计为167条,原正文"80+条"应为低估,记录见本报告末尾)vs QLI2.0 GitHub PR+DCO(`probot/dco`自动校验)。
  - 许可证/版权头合规检查:`meta-audioreach/repolint.json`(继承`quic/.github`通用规则)+`meta-qcom/.github/workflows/repolinter.yml`(`todogroup/repolinter-action`,`source-license-headers-exist`为`error`级)。
  - CI在评审门禁中的真实生效状态:GitHub Actions self-hosted runner(`runs-on: [self-hosted, qcom-u2404, amd64]`)+GitHub rulesets(`required_status_checks`/`required_approving_review_count`/`require_code_owner_review`,ruleset id——meta-qcom 4151135、meta-qcom-distro 2421982、meta-audioreach 10152596)。
  - 贡献指南与DCO要求对比:`meta-updater/CONTRIBUTING.adoc`、`meta-audioreach/CONTRIBUTING.md`(要求`git commit -s`)vs QLI1.0无项目自身CONTRIBUTING;`meta-qcom`/`meta-qcom-distro`用`CODEOWNERS`替代DCO的澄清。
  - 补丁质量把关脚本:`yocto-patchreview.sh`(调用`oe-core/scripts/contrib/patchreview.py`检测malformed-sob/malformed-upstream-status)、`yocto-check-layer.sh`、`schemacheck.py`。
  - 静态代码扫描能力缺口对比:QLI1.0`release/linux_base_klocwork_control_template.txt`+`release/kw`(Klocwork)vs QLI2.0对`.github/workflows`全量`grep -rln "codeql|klocwork|coverity|static.analysis|SAST"`零命中。
- **明确排除**:
  - 版本管理拓扑本身(repo manifest结构 vs 各层独立git仓库)的深度对比 ——见[Code_Repository](../../Code_Composition/Code_Repository/Code_Repository.md)
  - 代码同步/拉取机制本身(`repo sync`命令层面 vs `kas checkout`/`git clone`)的深度对比 ——见[Code_Sync_Method](../../Code_Composition/Code_Sync_Method/Code_Sync_Method.md)
  - kas CI矩阵机制本身(`ci/*.yml`结构、`kas build`触发方式) ——见[Build_Tools](../../Build_Architecture/Build_Tools/Build_Tools.md)
  - GitHub分支保护/ruleset的存在性与`non_fast_forward`(禁止force push)规则本身 ——见[Branch_Management](../../Code_Composition/Branch_Management/Branch_Management.md)
- **待定边界**:(无,已核实。Branch_Management.md的"明确排除"项——GitHub ruleset里代码评审/合并门禁的具体规则(`required_approving_review_count`/CODEOWNERS/`required_status_checks`)——已在本文"覆盖"字段与"关键差异"/"影响与风险"正文中真实承接,跨文档指向核对一致。)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| 版本管理拓扑 | Google `repo`工具聚合多仓(`.repo/manifest.xml`),单一manifest版本锁定所有子项目 | 每个`meta-*`层各自是独立git仓库,无统一manifest工具痕迹 |
| 评审系统 | Gerrit(`review-android.quicinc.com`),Change-Id/Code-Review;`.repo/manifest.xml`定义`remote fetch="git://git-android.quicinc.com/" name="quic" review="review-android.quicinc.com"` | GitHub风格Pull Request+DCO(`Signed-off-by`)+`probot/dco`自动校验 |
| 提交追溯 | `summary_log.txt`记录Gerrit Change-Id清单(如`https://review-android.quicinc.com/6767986`等80+条),作为"本次集成包含哪些Gerrit change"的追溯记录 | 依赖各层各自git log/PR历史 |
| 许可证合规检查 | 未见项目自身自动化工具(仅第三方子模块自带的`.gitreview`,如repo工具自身、`src/kernel-6.18/.../arm-trusted-firmware/.gitreview`,并非QLI1.0项目自身配置的gerrit hook,gerrit集成通过manifest`review=`属性统一配置) | `meta-audioreach/repolint.json`自动化强制SPDX/Copyright头检查,对`*.py/*.c/*.cpp/*.h/*.sh/*.bbclass`等文件强制要求60行内出现`Copyright ... Qualcomm Innovation Center`或`SPDX-License-Identifier`字样,否则报`error`级别(继承`quic/.github`通用规则) |
| CI定义 | 未见项目自身CI配置(内部build系统在仓外,`release/`、`framework_release/`是内部构建/发布基础设施脚本,服务于内部CRM/build系统) | 层内`ci/`目录kas矩阵(非传统gitlab-ci.yml/Jenkinsfile,详见output/Build_Architecture/Build_Tools/Build_Tools.md)+部分层`.gitlab-ci.yml`(仅`meta-security`、`meta-updater`出现)+patch review脚本(`yocto-patchreview.sh`调用`oe-core/scripts/contrib/patchreview.py`,检测malformed-sob/malformed-upstream-status补丁并使CI失败;`yocto-check-layer.sh`;`schemacheck.py`kas yaml schema校验) |
| 贡献指南 | 无项目自身CONTRIBUTING | 每个开源层均有CONTRIBUTING.md/adoc(如`meta-updater/CONTRIBUTING.adoc`要求`git commit -s`签署,由`probot/dco`自动检查PR;`meta-audioreach/CONTRIBUTING.md`同样要求DCO+fork/PR流程,遵循master分支开发规范),要求DCO+测试门槛(如"OTA-enabled build成功、oe-selftest通过、更新前后向兼容") |

## 关键差异

- 从Gerrit(强代码评审+CI gate强绑定,change必须Verified+Code-Review才能merge)迁移到PR+DCO+外部kas CI,评审强制性依赖外部CI系统的实际接入情况——已核实`meta-qcom`/`meta-qcom-distro`(qualcomm-linux GitHub组织)/`meta-audioreach`(Audioreach GitHub组织)都用**GitHub Actions自托管runner**(`runs-on: [self-hosted, qcom-u2404, amd64]`)真实触发`ci/*.yml`定义的kas矩阵,`pr.yml`在PR到`wrynose`分支时会跑`build-yocto.yml`;`meta-security`/`meta-updater`(上游git.yoctoproject.org/uptane仓库)则是独立的GitLab CI(`.gitlab-ci.yml`),两套体系互不相通。是否设为required status check(真正阻断merge按钮)已核实,见下方"影响与风险"。
- `repolint.json`的许可证头检查是新增的合规硬控制,对存量代码迁移/新增文件都会有强制影响,需要评估现有meta-qcom系列文件是否已全部满足(尤其预编译二进制wrapper recipe之外的脚本文件)。已核实`meta-qcom/.github/workflows/repolinter.yml`用`todogroup/repolinter-action`加载该规则,`source-license-headers-exist`为`error`级别,不通过会在PR页面产生红色失败检查,push/PR到`wrynose`/`main`分支都会跑,是job级别的真实失败而非提示。
- 提交追溯方式从"Gerrit Change-Id全局唯一可查"变为"分散在各层git历史",对安全/合规审计(如出口管制、代码来源追溯)的工具链需要重新搭建(原先可能依赖`summary_log.txt`+Gerrit API的脚本将失效)。
- `yocto-patchreview.sh`强制SoB(Signed-off-by)/upstream-status检查,与DCO机制共同构成"补丁必须签署来源"的双重把关,比QLI1.0(未见强制SoB机制证据)更严格,可能提高外部/内部贡献门槛。

## 影响与风险

- 顶层真正的`.gitlab-ci.yml`只出现在`meta-security`、`meta-updater`(独立GitLab CI体系);`meta-qcom`系列的`ci/*.yml`由GitHub Actions自托管runner消费,PR到`wrynose`分支即触发真实构建,不是"未接入"的猜测状态。**required status check已核实**:传统`GET /repos/{owner}/{repo}/branches/{branch}/protection`接口对无token的匿名请求返回`401 Requires authentication`,但GitHub新版`GET /repos/{owner}/{repo}/rulesets`列表/详情接口对公开仓库无需认证即可读取——用该接口拉取到`meta-qcom`的`Require status checks to pass`(id 4151135,`enforcement: active`,覆盖`~DEFAULT_BRANCH`与`refs/heads/wrynose`)、`meta-qcom-distro`的`Main / Wrynose protection`(id 2421982,active,覆盖`refs/heads/main`与`refs/heads/wrynose`)、`meta-audioreach`的`Require status checks to pass`(id 10152596,active),三者的`required_status_checks`都明确列出`DCO`、`repolinter`、`build-pr / build_successful`(meta-qcom额外多一条`Test Results`),且都同时要求`required_approving_review_count: 2`+`require_code_owner_review: true`。结论:这些CI检查和2人+CODEOWNERS评审确实被设为required status check,真实阻断merge按钮,不是仅定义未接入的空对空状态。
- 已确认`meta-audioreach`、`meta-updater`(开源上游血统层)要求DCO(`git commit -s`+`probot/dco`自动校验);`meta-qcom`、`meta-qcom-distro`(QTI自维护层)没有CONTRIBUTING/DCO配置,改用`CODEOWNERS`强制指定审阅人(`meta-qcom/.github/CODEOWNERS`)配合repolinter/build-yocto CI把关——是"审阅人机制替代DCO",不是评审流程缺失。
- QLI1.0内部Gerrit+`release/`/`framework_release/`下的Klocwork静态扫描(`release/linux_base_klocwork_control_template.txt`+`release/kw`)在QLI2.0没有对应替代物,是能力缺口而非"尚不确定":对`meta-qcom`、`meta-qcom-distro`、`meta-audioreach`的`.github/workflows`整体`grep -rln "codeql|klocwork|coverity|static.analysis|SAST"`零命中,现有GitHub Actions CI(build-yocto/repolinter/test)里没有任何静态代码扫描步骤,repolinter只检查license header/copyright。

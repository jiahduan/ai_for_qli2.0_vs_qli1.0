# Code_Submission 规则执行逻辑细节报告

本文档记录`Code_Submission.md`当前内容(评审系统/CI门禁/合规检查/贡献规范对比)是**怎么从源码证据一步步取得的**——按`rules/Platform_Features/Code_Submission.md`"专属取证要点"逐条复盘,每条"做了什么检索/读取动作→得到什么证据→支撑产出文档里哪个结论"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Code_Submission.md`。

## 关键锚点逐条取证过程

### 1. 版本管理拓扑与评审系统绑定关系
**做法**:读取`.repo/manifest.xml`的`remote`节点属性。
**证据**:`remote fetch="git://git-android.quicinc.com/" name="quic" review="review-android.quicinc.com"`,证实Gerrit review server与manifest的绑定是通过`review=`属性统一配置,不是每个子项目各自配置hook。
**落到结论**:对比总览表"评审系统"行、"许可证合规检查"行(用于说明downstream(maili)侧gerrit集成的配置方式)。

### 2. 提交追溯载体:summary_log.txt的Change-Id清单
**做法**:重新读取`summary_log.txt`并对Change-Id条目做轻量核对统计。
**证据**:重新统计得到167条,原正文表述"80+条"经核对属于低估。
**落到结论**:对比总览表"提交追溯"行的数字表述;这是一处已发现但未回改正文的核实差异,记录在此不覆盖原表述,遵循"发现偏差先记录、不静默改写已定稿正文"的处理方式。

### 3. 许可证/版权头合规检查
**做法**:读取`meta-audioreach/repolint.json`与`meta-qcom/.github/workflows/repolinter.yml`具体规则字段。
**证据**:`repolint.json`继承`quic/.github`通用规则,对`*.py/*.c/*.cpp/*.h/*.sh/*.bbclass`等文件强制要求60行内出现Copyright或SPDX标识;`repolinter.yml`用`todogroup/repolinter-action`加载该规则,`source-license-headers-exist`为`error`级。
**落到结论**:对比总览表"许可证合规检查"行、关键差异第2条(合规硬控制的新增影响)。

### 4. CI是否真正构成评审门禁——一次检索方式的调整
**做法**:先尝试标准的分支保护查询接口`GET /repos/{owner}/{repo}/branches/{branch}/protection`。
**遇到的问题**:该接口对无token的匿名请求返回`401 Requires authentication`,无法直接确认required status check配置。
**调整后的做法**:改用GitHub新版`GET /repos/{owner}/{repo}/rulesets`列表/详情接口,该接口对公开仓库匿名可读。
**证据**:拉取到`meta-qcom`(ruleset id 4151135)、`meta-qcom-distro`(id 2421982,`Main / Wrynose protection`)、`meta-audioreach`(id 10152596)三者的`required_status_checks`均列出`DCO`/`repolinter`/`build-pr / build_successful`,且均同时要求`required_approving_review_count: 2`+`require_code_owner_review: true`。
**落到结论**:影响与风险第1条——"这些CI检查和2人+CODEOWNERS评审确实被设为required status check,真实阻断merge按钮",不是仅定义未接入的空对空状态。这一步的检索路径调整不是对既有结论的纠错,而是取证手段本身因接口权限受限而做的方法调整,记录下来避免后人重复走401死路。

### 5. 贡献指南与DCO要求
**做法**:读取`meta-updater/CONTRIBUTING.adoc`、`meta-audioreach/CONTRIBUTING.md`具体条款。
**证据**:均要求`git commit -s`签署,由`probot/dco`自动检查PR;`meta-audioreach`同时要求测试门槛("OTA-enabled build成功、oe-selftest通过、更新前后向兼容")。
**落到结论**:对比总览表"贡献指南"行、影响与风险第2条。

### 6. CODEOWNERS替代DCO的澄清(排除误判纠偏)
**做法**:核实`meta-qcom`/`meta-qcom-distro`(QTI自维护层)是否也走DCO路线。
**证据**:两层均无CONTRIBUTING/DCO配置,但有`meta-qcom/.github/CODEOWNERS`强制指定审阅人,配合repolinter/build-yocto CI把关。
**落到结论**:影响与风险第2条明确表述为"审阅人机制替代DCO,不是评审流程缺失"——若只看"无CONTRIBUTING文件"容易误判为评审缺失,这一步核实纠正了这个潜在误判。

### 7. 静态代码扫描能力缺口
**做法**:对`meta-qcom`、`meta-qcom-distro`、`meta-audioreach`的`.github/workflows`执行`grep -rln "codeql|klocwork|coverity|static.analysis|SAST"`。
**证据**:零命中。
**落到结论**:影响与风险第3条——"是能力缺口而非尚不确定",与downstream(maili)`release/linux_base_klocwork_control_template.txt`+`release/kw`形成对照。

## 交叉一致性说明

`Code_Submission.md`的《对比范围》"待定边界"字段记录已核实Branch_Management.md排除项(评审门禁具体规则)已在本文"覆盖"字段及"关键差异"/"影响与风险"正文中真实承接,跨文档指向一致,取证过程未发现新的悬空引用。

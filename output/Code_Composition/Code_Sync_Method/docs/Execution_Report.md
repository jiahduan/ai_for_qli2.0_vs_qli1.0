# Code_Sync_Method 执行报告

本文档复盘`../Code_Sync_Method.md`的结论是怎么从取证要点(见`rules/Code_Composition/Code_Sync_Method.md`"Code_Sync_Method专属取证要点"节)一步步落地的——按锚点/检索方式逐条展开"做了什么检索→得到什么证据→支撑了哪个结论"。原理性背景见同目录`Principles.md`,具体差异结论本身见`../Code_Sync_Method.md`。

## 1. 元数据规模的坐实

**做法**:直接查看downstream(maili)`.repo/manifests/default.xml`文件大小与`<project>`条目数;查看QLI2.0各层`ci/*.yml`文件数量。
**证据**:`default.xml`342KB、380个`<project>`条目;`meta-qcom`46个yml、`meta-qcom-distro`36个yml。
**落到结论**:对比总览表"元数据规模"行,是《关键差异》"一步完成拉代码+配层+锁版本"这一判断的规模对比基础。

## 2. repo manifest残留排查——确认迁移的彻底性

**做法**:全树执行`grep -rl "manifest.xml\|<project \|repo init"`,排除`build/`产物目录。
**证据**:零命中。
**落到结论**:《影响与风险》"本次交付的QLI2.0全部三个顶层产品均使用kas...未见任何repo manifest残留"这一结论,是穷举检索得到的零命中证据,不是"没关注这个问题"。

## 3. kas工具本体源码的直接读取——鉴权机制取证

**做法**:取证要点记录了这是一次特殊的证据来源类型——不是读QLI2.0代码库本身,而是读本机安装的pip包`kas==5.5`的`site-packages/kas/libcmds.py`源码,定位`SetupHome`/`Macro.__init__`两个函数。
**证据**:读出kas对`SSH_PRIVATE_KEY`/`SSH_PRIVATE_KEY_FILE`(自动起`ssh-agent`)、`GIT_CREDENTIAL_HELPER`/`GITCONFIG_FILE`/`NETRC_FILE`(HTTPS凭据)、`CI_SERVER_HOST`/`CI_JOB_TOKEN`(GitLab CI自动追加netrc条目)的具体注入逻辑。
**落到结论**:《影响与风险》倒数第二条"kas发行包反查确认了kas具体走哪几条腿"整段——取证要点特别强调这是"读取工具源码具体字段"式取证,与"QLI2.0代码库本身证据"是两类不同性质的证据,本报告如实区分,不混同为同一类型。

## 4. QLI2.0快照内私有仓库接入痕迹排查

**做法**:全树检索`netrc|GIT_ASKPASS|ssh-agent|known_hosts|credential.helper|KAS_REPO_REF_DIR`。
**证据**:零命中,且核对全部`ci/*.yml`的`url:`字段均指向`github.com`或`git.yoctoproject.org`公开地址。
**落到结论**:《影响与风险》"本次交付快照里没有任何私有仓库示例"这一结论;《待确认》节"QLI2.0具体启用哪种kas鉴权机制、私有fork托管在哪"保留为开放问题的依据——取证要点明确这不是被推翻的旧结论,而是本就查不到的开放问题,因此本报告不虚构一个"最终查到了"的结果。

## 5. `base.lock.yml`的取证边界处理

**做法**:确认`base.lock.yml`集中锁定机制存在,但取证要点明确"不含其锁定的具体12个repo清单及与各产品顶层yml的两层结构细节"。
**证据**:锁定机制存在且与业务YAML分离。
**落到结论**:对比总览表"锁定粒度"行只描述机制层面("集中锁定所有层SHA,与业务YAML分离,便于CI复现"),具体清单细节明确排除给Code_Repository.md——这是范围交叉一致性规则(规则7)在证据收集阶段的体现,取证时就已经按边界分工去组织素材,不是写文档时才临时切割。

## 本主题无纠错记录的说明

取证要点明确标注本文档"暂无纠错记录",并说明文档里的"待确认"部分(QLI2.0具体启用哪种kas鉴权机制、私有fork托管在哪)是尚未查清的开放问题,不是被推翻的旧结论——本报告据此不虚构任何"初步判断→核实后结论"的对照,如实保留这两处为开放问题。

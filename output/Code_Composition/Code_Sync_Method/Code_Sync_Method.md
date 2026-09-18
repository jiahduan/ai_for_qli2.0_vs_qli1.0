# Code Composition — Code Sync Method

## 对比范围

- **覆盖**:
  - 代码同步机制整体对照:downstream(maili)`.repo/manifests/default.xml`(342KB,380个`<project>`条目)+`repo init`/`repo sync`工作流+`set_bb_env.sh`/`bblayers.conf`手工生成模式,vs QLI2.0各层`ci/*.yml`(`meta-qcom`46个/`meta-qcom-distro`36个)+`kas build`/`kas checkout`工作流
  - `ci/base.lock.yml`集中锁定机制的存在性与作用(不含其锁定的具体12个repo清单及与各产品顶层yml的两层结构细节)
  - repo manifest残留排查(`grep -rl "manifest.xml\|<project \|repo init"`排除build产物目录,零命中)
  - kas鉴权机制的通用实现细节:本机`kas==5.5`发行包源码(`site-packages/kas/libcmds.py`的`SetupHome`/`Macro.__init__`)反查`SSH_PRIVATE_KEY`/`GIT_CREDENTIAL_HELPER`/`NETRC_FILE`/`CI_SERVER_HOST`等环境变量注入逻辑,及QLI2.0快照内是否已配置私有仓库接入(`netrc|GIT_ASKPASS|ssh-agent|known_hosts|credential.helper|KAS_REPO_REF_DIR`全树检索,零命中)
- **明确排除**:
  - kas`patches:`跨仓补丁机制本身(字段语义与消费方patches目录关系) ——见[Patch_Management](../Patch_Management/Patch_Management.md)
  - kas`patches:`产生的`patched-<hash>`分支命名与状态 ——见[Branch_Management](../Branch_Management/Branch_Management.md)
  - Gerrit评审/GitHub PR code review流程对照 ——见[Code_Submission](../../Platform_Features/Code_Submission/Code_Submission.md)
  - `base.lock.yml`锁定的具体repo清单及与各产品顶层yml的两层锁定结构细节 ——见[Code_Repository](../Code_Repository/Code_Repository.md)
- **待定边界**:(无,已核实——现有"待确认"节讨论的QLI2.0具体启用哪种kas鉴权机制、私有fork托管在哪个内部git服务器,是快照之外的DevOps部署事实问题,不是文档间归属边界问题)

## 对比总览

| 维度 | downstream(maili)(repo) | QLI2.0(kas) |
|---|---|---|
| 元数据规模 | `.repo/manifests/default.xml`(342KB,380个`<project>`条目,remote包括quic/clo-le/clo-ype等) | 分散在各层`ci/*.yml`(meta-qcom 46个、meta-qcom-distro 36个等),可按machine/distro组合(`a.yml:b.yml`) |
| 典型命令 | `repo init -u <manifest-url> -b <branch> -m default.xml` + `repo sync -j<N>`(两步,且需手动生成bblayers.conf,downstream(maili)用setup-environment脚本动态生成) | `git clone https://github.com/qualcomm-linux/meta-qcom.git -b wrynose` + `kas build meta-qcom/ci/<machine>.yml:meta-qcom/ci/<distro>.yml` |
| 工作树落地方式 | poky及其下所有meta-qti-*层、src/*、qc/*.lnx/cd均是`repo sync`后生成的独立bare仓库(位于`.repo/projects/`),工作树通过符号链接`.git -> ../../.repo/projects/xxx.git`挂载 | `kas checkout`(递归拉取repos:中列出的所有层到锁定commit,并按`patches:`声明打补丁) |
| 锁定粒度 | manifest revision字段(每project一个SHA/branch),配合`local_manifests`覆盖 | `ci/base.lock.yml`集中锁定所有层SHA,与业务YAML分离,便于CI复现 |
| 跨仓补丁 | 无原生机制,依赖cherry-pick/脚本 | kas`patches:`声明式跨仓打补丁(详见Patch_Management.md) |
| 容器化 | 无内建支持 | `kas-container`一行命令即可在容器内构建,主机零依赖 |
| 层清单来源 | 手写在`set_bb_env.sh`/`bblayers.conf`模板中,和manifest是两套独立信息 | `ci/*.yml`的`repos:`与`BBLAYERS`同源自动生成,不会漂移 |
| 版本追溯方式 | Gerrit评审+manifest revision(详见output/Platform_Features/Code_Submission/Code_Submission.md) | 上游开源、轻量,不再需要访问Qualcomm内部gerrit/repo服务器 |

## 关键差异

- 一步完成"拉代码+配层+锁版本",避免repo模式下manifest revision与bblayers.conf手工列表"两处维护、易失配"的问题。
- `base.lock.yml`使任意开发者/CI可用同一组SHA精确复现构建,而repo manifest虽也能锁SHA,但缺乏与bitbake层加载的自动联动。
- kas原生支持Yocto语义(machine/distro/target/local_conf_header的YAML合并),repo只管代码拉取,层配置仍需额外脚本(downstream(maili)靠`set_bb_env.sh`动态吐出bblayers.conf,增加了一层不透明的胶水逻辑)。
- 上游开源、轻量(meta-qcom已是GitHub上`qualcomm-linux/meta-qcom`独立开源仓库),不再需要访问Qualcomm内部gerrit/repo服务器,降低了对私有基础设施的耦合。

## 影响与风险

- repo→kas迁移意味着构建入口、CI脚本、开发者本机环境搭建方式需要全面更新;原来依赖`.repo/local_manifests`做本地覆盖的流程需要迁移为kas的`KAS_REPO_REF_DIR`/覆写YAML。
- kas的`patches:`机制会在被打补丁的仓库上产生`patched-<hash>`分支(详见Branch_Management.md),这在依赖"分支名有意义"的下游脚本中可能造成误判。
- 失去repo的`local_manifests`灵活覆盖能力和Gerrit code-review集成(`review-android.quicinc.com`),需确认QLI2.0侧的code review流程(GitHub PR?)是否已配套(详见output/Platform_Features/Code_Submission/Code_Submission.md)。
- 本次交付的QLI2.0全部三个顶层产品(`meta-qcom`、`meta-qcom-robotics-sdk`、`meta-audioreach`)均使用kas(各自`ci/*.yml`+`base.lock.yml`),全树`grep -rl "manifest.xml\|<project \|repo init"`(排除`build/`产物目录)零命中,未见任何repo manifest残留。
- kas的`repos:`本质只是声明一个可被`git clone`的`url:`,kas自身不实现独立的鉴权层,而是直接调用主机/容器内的git,因此私有服务器接入方式与"给一台机器配置git访问私有仓库"完全相同(SSH仓库用`ssh://`URL+SSH key/ssh-agent,HTTPS私有仓库用git credential helper或`.netrc`/`GIT_ASKPASS`)。本次交付快照里没有任何私有仓库示例(所有`url:`均指向`github.com`或`git.yoctoproject.org`公开地址)。
- 本机已安装的kas发行包(pip `kas==5.5`,`site-packages/kas/libcmds.py`的`SetupHome`/`Macro.__init__`)反查确认了kas具体走哪几条腿:检测到`SSH_PRIVATE_KEY`或`SSH_PRIVATE_KEY_FILE`环境变量时,kas会在执行前自动起一个内部`ssh-agent`并把私钥加载进去(与外部`SSH_AUTH_SOCK`互斥,两者同时设置会直接报错);HTTPS方向靠`GIT_CREDENTIAL_HELPER`/`GITCONFIG_FILE`环境变量指定的credential helper,或者`NETRC_FILE`指向的文件会被复制成容器内`$HOME/.netrc`;在GitLab CI里检测到`CI_SERVER_HOST`+`CI_JOB_TOKEN`时还会自动追加一条`gitlab-ci-token`的netrc条目。即"接入私有仓库"在kas这一层就是"构建前导出这几个约定环境变量之一",不存在kas自己的凭据存储。这是kas工具本身的通用机制(与Qualcomm/QLI2.0是否使用无关),但把"理论上和配置一台机器一样"落到了具体、可验证的实现细节上。

## 待确认

- 内部私有仓库接入kas的实际鉴权部署细节里,"kas侧支持哪些机制"已通过读kas 5.5源码坐实(见上),剩下"QLI2.0/Qualcomm具体启用了哪一种、私有fork托管在哪个内部git服务器"仍是快照之外的DevOps部署配置(全树`netrc|GIT_ASKPASS|ssh-agent|known_hosts|credential.helper|KAS_REPO_REF_DIR`搜索依旧零命中),需找负责`kas-container`镜像/CI runner配置的团队确认。

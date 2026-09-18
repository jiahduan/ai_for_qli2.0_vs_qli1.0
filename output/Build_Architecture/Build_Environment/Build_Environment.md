# Build Architecture — Build Environment

## 对比范围

- **覆盖**:
  - 环境搭建入口对比:downstream(maili)`setup-environment`软链接→`poky/qti-conf/set_bb_env.sh`(已重新`wc -l`确认457行)vs QLI2.0`kas-container build <yaml>`;已重新核实meta-qcom/meta-qcom-distro/meta-qcom-robotics-sdk三层`ci/`目录无等价交互式封装脚本
  - Shell/host依赖强制检查:`set_bb_env.sh`对bash/`$SHELL`的检查逻辑与QLI2.0容器化后host侧依赖弱化
  - 官方系统最低要求交叉核实:已重新读取两侧`classes-global/sanity.bbclass`确认Python最低版本硬编码(downstream(maili)"3.8"、QLI2.0"3.9");官方`docs.yoctoproject.org/6.0.1/ref-manual/system-requirements.html`存档页面交叉核实磁盘/内存/受支持host清单
  - 内部补丁注入机制:`apply_poky_patches()`+`qti-conf/patches/series`5个补丁逐条比对QLI2.0`bitbake`(2.18.0)现状(3个已随上游重构失效,2个真实差异未迁移)
  - 层版本锁定方式对比:已重新确认`meta-qcom/ci/base.lock.yml`等3处`base.lock.yml`存在(meta-qcom/meta-qcom-robotics-sdk/meta-audioreach各一份)
  - 两侧`build/`目录下`cache/sanity_info`记录的`NATIVELSBSTRING`与本机host基线(`/etc/os-release`/`python3 --version`/`df -h`/`nproc`/`free -h`)交叉核对
- **明确排除**:
  - kas yml层组合/CI一键构建工作流本身,以及meta-security/meta-updater的kas主入口误判纠错 ——见[Build_Tools](../Build_Tools/Build_Tools.md)
  - kas代码同步/版本锁定的完整对比(repo vs kas) ——见[Code_Sync_Method](../../Code_Composition/Code_Sync_Method/Code_Sync_Method.md)
- **待定边界**:(无,已核实:环境搭建入口/host依赖/官方最低要求/补丁注入/层锁定五个维度锚点均已复核,未发现遗漏目录)

## 对比总览

| 维度 | downstream(maili) | QLI2.0 |
|---|---|---|
| 环境搭建入口 | `setup-environment`软链接→`poky/qti-conf/set_bb_env.sh`(457行) | `kas-container build <yaml>`(详见Build_Tools.md);已对meta-qcom/meta-qcom-distro/meta-qcom-robotics-sdk三层`ci/`目录grep核实,不存在类似`set_bb_env.sh`的交互式/自动探测封装脚本,`meta-qcom/README.md`"Quick build"一节即为官方入口 |
| Shell强制要求 | 显式检查`/bin/sh`必须指向bash、`$SHELL`必须是bash,否则直接`return 1`并提示`sudo ln -sf /bin/bash /bin/sh` | 未见等价脚本级校验(容器内环境由kas镜像固定) |
| Host依赖 | 需本机安装bash/所需apt包(继承Yocto reference manual的host依赖列表) | 官方建议仅需Docker/Podman+`kas-container`脚本,构建依赖全部在容器内 |
| 官方最低要求 | `MIN_PYTHON_VERSION="3.8.0"`,`MIN_DISK_SPACE="90"`GB,`MIN_RAM="8"`GB;受支持host:Ubuntu 22.04/24.04 LTS、Debian 11/12、Fedora 39-41、AlmaLinux/Rocky 8/9等 | 未见本仓库内置的等价独立文档,`sanity.bbclass`硬编码Python最低3.9;已直接抓取上游`docs.yoctoproject.org/6.0.1/ref-manual/system-requirements.html`(对应本仓库bitbake `yocto-6.0.1`/Wrynose release)核实官方口径:Python最低3.9.0,磁盘≥140GB(构建`core-image-sato`/qemux86-64),RAM"32GB+4核"起步(越多越快);受支持host为Ubuntu 22.04/24.04/25.04/25.10/26.04 LTS、Debian 11/12/13、Fedora 42/43、OpenSUSE Leap 15.6/16.0、AlmaLinux/Rocky 8/9、CentOS Stream 9/10;Ubuntu/Debian下headless构建所需包为`build-essential chrpath cpio debianutils diffstat file gawk gcc git iputils-ping libacl1 libcrypt-dev locales python3 python3-git python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd`(+按需`python3-websockets`),Fedora对应`dnf install`清单结构类似 |
| 内部补丁注入 | `apply_poky_patches()`会在`cd ${WS}/poky`后按`qti-conf/patches/series`逐个patch打入poky源码树,每次进环境都会执行,共5个补丁(均打在bitbake自身) | 无对应机制;逐个比对QLI2.0`bitbake`(2.18.0)代码后确认5个补丁中3个(去重复checksum警告、LAYERSERIES_COMPAT缺失时的warn/fatal差异、Python 3.11兼容双路径解析)已随上游重构自然失效,剩2个是真实差异未带过去:①`handleLayerDepends`对"qti"字样层名的`LAYERDEPENDS`强校验在QLI2.0没有等价实现(且层名已改为meta-qcom等,不再含"qti");②SRC_URI本地文件找不到时QLI2.0仍是`bb.fatal`而非downstream(maili)放宽过的`bb.warn`,比downstream(maili)更严格 |
| 内网镜像探测 | 脚本内保留`select_mirror`/`select_sstate_machine`/`generate_auto_mirror`等Qualcomm内网镜像自动探测逻辑,与内网构建基础设施强绑定 | 无内网耦合痕迹,面向开源GitHub生态 |
| 层版本锁定方式 | 依赖repo/manifest(`.repo/`)固定revision | kas yaml+`base.lock.yml`用commit hash精确锁定每个repo |
| 已验证构建目录 | — | 顶层已存在实体`build/`目录(含sstate-cache/、downloads/、buildhistory/、bitbake-cookerdaemon.log),说明该快照已在本机跑过至少一次原生(非容器)构建,证明原生host直接跑bitbake的路径依然可用,不是kas强制唯一入口 |

## 关键差异

- downstream(maili)从"clone一个大manifest+source setup-environment"整体切换为QLI2.0的"kas-container+yaml组合",是本次审计中"构建工作流"层面最直接的转变。
- Python 3.9门槛:如果内部构建机仍是较老版本的OS(如CentOS 7/8、老版本Ubuntu),需要先确认host上python3版本,否则sanity check会在构建早期直接失败。

## 影响与风险

- CI/CD与本地构建工作流需要重新设计:从"clone一个大manifest+source setup-environment"切换到"kas-container+yaml组合",研发同事的本地开发习惯、脚本、CI pipeline都要重写,而不只是升级版本号。
- kas容器化带来隔离性收益但也带来新依赖:构建机需要Docker/Podman权限,在有严格内网安全策略、容器daemon受限的企业环境中可能是新的落地障碍(相对downstream(maili)纯host原生构建更"重")。
- downstream(maili)脚本中的补丁注入机制(`apply_poky_patches`)是隐藏的构建期变更点;逐条比对后确认5个补丁里3个已随bitbake上游重构自然失效,但`handleLayerDepends`对"qti"层名的强校验和SRC_URI本地文件缺失时的报错严格度(QLI2.0仍是fatal,比downstream(maili)放宽过的warn更严)这两条真实差异没有带到QLI2.0,需要架构师确认是否要重新引入,尤其后者若不处理,某些历史习惯于"本地文件缺失只warn"的recipe搬到QLI2.0会直接fatal失败。
- 本机两侧`build`目录的实测host基线已核实完毕,不再是未知项:两侧`cache/sanity_info`(bitbake sanity check自己写入的记录,非人工填写)都记着`NATIVELSBSTRING ubuntu-22.04`,与当前host`/etc/os-release`(Ubuntu 22.04.5 LTS)一致;当前host `python3 --version`为3.10.12,高于官方最低3.9.0门槛;`df -h`可用磁盘约2.8TB,远超140GB门槛;`nproc`/`free -h`为96核/503GB内存,远超"32GB+4核"起步门槛。即本机两份`build/`目录的搭建环境本身就满足且明显富余于官方清单,不存在基线不一致的风险。

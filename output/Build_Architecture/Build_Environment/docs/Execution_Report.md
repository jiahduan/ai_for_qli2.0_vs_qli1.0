# Build_Environment 规则执行逻辑细节报告

本文档记录`Build_Environment.md`当前结论的取证过程——按`rules/Build_Architecture/Build_Environment.md`"专属取证要点"逐条复盘。原理性背景见同目录`Principles.md`,具体差异结论见`../Build_Environment.md`。

## 逐条取证过程

### 1. 环境搭建入口对比
**做法**:确认downstream(maili)入口脚本身份与体量,并排查QLI2.0是否存在等价封装脚本。
**证据**:downstream(maili)`setup-environment`软链接→`poky/qti-conf/set_bb_env.sh`(`wc -l`确认457行);已grep排查`meta-qcom`/`meta-qcom-distro`/`meta-qcom-robotics-sdk`三层`ci/`目录,无等价交互式封装脚本,官方入口是`meta-qcom/README.md`"Quick build"一节。
**落到结论**:对比总览表"环境搭建入口"行。

### 2. Shell/host依赖强制检查
**做法**:读取`set_bb_env.sh`内部对`/bin/sh`/`$SHELL`的检查逻辑。
**证据**:显式要求`/bin/sh`指向bash、`$SHELL`必须是bash,不满足直接`return 1`;QLI2.0无等价脚本级校验(容器内环境由kas镜像固定)。
**落到结论**:对比总览表"Shell强制要求"/"Host依赖"两行。

### 3. 官方系统最低要求交叉核实
**做法**:先读取两侧`classes-global/sanity.bbclass`硬编码的Python最低版本,再直接抓取上游`docs.yoctoproject.org/6.0.1/ref-manual/system-requirements.html`(对应本仓库`yocto-6.0.1`/wrynose release)核实官方口径。
**证据**:`sanity.bbclass`硬编码Python最低3.9(QLI2.0)/3.8(downstream(maili)引用值);官方页面给出Python≥3.9.0、磁盘≥140GB、RAM"32GB+4核"起步、受支持host清单(Ubuntu/Debian/Fedora/OpenSUSE/AlmaLinux/CentOS Stream各版本)及headless构建所需apt包清单。
**落到结论**:对比总览表"官方最低要求"行。

### 4. 内部补丁注入机制逐条比对
**做法**:读取`apply_poky_patches()`引用的`qti-conf/patches/series`5个补丁内容,逐条与QLI2.0`bitbake`(2.18.0)现状比对,判断是否已随上游重构自然失效。
**证据**:5个补丁中3个(去重复checksum警告、`LAYERSERIES_COMPAT`缺失时warn/fatal差异、Python 3.11兼容双路径解析)已随上游重构失效;剩2个是真实差异未迁移——`handleLayerDepends`对"qti"字样层名的`LAYERDEPENDS`强校验QLI2.0无等价实现,以及SRC_URI本地文件缺失时QLI2.0仍是`bb.fatal`(比downstream(maili)放宽后的`bb.warn`更严格)。
**落到结论**:对比总览表"内部补丁注入"行,《影响与风险》"这两条真实差异没有带到QLI2.0"一段。

### 5. 层版本锁定方式对比
**做法**:确认QLI2.0`base.lock.yml`等价lock文件的存在范围。
**证据**:重新确认`meta-qcom/ci/base.lock.yml`等3处`base.lock.yml`存在(meta-qcom/meta-qcom-robotics-sdk/meta-audioreach各一份)。
**落到结论**:对比总览表"层版本锁定方式"行。

### 6. 本机host基线交叉核对
**做法**:读取两侧`build/`目录下`cache/sanity_info`记录的`NATIVELSBSTRING`,与当前host`/etc/os-release`/`python3 --version`/`df -h`/`nproc`/`free -h`交叉核对。
**证据**:两侧`sanity_info`均记`NATIVELSBSTRING ubuntu-22.04`,与host`/etc/os-release`(Ubuntu 22.04.5 LTS)一致;`python3 --version`为3.10.12(高于3.9.0门槛);磁盘约2.8TB(远超140GB门槛);96核/503GB内存(远超32GB+4核门槛)。
**落到结论**:《影响与风险》"本机两份`build/`目录的搭建环境本身就满足且明显富余"结论。

## 纠错记录

本主题取证要点未记录纠错项(暂无先前判断被推翻的情况)。

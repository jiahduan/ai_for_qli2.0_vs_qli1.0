# Flash_Process 规则执行逻辑细节报告

本文档记录`Flash_Process.md`当前内容(刷机工具链/文档/版本追溯对比)是**怎么从源码证据一步步取得的**,重点复盘一次搜索路径纠错的完整过程——按`rules/Platform_Features/Flash_Process.md`"专属取证要点"逐条展开,原理性背景见同目录`Principles.md`,具体差异结论本身见`../Flash_Process.md`。

## 核心纠错过程:QLI1.0刷机工具链"从缺失到找到"

这是本主题最重要的一次判断修正,完整过程如下:

**最初判断**:围绕"面向终端工程师的完整刷机文档/工具链在哪里"这个问题,搜索范围限定在`sdk-tools/`、`release/`、`framework_release/`、`qc/`、`vendor/`、`src/`这几个看起来最直接相关的目录。检索结果:`release/`、`framework_release/`只有内部构建/发布基建脚本(`syncbuild.sh`、`updatepack`、`diffpack`等);`sdk-tools/Host.md`里确实出现"Freshly flashed device with metabuild"、"Prepare Device Connected To Local PC After Image Or Metabuild Flash"等章节标题,说明存在刷机后处理步骤文档,但全库检索`QDL`/`9008`关键字命中的都是无关的第三方测试向量文件,没有找到QDL工具本体或详细刷写命令。据此,最初倾向于认为QLI1.0缺少产线刷机工具链,需要向产线团队额外索取外部工具。

**怎么发现问题**:复核搜索范围是否已经覆盖代码库里所有可能存放BSP级工具链的位置时,注意到之前的搜索列表里没有包含`poky/meta-qti-bsp*`——这是Yocto BSP层的标准存放位置,理应优先纳入搜索范围,而不是只看应用层/发布层目录。

**修正后的做法**:对`poky/meta-qti-bsp*`执行`grep -rl "inherit.*qimage" --include="*.bb" .`,命中19个`qti-*-image.bb`产品镜像;追查`poky/meta-qti-bsp/classes/qimage.bbclass`第81-111行,确认`do_gen_partition_bin`任务依赖`gen-partitions-tool-native`/`ptool-native`/`qdl-native`三个recipe;逐一定位到`poky/meta-qti-bsp/recipes-devtools/qdl/qdl_git.bb`(qdl-native)、`poky/meta-qti-bsp-prop/recipes-devtools/partition-utils/`(ptool-native,`ptool.py`生成`rawprogram*.xml`/`patch*.xml`/GPT bin)、`poky/meta-qti-bsp/recipes-devtools/gen-partitions-tool/gen-partitions-tool-native_1.0.bb`。

**修正成的结论**:QLI1.0真正的产线刷机工具链其实一直存在,位于`poky/meta-qti-bsp*`而非应用层/发布层目录,并被`qti-camera-image.bb`/`qti-generic-image.bb`/`qti-robotics-image.bb`等约20个真实产品镜像inherit,不是缺失或需要向产线团队额外索取的外部工具——只是缺一份类似QLI2.0`flashing.md`的、面向终端工程师的整合文档。这一纠错记录已写入`Flash_Process.md`《对比范围》"覆盖"字段第一条及"影响与风险"末条,标注为"本文纠错核心",复核本主题时应优先确认搜索范围已覆盖`poky/meta-qti-bsp*`。

## 其余锚点取证过程

### QLI1.0侧qdl_git.bb具体来源
**做法**:读取`qdl_git.bb`第34-35行。
**证据**:`SRCREV = "22234e6af33af1848e36d4d4bc63264087b97892"`、`SRC_URI`指向内部CAF镜像`abozhinov444.qdl.git`分支`caf_migration/abozhinov444/sparse_image_format`;文件头注释显示该recipe本身derive自`meta-qcom`上游同名文件。
**落到结论**:对比总览表"刷机协议"行——两侧工具链血缘相同,差异只在源码分发渠道。

### QLI1.0版本追溯文件
**做法**:读取`sec_aus.txt`内容,与`.repo/manifest.xml`里的同名tag逐字比对。
**证据**:`AU_LINUX_KERNEL.PLATFORM.6.0.00.00.00.178.129`、`AU_LINUX_EMBEDDED_LE.FRAMEWORK.3.0_TARGET_ALL.01.310.237`,与manifest标签完全对应。
**落到结论**:对比总览表"版本追溯文件性质"行。

### QLI2.0侧刷机文档与命令
**做法**:全文读取`meta-qcom/docs/flashing.md`。
**证据**:VID:PID`05c6:9008`、`qdl --debug prog_firehose_ddr.elf rawprogram*.xml patch*.xml`等命令;`qdl_git.bb`的`HOMEPAGE`指向`github.com/linux-msm/qdl`。
**落到结论**:对比总览表"刷机文档""刷机流程步骤"行,关键差异第2条(QLI2.0文档化程度提升)。

### QLI2.0分区静态资源
**做法**:确认`meta-qcom/recipes-bsp/partition/qcom-partition-conf_git.bb`存在。
**证据**:产出`rawprogram*.xml`/`patch*.xml`/GPT bin。
**落到结论**:关键差异第1条、影响与风险第3条(qcom-distro-sota与默认qcom-distro共用同一份静态资源,不需要产线同步更新QDL脚本)。

### 版本锁定机制对应物
**做法**:确认`meta-qcom/ci/base.lock.yml`由`build-yocto.yml`的`kas-setup` job执行`kas lock`自动生成。
**证据**:锁定每个layer仓库的精确commit hash,作为构建artifact上传。
**落到结论**:对比总览表"版本追溯文件性质"行、影响与风险第2条——取代人工维护`sec_aus.txt`。

## 交叉一致性说明

《对比范围》"待定边界"字段记录:本次重新检索`poky/meta-qti-bsp*`及QLI2.0侧`meta-qcom/recipes-bsp/partition`、`meta-qcom/recipes-devtools/qdl`,未发现上述纠错记录之外的新遗漏目录或工具链缺口。

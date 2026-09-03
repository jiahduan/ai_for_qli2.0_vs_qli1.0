# Bitbake_Version 规则执行逻辑细节报告

本文档记录`Bitbake_Version.md`当前结论是怎么从源码证据一步步取得的——按`rules/Build_Architecture/Bitbake_Version.md`"专属取证要点"逐条复盘每一步"做了什么检索/读取→得到什么证据→支撑了产出文档哪个结论"。原理性背景见同目录`Principles.md`,具体差异结论见`../Bitbake_Version.md`。

## 逐条取证过程

### 1. 版本自证
**做法**:分别读取两侧bitbake自身的版本声明文件。
**证据**:`poky/bitbake/lib/bb/__init__.py`里QLI1.0`__version__="2.8.1"`;QLI2.0`bitbake/lib/bb/__init__.py`里`__version__="2.18.0"`,并用`git describe --tags`得到`yocto-6.0.1`,确认对应Yocto release代号(wrynose)。
**落到结论**:对比总览表第1、2行(bitbake版本、版本号推进跨5个次要发布周期)。

### 2. 覆盖语法/legacy语法硬性检查
**做法**:读取两侧`bb/data_smart.py`第545/553行的`setVar`判断逻辑。
**证据**:两侧逐字节一致,`_append`/`_prepend`旧式语法均触发`bb.fatal`,`__setvar_keyword__`合法列表相同。
**落到结论**:对比总览表"覆盖语法"行——两侧无变化。

### 3. 私有API访问模式排查
**做法**:用`grep`在两侧自定义层(QLI1.0`meta-qti-*`,QLI2.0`meta-qcom*`/`meta-security`/`meta-updater`)扫描典型bitbake私有实现细节访问模式(`bb.cooker.`、`bb.runqueue.`、`bb.taskdata.`、`bb.siggen.`、`d.dict[`、`.varhistory.`、`bb.data_smart.`、`d._data`、`bb.parse.ast.`)。
**证据**:两侧均零命中;唯一命中`SIGGEN`字样的两处核实为公开变量`BB_SIGNATURE_HANDLER`引用,非私有API误用。
**落到结论**:《关键差异》"两侧均无命中"一段,《影响与风险》"语法层/私有API依赖层风险很低"结论。

### 4. `BB_SIGNATURE_HANDLER`差异链
**做法**:逐层核对该变量在`bitbake.conf`默认值、机型conf覆盖、`local.conf`是否覆盖。
**证据**:`poky/meta/conf/bitbake.conf`(QLI1.0默认`"OEBasicHash"`)vs`oe-core/meta/conf/bitbake.conf`(QLI2.0默认`"OEEquivHash"`);`meta-qti-bsp/conf/machine/pebble.conf:156`用强赋值`=`把QLI1.0实际生效值锁回`"OEBasicHash"`;QLI2.0`build/conf/local.conf`未覆盖,最终生效值即上游默认`"OEEquivHash"`。
**落到结论**:对比总览表"BB_SIGNATURE_HANDLER"相关行,《影响与风险》里hash equivalence/`BB_HASHSERVE`依赖的风险提示。

### 5. 两侧实测`bitbake -e glibc`
**做法**:在两侧真实build目录(QLI1.0`build-qti-distro-camerastack-debug`/pebble机型;QLI2.0`build`/iq-9075-evk机型)分别跑通`bitbake -e glibc`,对比effective变量`TC_CXX_RUNTIME`/`SECURITY_CFLAGS`/`SRCREV`/`PACKAGE_CLASSES`/`BB_SIGNATURE_HANDLER`。
**证据**:均无fatal错误(QLI1.0 44667行输出,QLI2.0 35235行输出);`TC_CXX_RUNTIME`/`SECURITY_CFLAGS`/`SRCREV`一致,`PACKAGE_CLASSES`不同但属distro层选型差异非bitbake版本差异。
**落到结论**:《关键差异》"已在两侧真实配置好的build目录里实际跑通"一段,证明两个版本对同一类recipe的解析/展开机制本身是通的。

## 纠错记录

本主题取证要点未记录纠错项(暂无先前判断被推翻的情况)。

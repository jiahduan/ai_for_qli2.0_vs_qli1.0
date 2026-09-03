# Build Architecture — Bitbake Version

## 对比范围

- **覆盖**:
  - bitbake版本自证:已重新核对`poky/bitbake/lib/bb/__init__.py`(QLI1.0`__version__="2.8.1"`)与`bitbake/lib/bb/__init__.py`(QLI2.0`__version__="2.18.0"`,`git describe --tags`→`yocto-6.0.1`)
  - 覆盖语法与legacy语法(`_append`/`_prepend`)强制报错逻辑:已重新读取QLI2.0`bb/data_smart.py`第545/553行`setVar`判断,与QLI1.0逐字节一致
  - 私有API访问模式排查:QLI1.0`meta-qti-*`、QLI2.0`meta-qcom*`/`meta-security`/`meta-updater`层对`bb.cooker.`/`bb.runqueue.`/`bb.data_smart.`等模式的grep,两侧均零命中
  - `BB_SIGNATURE_HANDLER`默认值差异链:已重新核对`poky/meta/conf/bitbake.conf`(QLI1.0`"OEBasicHash"`)vs`oe-core/meta/conf/bitbake.conf`(QLI2.0`"OEEquivHash"`)vs`meta-qti-bsp/conf/machine/pebble.conf:156`强赋值锁回`"OEBasicHash"`
  - 两侧实测`bitbake -e glibc`输出对比(TC_CXX_RUNTIME/SECURITY_CFLAGS/SRCREV/PACKAGE_CLASSES/BB_SIGNATURE_HANDLER)
- **明确排除**:
  - bitbake自身顶层仓库化组织形式(QLI1.0内嵌poky vs QLI2.0独立`bitbake/`仓库) ——见[Yocto](../../System_Architecture/Yocto.md)
  - bitbake作为kas声明式repo被引入构建(`base.yml`里`bitbake: branch: "2.18"`) ——见[Build_Tools](../Build_Tools/Build_Tools.md)
- **待定边界**:(无,已核实:语法/私有API/签名算法三个取证维度的锚点均与规则文件描述吻合,未发现遗漏方向)

## 对比总览

| 维度 | QLI1.0 | QLI2.0 |
|---|---|---|
| bitbake版本 | 2.8.1(`poky/bitbake/lib/bb/__init__.py`) | 2.18.0(`bitbake/lib/bb/__init__.py`),`git describe --tags`→`yocto-6.0.1` |
| 版本号推进 | — | 跨5个次要发布周期(2.8→2.10→2.12→2.14→2.16→2.18,与Yocto每半年一个release对应) |
| ChangeLog可用性 | 均只保留到"Changes in Bitbake 1.9.x"(317行,内容逐字节相同),该文件在两侧均早已停止维护 | 同上 |
| 覆盖语法 | `bb/data_smart.py`: `__setvar_keyword__ = [":append", ":prepend", ":remove"]`是唯一合法语法,`_append`/`_prepend`旧式语法在两侧均硬性`bb.fatal`错误(第545/553行:`if not var.startswith("__anon_") and ("_append" in var or ...)`) | 相同(无变化) |
| 旧式语法迁移时间点 | 更早的dunfell→honister/kirkstone阶段完成,QLI1.0早已完成该迁移 | 不适用 |
| 最低Python版本 | 3.8 | 3.9(间接影响自定义python任务函数,若使用3.9+语法特性QLI1.0环境将无法运行) |

## 关键差异

- "任务语法/变量展开机制"层面的直接冲击其实很有限——因为两侧都已处于"新语法时代"之后,真正的风险不在语法本身,而在5个版本迭代期间bitbake内部API(fetcher、hash equivalence server、`bb.utils`、`bb.event`等)的渐进式变更,这些变更没有ChangeLog可查,必须靠实际跑`bitbake -p`/`bitbake world`触发真实报错来发现,审计层面无法穷尽列出。
- 由于本仓库ChangeLog已失效,无法凭此仓库自证具体breaking change列表,建议架构师后续直接对照上游`https://git.openembedded.org/bitbake`的release notes(2.10~2.18)或运行两个bitbake版本对同一组recipe做`bitbake -e`变量展开结果diff,作为更可靠的验证手段。
- 已用grep在两侧`meta-qti-*`(QLI1.0)与`meta-qcom*`/`meta-security`/`meta-updater`(QLI2.0)排查自定义bbclass/recipe是否假设了bitbake私有实现细节(`bb.cooker.`、`bb.runqueue.`、`bb.taskdata.`、`bb.siggen.`、`d.dict[`、`.varhistory.`、`bb.data_smart.`、`d._data`、`bb.parse.ast.`等典型访问模式),**两侧均无命中**;唯一命中`SIGGEN`字样的两处是公开变量`BB_SIGNATURE_HANDLER`相关引用,不是私有API误用,`getVar(x, True/False)`这类写法也确认是公开文档化的`expand`参数。结论:静态审查范围内两侧都没有依赖bitbake私有实现细节的代码,该项风险按已排查、结果为阴性处理。
- 已在两侧真实配置好的build目录里实际跑通`bitbake -e glibc`(QLI1.0:`build-qti-distro-camerastack-debug`,bitbake 2.8.1,pebble机型,44667行输出;QLI2.0:`build`,bitbake 2.18.0/yocto-6.0.1,iq-9075-evk机型,35235行输出),均无fatal错误,证明两个版本对同一类recipe的解析/展开机制本身是通的。对比关键变量:`TC_CXX_RUNTIME`(两侧均`"gnu"`)、`SECURITY_CFLAGS`(两侧均为空)、`SRCREV`(两侧均`"INVALID"`,glibc走tarball而非git)一致;`PACKAGE_CLASSES`两侧不同(QLI1.0`package_ipk`,QLI2.0`package_rpm`),但这是distro层选型差异,与bitbake版本无关。唯一一条真正由版本/上游默认值变化引出的差异:`BB_SIGNATURE_HANDLER`——QLI2.0侧`oe-core/meta/conf/bitbake.conf`把上游默认值从QLI1.0`poky/meta/conf/bitbake.conf`的`"OEBasicHash"`改成了`"OEEquivHash"`(hash equivalence),且QLI2.0的`build/conf/local.conf`未覆盖,最终生效值就是`"OEEquivHash"`,配合真实存在的`BB_HASHSERVE` unix socket,hash equivalence在QLI2.0是真正启用的;QLI1.0侧`local.conf`虽然也写了`BB_SIGNATURE_HANDLER ?= "OEEquivHash"`,但`meta-qti-bsp/conf/machine/pebble.conf:156`用强赋值`=`把它锁回`"OEBasicHash"`,即pebble机型实际禁用了hash equivalence。这是一条已核实的真实机制差异(oe-core上游默认值变化+QLI1.0机型级显式关闭),但只覆盖到glibc这一个recipe/pebble这一个机型的取样范围,不是对全部recipe的穷尽diff。

## 影响与风险

- 迁移到QLI2.0的bitbake 2.18.0本身在语法层/私有API依赖层风险很低:两侧`meta-qti-*`/`meta-qcom*`自定义bbclass均未触碰`_append`旧语法或bitbake私有实现细节(已排查,零命中),且`bitbake -e`实测跑通,不会因为版本跳变本身导致构建失败。
- 真正的操作风险在`BB_SIGNATURE_HANDLER`默认值切到`OEEquivHash`:QLI2.0的sstate缓存复用行为依赖`BB_HASHSERVE`这个常驻服务(unix socket),如果CI/构建机环境搭建脚本只是照搬QLI1.0"跑起来就行"的思路而没有意识到这一默认值变化,可能出现"hash equivalence服务没启动但配置认为启用"的静默降级(退化为普通OEBasicHash式判定,不会报错但sstate复用率下降、构建变慢),需要构建基建团队在CI环境模板里显式确认`BB_HASHSERVE`服务已随bitbake-cookerdaemon一起拉起。此风险可通过配置检查规避,不影响构建正确性,只影响构建效率,定级P2/P3量级,不需要写入README汇总表。
- 5个发布周期跨度内bitbake内部API(fetcher实现细节、`bb.event`事件类型等)的渐进式变更本身没有ChangeLog可查,本文档的"零命中"结论只覆盖当前两侧代码库存量代码;后续任何新增的自定义bbclass/fetcher如果尝试复用bitbake内部实现细节,应重新跑一遍本文档的grep模式而不是假设历史结论继续有效。


# systemd_ 原理文档

本文档解释systemd这一层在启动链末端管什么、为什么它的版本/补丁/unit数量差异值得单独对比,以及它与Boot_Flow/Bootargs/Partition_Layout的分工边界原理——不涉及QLI1.0/QLI2.0具体差异结论(结论见`../systemd_.md`)。

## 1. systemd层管什么

systemd是内核启动后运行的PID1,负责后续所有用户态服务的启动顺序、依赖管理、挂载点生成(如`fstab-generator`)等。它站在"启动链"和"用户态运行"的交界点:一方面它的早期行为(挂载生成器、initrd阶段的权限模型)仍然算"启动过程"的一部分,直接影响系统能不能正常起来;另一方面它管理的服务集合(`.service`单元)体现的是"这套系统把哪些硬件子系统接管为受systemd生命周期管理的后台服务"。BSP厂商通常需要对上游systemd打若干补丁,把硬件/产品特定的行为(如识别自家cmdline参数、放行自家特权uid)接进systemd的标准流程里——这些补丁是"上游systemd标准行为"和"vendor特定需求"之间的缝合层。

## 2. 为什么要对比这个主题

- **补丁的存在与消失是一份"需求清单"的快照**:一个BSP给systemd打的补丁,本质上是在说"标准systemd的默认行为不满足我们的某个具体需求"。补丁消失不一定是坏事——可能是需求本身不存在了(如没有dm-verity体系,就不需要fstab-generator识别verity cmdline参数),此时补丁消失是"体系变了,需求跟着消失",而不是"功能退化了"。
- **unit数量差异是层成熟度/覆盖范围的信号,不是架构优劣的信号**:vendor层`.service`文件数量的多少,直接反映这个层目前覆盖了多少硬件子系统(WLAN/相机/安全/显示等各自需要多少后台服务)。数量差异需要先判断"是覆盖范围本来就不同"还是"同样的覆盖范围换了实现方式却更省service数量",不能直接类比Distro_Version主题里"变体矩阵从30到4"是否代表能力变化的判断方法。
- **版本差异带来的NEWS级行为变化,需要逐条过筛与本BSP路径的相关性**:systemd主版本升级几年间可能新增几千行NEWS,但只有一部分变化真正命中"这套BSP启动路径实际会用到的功能"(如是否用TPM1.2、是否走gpt-auto-generator路径),逐条筛选比整体引用release notes更有实际意义。

## 3. 与相邻主题的分工边界原理

- **与Bootargs的边界**:cmdline里是否含verity/AVB参数这一取证结论的权威归属是Bootargs;本主题只**引用**这一零命中结果,作为"fstab-generator补丁为什么不再需要"这一判定的交叉印证,不重复取证——因为"cmdline里有没有这个字符串"这件事的检索证据只应该存在一处,本主题需要的只是这个既有事实,不是重新验证它。
- **与Partition_Layout的边界**:Android安全HAL分区消失清单归Partition_Layout;本主题不重复列这份清单,只在必要时引用其结论。
- **与OTA_Mechanism的边界**:`aktualizr*`等meta-updater服务"存在"这一事实(体现为新增unit)归本主题;这些服务背后的证书管理/更新服务器信任链等运作细节归OTA_Mechanism。
- **为什么UKI签名结论的权威归属仍然是Boot_Flow,即使本篇也讨论TPM/measured-boot相关NEWS**:本主题讨论的NEWS变化(如TPM1.2 PCR measurement移除)是"系统未来若要做measured boot还需要考虑什么"这类前瞻性影响分析,判断对象仍然是"UKI这个容器当前实际有没有签名"这件事——这件事的权威判定不因为话题接近TPM/签名就该重新取证,因为判定所需的证据(UKI机制定义+全局检索)天然属于Boot_Flow已经建立的知识范围(见`Principles.md`for Boot_Flow的详细原理)。本篇只需要在涉及TPM/measured-boot话题时"引用"Boot_Flow的既有结论,提醒读者"当前还没有签名,所以TPM measured boot这条路径目前也谈不上启用",不需要另起一次UKI_SB_KEY检索。

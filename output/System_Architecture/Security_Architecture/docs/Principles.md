# Security_Architecture 原理文档

本文档解释Security_Architecture(SELinux)主题在Qualcomm Linux BSP体系里管什么、为什么要对比它、以及它与相邻主题的分工原理——这是理解`Security_Architecture.md`具体差异结论的前置知识,不涉及downstream(maili)/QLI2.0具体差异结论(结论见`../Security_Architecture.md`)。

## 1. 本主题管的是"强制访问控制(MAC)策略",不是安全的全部

"安全"是一个笼统词,实际拆解开至少包含多个互不相同的机制类别:防篡改(镜像/分区完整性校验)、存储隔离(密钥/凭据分区布局)、进程访问控制(SELinux/AppArmor等MAC机制)、可信执行(TrustZone/QTEE/TUI)、合规声明(SBOM/出口合规文档)。Security_Architecture本文档管的具体是"进程访问控制"这一类——SELinux/refpolicy策略体系整体对照(上游层版本、策略规模、默认启用状态、裁剪机制),以及排查是否存在替代MAC/沙箱隔离机制、合规声明机制的代码侧承接情况。

SELinux这类MAC策略解决的工程问题是"即便一个进程被攻破,它能做的坏事范围有多大"——策略规则数量级(而不只是"有没有")直接反映了这个范围被限制到什么程度,这是为什么System_Architecture专属取证指引特别强调"安全类结论需要给出规则数量级对比,不能只写有/无"。

## 2. 为什么要对比这个主题

downstream(maili)覆盖audio/camera/modem/加密/OTA/诊断等数十个高权限daemon的域定义(661个策略文件),QLI2.0仅覆盖相机测试工具和TrustZone/QTEE两小块(约3个策略点),规模差距在两个数量级以上——这直接关系到安全基线是否弱化这一现实工程问题。但"规模小"不等于"完全空白":对比的价值恰恰在于既不夸大也不低估这个差距,给出一个准确的、按策略点逐条核实过的规模对比,而不是简单地用"有/无"二元判断掩盖了"雏形已存在、但覆盖面远未追平"这一更细致的真相。

## 3. 与相邻主题的分工边界原理

- 镶像完整性校验(dm-verity+AVB)归OTA_Mechanism/Bootargs/Boot_Flow——因为完整性校验解决"镜像有没有被篡改",与SELinux解决"进程能不能做不该做的事"是安全大范畴下两个独立的机制类别,前者关乎启动链信任,后者关乎运行时进程隔离。
- Android安全HAL分区(keystore/secretkeeper/hwcrypto等)归Partition_Layout——因为那是"密钥/凭据存储在哪个分区"的物理布局问题,属于"存储隔离"这一机制类别,不是MAC策略。
- TUI(Trusted UI)生产能力归Layer_Architecture——因为TUI属于可信执行环境的应用层能力,与SELinux这种内核级MAC策略是互补而非同一机制类别(本文档"替代隔离机制排查结果"一节已明确得出"TrustZone/QTEE隔离与SELinux是互补而非替代关系"的结论)。

判断原则:**"安全"这个大范畴下,按具体机制类别(防篡改/存储隔离/进程访问控制/可信执行/合规声明)分工,不能因为都带"安全"二字就笼统地都归入本主题**——这是本轮9个主题里对"避免大而化之的归类"表述最直接的案例,任何新出现的安全相关话题都应先问"它具体属于哪个机制类别",再决定归属。

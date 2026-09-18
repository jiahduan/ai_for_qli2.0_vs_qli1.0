# OTA_Mechanism —— 外部参考资料

已存档OSTree官方文档4份页面(2026-09-09存档,当时环境网络可通过`curl`直连`ostreedev.github.io`,WebFetch工具因域名安全策略被拦截,改用Bash `curl`获取):
- `ostree_introduction.html` —— https://ostreedev.github.io/ostree/introduction/ (总览,提及HTTP用于只读OS树复制,未涉及断点续传细节)
- `ostree_repo.html` —— https://ostreedev.github.io/ostree/repo/ (仓库/对象格式,同样未提及HTTP Range)
- `ostree_copying-deltas.html` —— https://ostreedev.github.io/ostree/copying-deltas/ (static-delta离线更新用法,`ostree static-delta generate`/`apply-offline`命令)
- `ostree_formats.html` —— https://ostreedev.github.io/ostree/formats/ (**关键页**,"OSTree data formats"章节原文:"These deltas are targeted to be a delta between two specific commit objects, including 'bsdiff' and 'rsync-style' deltas **within a content object**"——明确static-delta在content object内部使用bsdiff/rsync-style差分,不只是对象级去重)

**核实结论**(供产出文档`OTA_Mechanism.md`引用,不在本文件展开分析结论本身):
1. static-deltas能否达到接近bsdiff字节级差分——**已核实,官方文档明确使用"bsdiff"一词描述该机制**,原先的"推测"状态可以解除。
2. OSTree pull是否支持HTTP Range分块续传——**已存档4份官方页面并逐一检索`Range`/`resume`/`resumable`/`interrupted download`关键字,全部零命中**。这不是"网络不可达查不到",是这一层级的架构文档确实没有覆盖该实现细节(可能只存在于libostree的HTTP fetcher源码/soup或curl backend实现层面,不在概念性文档里);应更正为"已核实官方架构文档未提及此实现细节,能力是否存在需查源码或更底层文档,不再标注为纯网络受限"。


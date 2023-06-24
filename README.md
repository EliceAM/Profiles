# 个人适用OpenWrt插件配置文件，仅针对供个人使用场景进行更新，不保证可用性。

适用于如下的OpenClash和MosDNS的结构场景，主要解决移动宽带的DNS污染和OpenClash（Redir-Host模式）切换不同国家节点时DNS缓存造成的分流异常


客户端—>AdGuadHome（网页web管理&去广告）—>MosDNS（分流国内外并负责缓存）—>
        
国内—>国内DNS服务器（ttl 600 Cache）

国外—>OpenClash —>国外DNS服务器（ttl 5 no Cache）
              
本配置亦可解决OpenClash的Fake—IP的持久化问题，推荐使用Redir-Host模式

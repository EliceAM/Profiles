# 个人适用的Openwrt MosDNS插件V5版本 自定义配置 

AdGuardHome 直接监听53端口，不使用dnsmasq，dnsmasq监听端口改为54。agh设置上游127.0.0.1:5335，反向dns服务器为127.0.0.1:54

MosDNS 监听端口为5335, 设置上游127.0.0.1:7874 & 国内dot服务器

OpenClash 监听端口为7874

国内请求转发至腾讯阿里dot，修改ttl为600并计入缓存，国外请求转发至OpenClash插件做进一步分流，修改ttl为5不计入缓存，可解决OpenClash Redir-Host模式下切换国家或者节点时不及时刷新DNS缓存导致的各种问题
也可用于解决fakeip模式下的持久化问题

MosDNS管理界面需要手动配置导出以下 GeoData 标签

geosite_tld-cn

geosite_category-games@cn

geosite_icloud

geosite_apple-cn

#兼容OpenWRT内MosDNS的luci管理页面，可直接在 MosDNS/RULE LIST/各个名单 内直接添加自定义规则并直接应用，不再局限于插件本身的【规则列表仅适用于 “内置预设” 配置文件】限制
#由于PTR、黑名单已由下游的AGH提供，白名单会导致上游openclash在特殊情况下分流错误（如mosdns的GeoData和OpenClash的版本不匹配，且刚好访问该网站时）已不再网页管理端支持这三项的修改

# 个人适用的Openwrt MosDNS插件V5版本 自定义配置 

直接对53端口监听，不使用Dnsmasq转发

OpenClash监听端口为7874

国内请求转发至腾讯阿里dot修改ttl为600并计入缓存，国外请求转发至OpenClash插件做进一步分流，并将返回的结果ttl修改为5，不计入缓存以解决OpenClash	Redir-Host模式下切换国家地区时DNS不及时刷新导致的访问问题或fakeip模式的持久化问题


需要手动配置导出以下 GeoSite 标签

category-ads-all

category-games@cn

tld-cn


#兼容OpenWRT内MosDNS的luci管理页面，可直接在 MosDNS/RULE LIST/各个名单 内直接添加自定义规则并直接应用，不再局限于插件本身的【规则列表仅适用于 “内置预设” 配置文件】限制

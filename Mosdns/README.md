# 个人适用的Openwrt MosDNS插件V5版本 自定义配置 

MosDNS 监听端口为6353, 设置上游clash 127.0.0.1:7874 和 国内dns缓存服务器smartdns 
打开MosDNS的DNS转发用来作为Dnsmasq的上游

OpenClash 监听端口为7874

不要使用5353端口！！！
不要使用5353端口！！！
不要使用5353端口！！！

OpenClash 不要开启 fakeip 持久化,不要开启旁路由兼容，不要开启 DNS 劫持，不要绑定网络接口，不要启用流量（域名）探测
建议开启路由本机代理，可以指定LAN接口名称


MosDNS管理界面需要手动配置导出 GeoData 标签
配合定时任务，自动将fallback后归入出国的域名加入greylist，下次解析不走fallback，加快解析响应速度

#PTR、黑名单由mosdns的下游的AGH提供

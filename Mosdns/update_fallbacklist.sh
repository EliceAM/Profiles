#!/bin/sh

# ==================== 配置区域 ====================
MOSDNS_LOG="/var/log/mosdns.log"
TMP_FILE="/tmp/mosdns_extracted_domains.txt"
TMP_EXISTING="/tmp/mosdns_existing_pure.txt"
TMP_COMBINED="/tmp/mosdns_combined_pruned.txt"
GREYLIST_FILE="/etc/mosdns/rule/greylist.txt"
LOG_TAG="HIT_FAKEIP"
# ==================================================

if [ ! -f "$MOSDNS_LOG" ]; then
    exit 1
fi

touch "$GREYLIST_FILE"

# 2. 精准切出日志中的域名
grep "$LOG_TAG" "$MOSDNS_LOG" | awk -F'"qname": "' '{print $2}' | cut -d'"' -f1 | sed 's/\.$//' | tr 'A-Z' 'a-z' | sort -u | sed 's/^/domain:/' > "$TMP_FILE"

if [ ! -s "$TMP_FILE" ]; then
    rm -f "$TMP_FILE"
    exit 0
fi

# 3. 清洗现有的 greylist 文件，过滤掉历史注释和空行
grep -v '^#' "$GREYLIST_FILE" | grep -v '^$' | sort -u > "$TMP_EXISTING"

# 4. 骨灰级核心逻辑：跨类型去重 + 多子域名自动聚合收敛为二层主域名
cat "$TMP_EXISTING" "$TMP_FILE" | awk '
# 编写一个高效提取二层主域名的函数（兼容了常见 .com.cn 等三段式后缀）
function get_base_domain(d,   parts, n) {
    n = split(d, parts, ".");
    if (n <= 2) return d;
    if (parts[n] == "cn" && (parts[n-1] == "com" || parts[n-1] == "net" || parts[n-1] == "org" || parts[n-1] == "edu" || parts[n-1] == "gov")) {
        if (n == 3) return d;
        return parts[n-2] "." parts[n-1] "." parts[n];
    }
    return parts[n-1] "." parts[n];
}

{
    # 分门别类收集所有原始规则
    if ($0 ~ /^domain:/) {
        raw = substr($0, 8);
        if (raw != "") domains[raw] = 1;
    } else if ($0 ~ /^keyword:/) {
        raw = substr($0, 9);
        if (raw != "") keywords[raw] = 1;
    } else if ($0 ~ /^regexp:/) {
        raw = substr($0, 8);
        if (raw != "") regexps[raw] = 1;
    } else if ($0 ~ /^full:/) {
        raw = substr($0, 6);
        if (raw != "") fulls[raw] = 1;
    }
}
END {
    # 步骤 A：初步筛选并统计每个主域名的子域名出现频次
    for (d in domains) {
        # 遵循文档优先级：若同名 full: 已存在，则不参与 domain 统计
        if (d in fulls) continue;

        # 过滤已被已有 keyword 或 regexp 覆盖的域名
        has_k = 0; for (k in keywords) { if (index(d, k) > 0) { has_k = 1; break; } } if (has_k) continue;
        has_r = 0; for (r in regexps) { if (match(d, r)) { has_r = 1; break; } } if (has_r) continue;

        # 计算并累加主域名频次
        base = get_base_domain(d);
        base_count[base]++;
        domain_to_base[d] = base;
        valid_domains[d] = 1;
    }

    # 步骤 B：根据频次决定是“原样输出”还是“聚合精简为二层域名”
    for (d in valid_domains) {
        b = domain_to_base[d];
        if (base_count[b] >= 2) {
            # 关键点：同一个主域下出现了多个不同的子域名，直接精简成二层主域名
            # 降维打击前，同样双重校验该二层主域是否命中高优先级规则
            if (b in fulls) continue;
            has_k = 0; for (k in keywords) { if (index(b, k) > 0) { has_k = 1; break; } } if (has_k) continue;
            has_r = 0; for (r in regexps) { if (match(b, r)) { has_r = 1; break; } } if (has_r) continue;

            if (!printed_base[b]) {
                print "domain:" b;
                printed_base[b] = 1;
            }
        } else {
            # 只有孤零零的一条子域名，原样保留，不盲目扩大拦截面
            print "domain:" d;
        }
    }

    # 步骤 C：原封不动输出其他资产类型
    for (f in fulls)    print "full:" f;
    for (r in regexps) print "regexp:" r;
    for (k in keywords) print "keyword:" k;
}' | sort > "$TMP_COMBINED"

# 5. 智能比对：检查精简去重后的最终列表，与原列表是否有实质变化
if cmp -s "$TMP_EXISTING" "$TMP_COMBINED"; then
    rm -f "$TMP_FILE" "$TMP_EXISTING" "$TMP_COMBINED"
    exit 0
fi

# 6. 有实质更新，写入新规则文件并重启服务
echo "# Last Updated by auto-script on $(date '+%Y-%m-%d %H:%M:%S')" > "${GREYLIST_FILE}.tmp"
cat "$TMP_COMBINED" >> "${GREYLIST_FILE}.tmp"

# 替换原规则文件
mv "${GREYLIST_FILE}.tmp" "$GREYLIST_FILE"

# 清理临时文件
rm -f "$TMP_FILE" "$TMP_EXISTING" "$TMP_COMBINED"

# 对接 luci-app-mosdns 管理插件重启
/etc/init.d/mosdns restart

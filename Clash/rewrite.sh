#!/bin/sh

LOCKFILE="/tmp/rewrite.lock"

# 尝试创建锁文件，防止脚本重复运行
if [ -e "$LOCKFILE" ]; then
    echo "[$(date '+%F %T')] 脚本已在运行中，退出。"
    exit 1
else
    echo "[$(date '+%F %T')] 创建运行锁"
    touch "$LOCKFILE"
fi

# 设置退出时删除锁文件
trap 'rm -f "$LOCKFILE"; exit' INT TERM EXIT

# 延时 20 秒，确保 OpenClash 完全启动
sleep 5

# 定义目标配置文件路径（只处理 /etc/openclash/config 文件夹下的 .yaml 文件）
CONFIG_DIR="/etc/openclash/config"
TARGET_FILES=$(find "$CONFIG_DIR" -type f -name "*.yaml")

MODIFIED=false

# 遍历每个配置文件，检查是否需要修改
for TARGET_FILE in $TARGET_FILES; do
    if grep -q "type: fallback" "$TARGET_FILE"; then
        echo "[$(date '+%F %T')] '$TARGET_FILE' 需要修改。"
        MODIFIED=true
    else
        echo "[$(date '+%F %T')] '$TARGET_FILE' 无需修改。"
    fi
done

# 如果有文件需要修改，执行停止、修改和启动操作
if [ "$MODIFIED" = true ]; then
    echo "[$(date '+%F %T')] 停止 OpenClash。"
    /etc/init.d/openclash stop
    sleep 5

    for TARGET_FILE in $TARGET_FILES; do
        if grep -q "type: fallback" "$TARGET_FILE"; then
            echo "[$(date '+%F %T')] 修改 '$TARGET_FILE'。"
            sed -i 's/type: fallback/type: smart/g' "$TARGET_FILE"
        fi
    done

    echo "[$(date '+%F %T')] 启动 OpenClash。"
    /etc/init.d/openclash restart
    echo "[$(date '+%F %T')] 操作完成。"
else
    echo "[$(date '+%F %T')] 所有文件均无需修改，跳过操作。"
fi

# 等待5秒删除锁文件
sleep 5
rm -f "$LOCKFILE"
echo "[$(date '+%F %T')] 脚本执行结束。"

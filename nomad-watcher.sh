#!/bin/bash

# ============================================================
# التنظيف الذاتي: إصلاح صيغة الويندوز (CRLF) إلى لينكس (LF)
# ============================================================
if grep -q $'\r' "$0"; then
    sed -i 's/\r$//' "$0"
    exec bash "$0" "$@"
fi

# ============================================================
# بيانات تلجرام الخاصة بك (يجب تعبئتها قبل التشغيل)
# Telegram credentials (must be filled before running)
# ============================================================
TOKEN="YOUR_TELEGRAM_BOT_TOKEN"       # ← ضع توكن البوت هنا | Put your bot token here
CHAT_ID="YOUR_TELEGRAM_CHAT_ID"       # ← ضع معرف المحادثة هنا | Put your chat ID here
JOB_NAME="demo-app"                   # ← اسم الـ Job المراد مراقبته | Name of the Nomad job to watch

echo "👀 Starting watcher for job: $JOB_NAME ..."

# دالة مساعدة لجلب معرف (ID) واسم (Name) السيرفر معاً
get_active_node_info() {
    # جلب الـ ID أولاً
    local ALLOC_NODE_ID=$(nomad job allocs "$JOB_NAME" 2>/dev/null | awk '$6 == "running" {print $2}' | head -n1)
    
    if [[ -n "$ALLOC_NODE_ID" ]]; then
        # الاستعلام عن اسم السيرفر باستخدام الـ ID
        local ALLOC_NODE_NAME=$(nomad node status "$ALLOC_NODE_ID" 2>/dev/null | awk '/^Name/ {print $3}')
        echo "${ALLOC_NODE_ID}:${ALLOC_NODE_NAME}"
    else
        echo ":"
    fi
}

# جلب بيانات السيرفر الحالي عند بدء السكربت
CURRENT_INFO=$(get_active_node_info)
CURRENT_ID=$(echo "$CURRENT_INFO" | cut -d':' -f1)
CURRENT_NAME=$(echo "$CURRENT_INFO" | cut -d':' -f2)

if [[ -n "$CURRENT_ID" ]]; then
    echo "✅ App is currently running on: [$CURRENT_NAME] (ID: $CURRENT_ID)"
fi

# حلقة لا نهائية للمراقبة كل 5 ثوانٍ
while true; do
    NEW_INFO=$(get_active_node_info)
    NEW_ID=$(echo "$NEW_INFO" | cut -d':' -f1)
    NEW_NAME=$(echo "$NEW_INFO" | cut -d':' -f2)

    # إذا كان هناك سيرفر جديد، وهو يختلف عن السيرفر القديم
    if [[ -n "$NEW_ID" && "$NEW_ID" != "$CURRENT_ID" ]]; then

        if [[ -n "$CURRENT_ID" ]]; then
            # رسالة الانهيار والانتقال (Failover)
            MSG="🚨 ⚠️ تنبيه طوارئ (Failover) ⚠️

⛔️ السيرفر السابق: [$CURRENT_NAME]
(ID: $CURRENT_ID)
انقطع الاتصال به أو توقف!

✅ النظام تدخل تلقائياً لحماية الخدمة.
🚀 التطبيق تم نقله ويعمل الآن بنجاح على السيرفر البديل:
[$NEW_NAME]
(ID: $NEW_ID)"
        else
            # رسالة التشغيل لأول مرة
            MSG="✅ نظام Nomad:
التطبيق [$JOB_NAME] بدأ العمل بنجاح على السيرفر:
[$NEW_NAME] 
(ID: $NEW_ID)"
        fi

        # إرسال الرسالة عبر API تلجرام
        curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
             -d chat_id="${CHAT_ID}" \
             -d text="${MSG}" > /dev/null

        echo "✅ Telegram Alert Sent! Moved to -> $NEW_NAME"
        
        # تحديث البيانات القديمة بالبيانات الجديدة
        CURRENT_ID=$NEW_ID
        CURRENT_NAME=$NEW_NAME
    fi

    sleep 5
done
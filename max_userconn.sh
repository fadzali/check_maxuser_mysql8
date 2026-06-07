#!/bin/bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

HOST="$1"
MYSQL_USER="$2"
MYSQL_PASS="$3"
TARGET_USER="$4"
WARN="$5"
CRIT="$6"

if [ -z "$TARGET_USER" ]; then
  echo "UNKNOWN - Usage: $0 host mysql_user mysql_pass target_user warn% crit%"
  exit $STATE_UNKNOWN
fi

MYSQL="mysql --ssl-mode=DISABLED -h $HOST -u $MYSQL_USER -p$MYSQL_PASS -N -s"

# ----------------------------
# Get max_user_connections
# ----------------------------
MAX_CONN=$($MYSQL -e "
SELECT IFNULL(max_user_connections,0)
FROM mysql.user
WHERE user='$TARGET_USER'
LIMIT 1;
" 2>/dev/null)

MAX_CONN=${MAX_CONN:-0}

# ----------------------------
# Get current connections (ACCURATE)
# ----------------------------
# Get current connections (ACCURATE)
# using performance_schema
# ----------------------------
CUR_CONN=$($MYSQL -e "
SELECT COUNT(*)
FROM performance_schema.threads
WHERE PROCESSLIST_USER='$TARGET_USER';
" 2>/dev/null)

CUR_CONN=${CUR_CONN:-0}

# ----------------------------
# If unlimited
# ----------------------------
if [ "$MAX_CONN" -eq 0 ] 2>/dev/null; then
  echo "OK - $TARGET_USER connections: $CUR_CONN (unlimited) | connections=$CUR_CONN"
  exit $STATE_OK
fi

# ----------------------------
# Safe percentage calc (no bc/awk crash)
# ----------------------------
PERCENT=$(( CUR_CONN * 100 / MAX_CONN ))

STATE=$STATE_OK
STATUS="OK"

if [ "$PERCENT" -ge "$CRIT" ]; then
  STATE=$STATE_CRITICAL
  STATUS="CRITICAL"
elif [ "$PERCENT" -ge "$WARN" ]; then
  STATE=$STATE_WARNING
  STATUS="WARNING"
fi

echo "$STATUS - $TARGET_USER connections: $CUR_CONN/$MAX_CONN ($PERCENT%) | connections=$CUR_CONN;$WARN;$CRIT;0;$MAX_CONN"
exit $STATE



# using performance_schema
# ----------------------------
CUR_CONN=$($MYSQL -e "
SELECT COUNT(*)
FROM performance_schema.threads
WHERE PROCESSLIST_USER='$TARGET_USER';
" 2>/dev/null)

CUR_CONN=${CUR_CONN:-0}


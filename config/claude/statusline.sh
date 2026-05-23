#!/bin/bash

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
TOK_IN=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
TOK_OUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
FIVE_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_RESETS=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
WEEK_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
WEEK_RESETS=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Build status line parts
parts="[$MODEL] 📂 ${DIR##*/}"

if [ -n "$TOK_IN" ] && [ -n "$TOK_OUT" ]; then
  tok_total=$((TOK_IN + TOK_OUT))
  if [ "$tok_total" -ge 1000000 ]; then
    tok_fmt=$(echo "$tok_total" | awk '{printf "%.1fM", $1/1000000}')
  elif [ "$tok_total" -ge 1000 ]; then
    tok_fmt=$(echo "$tok_total" | awk '{printf "%.1fk", $1/1000}')
  else
    tok_fmt="$tok_total"
  fi
  usage="$tok_fmt"
  if [ -n "$CTX_PCT" ]; then
    ctx_int=$(printf '%.0f' "$CTX_PCT")
    usage="$usage/${ctx_int}%"
  fi
  parts="$parts | $usage"
elif [ -n "$CTX_PCT" ]; then
  ctx_int=$(printf '%.0f' "$CTX_PCT")
  parts="$parts | ${ctx_int}%"
fi

if [ -n "$FIVE_PCT" ]; then
  five_int=$(printf '%.0f' "$FIVE_PCT")
  five_str="5h: ${five_int}%"
  if [ -n "$FIVE_RESETS" ]; then
    five_reset_time=$(date -r "$FIVE_RESETS" +"%H:%M")
    five_str="$five_str resets $five_reset_time"
  fi
  parts="$parts | $five_str"
fi

if [ -n "$WEEK_PCT" ]; then
  week_int=$(printf '%.0f' "$WEEK_PCT")
  week_str="7d: ${week_int}%"
  if [ -n "$WEEK_RESETS" ]; then
    week_reset_time=$(date -r "$WEEK_RESETS" +"%a %H:%M")
    week_str="$week_str resets $week_reset_time"
  fi
  parts="$parts | $week_str"
fi

echo "$parts"

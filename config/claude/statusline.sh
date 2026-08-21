#!/bin/bash

# Renders the Claude Code status line from the JSON status blob Claude sends
# on stdin. Output looks like:
#
#   [Opus 5] 📂 dotfiles | 231.4k/62% | 5h: 18% resets 14:00
#
# A seven day rate limit renders alongside the five hour one, in the same
# style. Everything after the model and directory appears only when Claude
# gives us the numbers behind it.

# shellcheck disable=SC2154
# (Every variable below is assigned by the eval of jq's output, which the
# linter can't see through.)

# Pull every field we need out of the JSON in one pass, as `name=value` lines.
# Fields Claude didn't send come back as empty strings. @sh quotes the values,
# so directories with spaces in them survive the eval.
eval "$(jq -r '
  @sh "model=\(.model.display_name // "")",
  @sh "directory=\(.workspace.current_dir // "")",
  @sh "context_percentage=\(.context_window.used_percentage // "")",
  @sh "input_tokens=\(.context_window.total_input_tokens // "")",
  @sh "output_tokens=\(.context_window.total_output_tokens // "")",
  @sh "five_hour_percentage=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "five_hour_reset=\(.rate_limits.five_hour.resets_at // "")",
  @sh "seven_day_percentage=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "seven_day_reset=\(.rate_limits.seven_day.resets_at // "")"
')"

# Formats a token count compactly, so 5400 becomes "5.4k" and 2345678 becomes
# "2.3M". Counts under 1000 are printed as they are.
function format_token_count {
  local count=$1

  if ((count >= 1000000)); then
    awk -v count="$count" 'BEGIN { printf "%.1fM", count / 1000000 }'
  elif ((count >= 1000)); then
    awk -v count="$count" 'BEGIN { printf "%.1fk", count / 1000 }'
  else
    printf '%d' "$count"
  fi
}

# Renders the context section, like "231.4k/62%". Drops either half when
# Claude didn't send the numbers for it, and renders nothing when both are
# missing.
function format_context {
  local section=""

  if [[ -n $input_tokens && -n $output_tokens ]]; then
    section=$(format_token_count $((input_tokens + output_tokens)))
  fi

  if [[ -n $context_percentage ]]; then
    [[ -n $section ]] && section+="/"
    section+=$(printf '%.0f%%' "$context_percentage")
  fi

  printf '%s' "$section"
}

# Renders a rate limit as "5h: 18% resets 14:00". The reset time is formatted
# with the given `date` format string, and left off when Claude didn't send
# one. Renders nothing without a percentage.
function format_rate_limit {
  local label=$1 percentage=$2 resets_at=$3 reset_format=$4

  [[ -z $percentage ]] && return

  printf '%s: %.0f%%' "$label" "$percentage"

  if [[ -n $resets_at ]]; then
    printf ' resets %s' "$(date -r "$resets_at" +"$reset_format")"
  fi
}

# Joins the sections into a single line separated by pipes, skipping any that
# came back empty.
function join_sections {
  local line=""

  for section in "$@"; do
    [[ -z $section ]] && continue
    [[ -n $line ]] && line+=" | "
    line+="$section"
  done

  echo "$line"
}

join_sections \
  "[$model] 📂 ${directory##*/}" \
  "$(format_context)" \
  "$(format_rate_limit "5h" "$five_hour_percentage" "$five_hour_reset" "%H:%M")" \
  "$(format_rate_limit "7d" "$seven_day_percentage" "$seven_day_reset" "%a %H:%M")"

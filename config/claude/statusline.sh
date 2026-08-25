#!/bin/bash

# Renders the Claude Code status line from the JSON status blob Claude sends
# on stdin. Output looks like:
#
#    …/.dotfiles     main    󰚩 Opus 5    243.4k     ████▒░░░ 62%    5h 18% · 14:00 
#
# Starship draws it, using the `claude-code` profile in
# config/starship/starship.toml, so the status line and the shell prompt share
# one set of colours and shapes. Starship reads the model and the context
# window out of the blob itself.
#
# Two things it can't do are handled here. It doesn't know about rate limits,
# so those are pulled out and handed over as environment variables, which the
# profile picks up as env_var modules. And it works out the directory and git
# state from the path it's given rather than from the blob, so it needs to be
# told which directory Claude is working in.

# shellcheck disable=SC2154
# (Every variable below is assigned by the eval of jq's output, which the
# linter can't see through.)

payload=$(cat)

# Claude reports the model as "Opus 5 (1M context)". The parenthetical says the
# same thing on every line of every session, so it's dropped to keep the capsule
# short. Starship reads the model straight out of the blob, so the name has to
# be shortened here rather than on the way past.
payload=$(printf '%s' "$payload" |
  jq -c 'if .model.display_name
         then .model.display_name |= sub(" \\([^)]*\\)$"; "")
         else . end')

# Pull the fields Starship can't see out of the JSON in one pass, as
# `name=value` lines. Fields Claude didn't send come back as empty strings.
# @sh quotes the values, so directories with spaces in them survive the eval.
eval "$(printf '%s' "$payload" | jq -r '
  @sh "current_dir=\(.workspace.current_dir // "")",
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

# Renders a rate limit as "18% · 14:00", for the capsule to label. The reset
# time is formatted with the given `date` format string, and left off when
# Claude didn't send one. Renders nothing without a percentage.
function format_rate_limit {
  local percentage=$1 resets_at=$2 reset_format=$3

  if [[ -n $percentage ]]; then
    printf '%.0f%%' "$percentage"

    if [[ -n $resets_at ]]; then
      printf ' · %s' "$(date -r "$resets_at" +"$reset_format")"
    fi
  fi
}

# Only export a variable we have something to say about. Starship draws a
# capsule for a variable that's set but empty, which would leave a blank one
# sitting in the status line.
tokens=""
if [[ -n $input_tokens && -n $output_tokens ]]; then
  tokens=$(format_token_count $((input_tokens + output_tokens)))
fi

five_hour=$(format_rate_limit "$five_hour_percentage" "$five_hour_reset" "%H:%M")
seven_day=$(format_rate_limit "$seven_day_percentage" "$seven_day_reset" "%a %H:%M")

[[ -n $tokens ]] && export CLAUDE_TOKENS="$tokens"
[[ -n $five_hour ]] && export CLAUDE_LIMIT_5H="$five_hour"
[[ -n $seven_day ]] && export CLAUDE_LIMIT_7D="$seven_day"

# Both paths need giving. Starship finds the git repo from --path, but takes
# the directory it displays from --logical-path, which otherwise falls back to
# whichever directory Claude happened to launch this script from.
printf '%s' "$payload" |
  starship statusline claude-code --profile claude-code \
    --path "$current_dir" --logical-path "$current_dir"

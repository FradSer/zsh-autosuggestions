
#--------------------------------------------------------------------#
# AI Suggestion Strategy         #
#--------------------------------------------------------------------#
# Queries an OpenAI-compatible LLM API to generate command
# completions based on partial input, working directory, and
# recent shell history.
#

_zsh_autosuggest_strategy_ai_json_escape() {
	# Reset options to defaults and enable LOCAL_OPTIONS
	emulate -L zsh

	local input="$1"
	local output=""
	local char

	for ((i=1; i<=${#input}; i++)); do
		char="${input:$((i-1)):1}"
		case "$char" in
			'\\') output+='\\\\' ;;
			'"') output+='\"' ;;
			$'\n') output+='\n' ;;
			$'\t') output+='\t' ;;
			$'\r') output+='\r' ;;
			[[:cntrl:]]) ;; # Skip other control chars
			*) output+="$char" ;;
		esac
	done

	printf '%s' "$output"
}

_zsh_autosuggest_strategy_ai_gather_context() {
	# Reset options to defaults and enable LOCAL_OPTIONS
	emulate -L zsh

	local max_lines="${ZSH_AUTOSUGGEST_AI_HISTORY_LINES:-20}"
	local prefer_pwd="${ZSH_AUTOSUGGEST_AI_PREFER_PWD_HISTORY:-yes}"
	local pwd_basename="${PWD:t}"
	local -a context_lines
	local -a pwd_lines
	local -a other_lines
	local line

	# Iterate from most recent history
	for line in "${(@On)history}"; do
		# Truncate long lines
		if [[ ${#line} -gt 200 ]]; then
			line="${line:0:200}..."
		fi

		# Categorize by PWD relevance
		if [[ "$prefer_pwd" == "yes" ]] && [[ "$line" == *"$pwd_basename"* || "$line" == *"./"* || "$line" == *"../"* ]]; then
			pwd_lines+=("$line")
		else
			other_lines+=("$line")
		fi
	done

	# Prioritize PWD-relevant lines, then fill with others
	context_lines=("${pwd_lines[@]}" "${other_lines[@]}")
	context_lines=("${(@)context_lines[1,$max_lines]}")

	# Return via reply array
	reply=("${context_lines[@]}")
}

_zsh_autosuggest_strategy_ai_normalize() {
	# Reset options to defaults and enable LOCAL_OPTIONS
	emulate -L zsh

	local response="$1"
	local buffer="$2"
	local result=""

	# Strip \r
	response="${response//$'\r'/}"

	# Strip markdown code fences
	response="${response##\`\`\`*$'\n'}"
	response="${response%%$'\n'\`\`\`}"

	# Strip surrounding quotes
	if [[ "$response" == \"*\" || "$response" == \'*\' ]]; then
		response="${response:1:-1}"
	fi

	# Trim whitespace
	response="${response##[[:space:]]##}"
	response="${response%%[[:space:]]##}"

	# Take first line only
	result="${response%%$'\n'*}"

	# If response starts with buffer, extract suffix
	if [[ "$result" == "$buffer"* ]]; then
		local suffix="${result#$buffer}"
		result="$buffer$suffix"
	# If response looks like a pure suffix, prepend buffer
	elif [[ -n "$buffer" ]] && [[ "$result" != "$buffer"* ]] && [[ "${buffer}${result}" == [[:print:]]* ]]; then
		result="$buffer$result"
	fi

	printf '%s' "$result"
}

_zsh_autosuggest_strategy_ai() {
	# Reset options to defaults and enable LOCAL_OPTIONS
	emulate -L zsh

	typeset -g suggestion
	local buffer="$1"

	# Early return if API key not set (opt-in gate)
	[[ -z "$ZSH_AUTOSUGGEST_AI_API_KEY" ]] && return

	# Early return if curl or jq not available
	[[ -z "${commands[curl]}" ]] || [[ -z "${commands[jq]}" ]] && return

	# Early return if input too short
	local min_input="${ZSH_AUTOSUGGEST_AI_MIN_INPUT:-3}"
	[[ ${#buffer} -lt $min_input ]] && return

	# Gather context
	local -a context
	_zsh_autosuggest_strategy_ai_gather_context
	context=("${reply[@]}")

	# Build context string
	local context_str=""
	for line in "${context[@]}"; do
		if [[ -n "$context_str" ]]; then
			context_str+=", "
		fi
		context_str+="\"$(_zsh_autosuggest_strategy_ai_json_escape "$line")\""
	done

	# Build JSON request body
	local system_prompt="You are a shell command auto-completion engine. Given the user's partial command, working directory, and recent history, predict the complete command. Reply ONLY with the complete command. No explanations, no markdown, no quotes."
	local user_message="Working directory: $PWD\nRecent history: [$context_str]\nPartial command: $buffer"

	local json_body
	json_body=$(printf '{
 "model": "%s",
 "messages": [
  {"role": "system", "content": "%s"},
  {"role": "user", "content": "%s"}
 ],
  "temperature": 0.3,
 "max_tokens": 100
}' \
		"${ZSH_AUTOSUGGEST_AI_MODEL:-gpt-3.5-turbo}" \
		"$(_zsh_autosuggest_strategy_ai_json_escape "$system_prompt")" \
		"$(_zsh_autosuggest_strategy_ai_json_escape "$user_message")")

	# Make API request
	local endpoint="${ZSH_AUTOSUGGEST_AI_ENDPOINT:-https://api.openai.com/v1/chat/completions}"
	local timeout="${ZSH_AUTOSUGGEST_AI_TIMEOUT:-5}"
	local response

	response=$(curl --silent --max-time "$timeout" \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $ZSH_AUTOSUGGEST_AI_API_KEY" \
		-d "$json_body" \
		-w '\n%{http_code}' \
		"$endpoint" 2>/dev/null)

	# Check curl exit status
	[[ $? -ne 0 ]] && return

	# Split response body from HTTP status
	local http_code="${response##*$'\n'}"
	local body="${response%$'\n'*}"

	# Early return on non-2xx status
	[[ "$http_code" != 2* ]] && return

	# Extract content from JSON response
	local content
	content=$(printf '%s' "$body" | jq -r '.choices[0].message.content // empty' 2>/dev/null)

	# Early return if extraction failed
	[[ -z "$content" ]] && return

	# Normalize response
	local normalized
	normalized="$(_zsh_autosuggest_strategy_ai_normalize "$content" "$buffer")"

	# Set suggestion
	[[ -n "$normalized" ]] && suggestion="$normalized"
}

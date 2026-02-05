
#--------------------------------------------------------------------#
# AI Suggestion Strategy   #
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

		# Categorize by PWD relevance - match full path, basename, or PWD-relevant commands
		if [[ "$prefer_pwd" == "yes" ]] && [[ "$line" == *"$PWD"* || "$line" == *"$pwd_basename"* || "$line" == cd* || "$line" == ls* || "$line" == "git "* || "$line" == *"./"* || "$line" == *"../"* ]]; then
			pwd_lines+=("$line")
		else
			other_lines+=("$line")
		fi
	done

	# Cap PWD lines at 2/3 of max to maintain diversity
	local pwd_max=$(( (max_lines * 2) / 3 ))
	local pwd_count=${#pwd_lines}
	[[ $pwd_count -gt $pwd_max ]] && pwd_count=$pwd_max

	# Prioritize PWD-relevant lines, then fill with others
	context_lines=("${(@)pwd_lines[1,$pwd_count]}" "${other_lines[@]}")
	context_lines=("${(@)context_lines[1,$max_lines]}")

	# Return via reply array
	reply=("${context_lines[@]}")
}

_zsh_autosuggest_strategy_ai_gather_env_context() {
	# Reset options to defaults and enable LOCAL_OPTIONS
	emulate -L zsh

	local -A env_info

	# Directory listing (up to 20 entries)
	local dir_contents
	dir_contents=$(command ls -1 2>/dev/null | head -20 | tr '\n' ', ' | sed 's/, $//')
	[[ -n "$dir_contents" ]] && env_info[dir_contents]="$dir_contents"

	# Git branch (try two methods)
	local git_branch
	git_branch=$(command git branch --show-current 2>/dev/null)
	[[ -z "$git_branch" ]] && git_branch=$(command git rev-parse --abbrev-ref HEAD 2>/dev/null)
	[[ -n "$git_branch" ]] && env_info[git_branch]="$git_branch"

	# Git status (up to 10 lines)
	local git_status
	git_status=$(command git status --porcelain 2>/dev/null | head -10 | tr '\n' '; ' | sed 's/; $//')
	[[ -n "$git_status" ]] && env_info[git_status]="$git_status"

	# Return via reply associative array
	typeset -gA reply
	reply=("${(@kv)env_info}")
}

_zsh_autosuggest_strategy_ai_normalize() {
	# Reset options to defaults and enable LOCAL_OPTIONS
	emulate -L zsh

	local response="$1"
	local buffer="$2"
	local result=""

	# Strip \r
	response="${response//$'\r'/}"

	# Strip leading prompt artifacts ($ or >)
	response="${response##\$ }"
	response="${response##> }"

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
	local min_input="${ZSH_AUTOSUGGEST_AI_MIN_INPUT:-0}"
	[[ ${#buffer} -lt $min_input ]] && return

	# Gather history context
	local -a context
	_zsh_autosuggest_strategy_ai_gather_context
	context=("${reply[@]}")

	# Gather environment context
	local -A env_context
	_zsh_autosuggest_strategy_ai_gather_env_context
	env_context=("${(@kv)reply}")

	# Build context string
	local context_str=""
	for line in "${context[@]}"; do
		if [[ -n "$context_str" ]]; then
			context_str+=", "
		fi
		context_str+="\"$(_zsh_autosuggest_strategy_ai_json_escape "$line")\""
	done

	# Determine prompt mode (empty vs non-empty buffer)
	local system_prompt user_message temperature
	if [[ -z "$buffer" ]]; then
		# Empty buffer: predict next command
		system_prompt="You are a shell command prediction engine. Based on the working directory, directory contents, git status, and recent history, suggest the single most likely next command the user wants to run. Reply ONLY with the complete command. No explanations, no markdown, no quotes."
		temperature="0.5"
		user_message="Working directory: $PWD"
		[[ -n "${env_context[dir_contents]}" ]] && user_message+="\nDirectory contents: ${env_context[dir_contents]}"
		[[ -n "${env_context[git_branch]}" ]] && user_message+="\nGit branch: ${env_context[git_branch]}"
		[[ -n "${env_context[git_status]}" ]] && user_message+="\nGit changes: ${env_context[git_status]}"
		user_message+="\nRecent history: [$context_str]"
	else
		# Non-empty buffer: complete partial command
		system_prompt="You are a shell command auto-completion engine. Given the user's partial command, working directory, and recent history, predict the complete command. Reply ONLY with the complete command. No explanations, no markdown, no quotes."
		temperature="0.3"
		user_message="Working directory: $PWD"
		[[ -n "${env_context[dir_contents]}" ]] && user_message+="\nDirectory contents: ${env_context[dir_contents]}"
		[[ -n "${env_context[git_branch]}" ]] && user_message+="\nGit branch: ${env_context[git_branch]}"
		[[ -n "${env_context[git_status]}" ]] && user_message+="\nGit changes: ${env_context[git_status]}"
		user_message+="\nRecent history: [$context_str]"
		user_message+="\nPartial command: $buffer"
	fi

	# Build JSON request body
	local json_body
	json_body=$(printf '{
 "model": "%s",
 "messages": [
 {"role": "system", "content": "%s"},
  {"role": "user", "content": "%s"}
 ],
 "temperature": %s,
 "max_tokens": 100
}' \
		"${ZSH_AUTOSUGGEST_AI_MODEL:-gpt-3.5-turbo}" \
		"$(_zsh_autosuggest_strategy_ai_json_escape "$system_prompt")" \
		"$(_zsh_autosuggest_strategy_ai_json_escape "$user_message")" \
		"$temperature")

	# Make API request
	local base_url="${ZSH_AUTOSUGGEST_AI_ENDPOINT:-https://api.openai.com/v1}"
	local endpoint="${base_url}/chat/completions"
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

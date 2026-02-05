
#--------------------------------------------------------------------#
# Global Configuration Variables                                     #
#--------------------------------------------------------------------#

# Color to use when highlighting suggestion
# Uses format of `region_highlight`
# More info: http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Widgets
(( ! ${+ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE} )) &&
typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# Prefix to use when saving original versions of bound widgets
(( ! ${+ZSH_AUTOSUGGEST_ORIGINAL_WIDGET_PREFIX} )) &&
typeset -g ZSH_AUTOSUGGEST_ORIGINAL_WIDGET_PREFIX=autosuggest-orig-

# Strategies to use to fetch a suggestion
# Will try each strategy in order until a suggestion is returned
(( ! ${+ZSH_AUTOSUGGEST_STRATEGY} )) && {
	typeset -ga ZSH_AUTOSUGGEST_STRATEGY
	ZSH_AUTOSUGGEST_STRATEGY=(history)
}

# Widgets that clear the suggestion
(( ! ${+ZSH_AUTOSUGGEST_CLEAR_WIDGETS} )) && {
	typeset -ga ZSH_AUTOSUGGEST_CLEAR_WIDGETS
	ZSH_AUTOSUGGEST_CLEAR_WIDGETS=(
		history-search-forward
		history-search-backward
		history-beginning-search-forward
		history-beginning-search-backward
		history-beginning-search-forward-end
		history-beginning-search-backward-end
		history-substring-search-up
		history-substring-search-down
		up-line-or-beginning-search
		down-line-or-beginning-search
		up-line-or-history
		down-line-or-history
		accept-line
		copy-earlier-word
	)
}

# Widgets that accept the entire suggestion
(( ! ${+ZSH_AUTOSUGGEST_ACCEPT_WIDGETS} )) && {
	typeset -ga ZSH_AUTOSUGGEST_ACCEPT_WIDGETS
	ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(
		forward-char
		end-of-line
		vi-forward-char
		vi-end-of-line
		vi-add-eol
	)
}

# Widgets that accept the entire suggestion and execute it
(( ! ${+ZSH_AUTOSUGGEST_EXECUTE_WIDGETS} )) && {
	typeset -ga ZSH_AUTOSUGGEST_EXECUTE_WIDGETS
	ZSH_AUTOSUGGEST_EXECUTE_WIDGETS=(
	)
}

# Widgets that accept the suggestion as far as the cursor moves
(( ! ${+ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS} )) && {
	typeset -ga ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS
	ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=(
		forward-word
		emacs-forward-word
		vi-forward-word
		vi-forward-word-end
		vi-forward-blank-word
		vi-forward-blank-word-end
		vi-find-next-char
		vi-find-next-char-skip
	)
}

# Widgets that should be ignored (globbing supported but must be escaped)
(( ! ${+ZSH_AUTOSUGGEST_IGNORE_WIDGETS} )) && {
	typeset -ga ZSH_AUTOSUGGEST_IGNORE_WIDGETS
	ZSH_AUTOSUGGEST_IGNORE_WIDGETS=(
		orig-\*
		beep
		run-help
		set-local-history
		which-command
		yank
		yank-pop
		zle-\*
	)
}

# Pty name for capturing completions for completion suggestion strategy
(( ! ${+ZSH_AUTOSUGGEST_COMPLETIONS_PTY_NAME} )) &&
typeset -g ZSH_AUTOSUGGEST_COMPLETIONS_PTY_NAME=zsh_autosuggest_completion_pty

# AI strategy configuration
# API endpoint for AI suggestions (OpenAI-compatible)
(( ! ${+ZSH_AUTOSUGGEST_AI_ENDPOINT} )) &&
typeset -g ZSH_AUTOSUGGEST_AI_ENDPOINT='https://api.openai.com/v1/chat/completions'

# AI model to use for suggestions
(( ! ${+ZSH_AUTOSUGGEST_AI_MODEL} )) &&
typeset -g ZSH_AUTOSUGGEST_AI_MODEL='gpt-3.5-turbo'

# Timeout in seconds for AI API requests
(( ! ${+ZSH_AUTOSUGGEST_AI_TIMEOUT} )) &&
typeset -g ZSH_AUTOSUGGEST_AI_TIMEOUT=5

# Minimum input length before querying AI
(( ! ${+ZSH_AUTOSUGGEST_AI_MIN_INPUT} )) &&
typeset -g ZSH_AUTOSUGGEST_AI_MIN_INPUT=0

# Number of recent history lines to include as context
(( ! ${+ZSH_AUTOSUGGEST_AI_HISTORY_LINES} )) &&
typeset -g ZSH_AUTOSUGGEST_AI_HISTORY_LINES=20

# Prefer history entries from current directory
(( ! ${+ZSH_AUTOSUGGEST_AI_PREFER_PWD_HISTORY} )) &&
typeset -g ZSH_AUTOSUGGEST_AI_PREFER_PWD_HISTORY=yes

# Allow suggestions on empty buffer (opt-in, for AI strategy)
# Set to any value to enable. Unset by default.
# Uses (( ${+VAR} )) pattern like ZSH_AUTOSUGGEST_MANUAL_REBIND

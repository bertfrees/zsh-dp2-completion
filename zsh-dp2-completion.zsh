# Zsh auto completion for the Daisy Pipeline 2 command line a.k.a. dp2

_dp2() {
	_dp2_read_help
	if (( CURRENT > 2 )); then
		local cmd=${words[2]}
		(( CURRENT-- ))
		shift words
		if [[ ${DP2_CACHE_SCRIPTS[*]} =~ $cmd ]]; then
			_dp2_read_script_help $cmd
			_arguments \
				${(f)"$(_dp2_script_options $cmd)"} \
				'(-b --background -p --persistent)'{-b,--background}'[Runs the job in the background (will be persistent)]' \
				'(-p --persistent)'{-p,--persistent}'[Forces to keep the job data in the server]' \
				'(-q --quiet)'{-q,--quiet}'[Doesn''t show the job messages]'
		else
			case $cmd in
				(help)
					local _f_; _f_() { _wanted dp2-commands expl 'command' compadd $(_dp2_scripts) $(_dp2_general_commands) }
					_arguments ':command:_f_' ;;
				(result | status | delete)
					local _jobs_; _jobs_=$(_dp2_jobs)
					if (( $#_jobs_ )); then
						local _f_; _f_() { _wanted dp2-jobs expl 'job' compadd $_jobs_ }
						_arguments ':job:_f_'
					else _message 'No jobs found'; fi ;;
				(version | jobs | halt) ;;
			esac
		fi
	else
		local _desc_
		_desc_=(${(f)"$(_dp2_scripts_long)"})
		_describe -t dp2-scripts 'Script commands' _desc_
		_desc_=(${(f)"$(_dp2_general_commands_long)"})
		_describe -t dp2-general-commands 'General commands' _desc_
	fi
}

DP2_CACHE_SCRIPTS=()
DP2_CACHE_SCRIPTS_LONG=()
DP2_CACHE_GENERAL_COMMANDS=()
DP2_CACHE_GENERAL_COMMANDS_LONG=()
typeset -A DP2_CACHE_SCRIPT_OPTIONS

_dp2_read_help() {
	if [[ -z $DP2_CACHE_SCRIPTS ]]; then
		local dp2_help; dp2_help=$(dp2 help 2>/dev/null)
		DP2_CACHE_SCRIPTS=$(echo $dp2_help | sed -e '1,/^Script commands:$/d' | sed '1d' | sed -e '/^$/,$d' | sed 's/	.*//' )
		DP2_CACHE_SCRIPTS_LONG=$(echo $dp2_help | sed -e '1,/^Script commands:$/d' | sed '1d' | sed -e '/^$/,$d' | sed 's/:/\\:/g' | sed 's/		*/:/')
		DP2_CACHE_GENERAL_COMMANDS=$(echo $dp2_help | sed -e '1,/^General commands:$/d' | sed '1d' | sed -e '/^$/,$d' | sed 's/	.*//')
		DP2_CACHE_GENERAL_COMMANDS_LONG=$(echo $dp2_help | sed -e '1,/^General commands:$/d' | sed '1d' | sed -e '/^$/,$d' | sed 's/		*/:/')
	fi
}

_dp2_read_script_help() {
	if [[ -z $DP2_CACHE_SCRIPT_OPTIONS[$1] ]]; then
		local script_help script_inputs script_options
		script_help=$(dp2 help $1 2>/dev/null | sed 's/^[ 	]*//' | grep -E '^(--x-|--i-|Desc:|Type:)' | sed 's/^\(--[^ ]*\).*/\1/' \
			| sed 's/^Desc:\(.*\)$/[\1]/' | sed 's/^Type:any.*URI.*/:file:_files/' | sed 's/^Type:\(boolean\)$/:\1:(true false)/' | sed 's/^Type\(.*\)$/:\1: /')
		script_inputs=$(echo $script_help | sed -n '/^--i.*/{N;p;}' | sed '$!N;s/\n//' | sed 's/$/:file:_files/')
		script_options=$(echo $script_help | sed -n '/^--x.*/{N;N;p;}' | sed 'N;N;s!\n!!g')
		DP2_CACHE_SCRIPT_OPTIONS[$1]=$(echo "$script_inputs\n$script_options")
	fi
}

_dp2_scripts() { echo "$DP2_CACHE_SCRIPTS" }
_dp2_scripts_long() { echo "$DP2_CACHE_SCRIPTS_LONG" }
_dp2_general_commands() { echo "$DP2_CACHE_GENERAL_COMMANDS" }
_dp2_general_commands_long() { echo "$DP2_CACHE_GENERAL_COMMANDS_LONG" }
_dp2_script_options() { echo "$DP2_CACHE_SCRIPT_OPTIONS[$1]" }

_dp2_jobs() {
	echo "$(dp2 jobs 2>/dev/null | grep '^\[DP2\] Job Id' | sed 's/^.*://')"
}

zstyle ':completion::complete:dp2::descriptions' format $'\e[01;33m -- %d --\e[0m'
zstyle ':completion::complete:dp2:*' group-name ''

compdef _dp2 dp2

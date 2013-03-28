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
				'(-n --name)'{-n,--name}'[Job''s nice name]:NAME: ' \
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

_comma_separated_files() {
	local -a suf
	compset -P '*,'
	_files
}

_dp2_read_script_help() {
	if [[ -z $DP2_CACHE_SCRIPT_OPTIONS[$1] ]]; then
		DP2_CACHE_SCRIPT_OPTIONS[$1]=$(dp2 help $1 2>/dev/null \
			| sed 's/^[ 	]*//' \
			| grep -Ev '^(Usage|-n|-b|-p|-q)' \
			| sed -e ':a' -e '$!N;s/\n\([^-]\)/ \1/;ta' -e 'P;D' \
			| sed -e 's/^\(--[^ ]*\)  *\[\([^ ][^ ]*\)\]  *\(.*\)$/\1 \2 \3/' \
			| sed -e 's/^\(--[^ ]*\)  *\([^ ][^ ]*\)  *\(.*\)$/\1[\3]:\2:#/' \
			| sed -e 's/^\(.*:input:\)#$/\1_files/' \
			| sed -e 's/^\(.*:output:\)#$/\1_files/' \
			| sed -e 's/^\(.*:input1,input2,input3:\)#$/\1_comma_separated_files/' \
			| sed -e 's/^\(.*:output1,output2,output3:\)#$/\1_comma_separated_files/' \
			| sed -e 's/^\(.*:anyFileURI:\)#$/\1_files/' \
			| sed -e 's|^\(.*:anyDirURI:\)#$|\1_files -/|' \
			| sed -e 's/^\(.*:boolean:\)#$/\1(true false)/' \
			| sed -e 's/^\(.*\)#$/\1 /'
		)
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

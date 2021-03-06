# Zsh auto completion for the Daisy Pipeline 2 command line a.k.a. dp2

_dp2() {
	_dp2_read_help
	if (( CURRENT > 2 )); then
		local cmd=${words[2]}
		(( CURRENT-- ))
		shift words
		if [[ ${_DP2_CACHE_SCRIPTS[*]} =~ $cmd ]]; then
			_dp2_read_script_help $cmd
			_arguments ${(f)"$(_dp2_script_options $cmd)"}
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

_DP2_CACHE_SCRIPTS=()
_DP2_CACHE_SCRIPTS_LONG=()
_DP2_CACHE_GENERAL_COMMANDS=()
_DP2_CACHE_GENERAL_COMMANDS_LONG=()
typeset -A _DP2_CACHE_SCRIPT_OPTIONS

_dp2_read_help() {
	if [[ -z $_DP2_CACHE_SCRIPTS ]]; then
		local dp2_help dp2_help_scripts dp2_help_general_commands;
		dp2_help=$(dp2 help 2>/dev/null)
		dp2_help_scripts=$(echo $dp2_help \
			| sed -e '1,/^Script commands:$/d' | sed '1d' | sed -e '/^$/,$d' \
			| sed -e ':a' -e '$!N;s/\n\( \) */\1/;ta' -e 'P;D')
		dp2_help_general_commands=$(echo $dp2_help \
			| sed -e '1,/^General commands:$/d' | sed '1d' | sed -e '/^$/,$d' \
			| sed -e ':a' -e '$!N;s/\n\( \) */\1/;ta' -e 'P;D')
		_DP2_CACHE_SCRIPTS=$(echo $dp2_help_scripts | sed 's/	.*//' )
		_DP2_CACHE_SCRIPTS_LONG=$(echo $dp2_help_scripts | sed 's/:/\\:/g' | sed 's/		*/:/')
		_DP2_CACHE_GENERAL_COMMANDS=$(echo $dp2_help_general_commands | sed 's/	.*//')
		_DP2_CACHE_GENERAL_COMMANDS_LONG=$(echo $dp2_help_general_commands | sed 's/		*/:/')
	fi
}

_zip_files() {
	_files "$@" -g "*.zip"
}

_comma_separated() {
	local -a suf
	compset -P '*,'
	"${@[$#]}" "${@[1,${#}-1]}"
}

_files_from_data_zip() {
	local data_file
	data_file=$words[$(($words[(i)(-d|--data)] + 1))]
	[[ -z $data_file ]] && return 1
	if [[ $data_file !=  $_DP2_CACHE_DATA_ZIP_NAME ]]; then
		_DP2_CACHE_DATA_ZIP_NAME="$data_file"
		_DP2_CACHE_DATA_ZIP_CONTENT=(${(f)"$(eval zipinfo -1 $_DP2_CACHE_DATA_ZIP_NAME)"})
	fi
	_wanted files-from-data-zip expl 'file from data zip' _multi_parts / _DP2_CACHE_DATA_ZIP_CONTENT && return
}

_dp2_read_script_help() {
	if [[ -z $_DP2_CACHE_SCRIPT_OPTIONS[$1] ]]; then
		local dp2_script_help _input_files
		dp2_script_help=$(dp2 help $1 2>/dev/null)
		if [[ -n $(echo $dp2_script_help | grep '^  *-d, --data') ]]; then
			_input_files() { _files_from_data_zip }
		else
			_input_files() { _files }
		fi
		_DP2_CACHE_SCRIPT_OPTIONS[$1]=$(echo $dp2_script_help \
			| sed -e 's/^ *//' \
			| sed -e 's/^Usage.*$//' \
			| sed -e ':a' -e '$!N;s/\n\([^-]\)/ \1/;ta' -e 'P;D' \
			| sed -e 's/^\(-[^ ,]*\) *, *\(--.*\)$/\1,\2/' \
			| sed -e 's/^\(-[^ ]*\)  *\[\([^ ][^ ]*\)\]  *\(.*\)$/\1 \2 \3/' \
			| sed -e 's/^\(-[bpq][^ ]*\)  *\(.*\)$/\1[\2]/' \
			| sed -e 's/^\(-[^bpq][^ ]*\)  *\([^ ][^ ]*\)  *\(.*\)$/\1[\3]:\2:#/' \
			| sed -e 's/^\(--i.*:input:\)#$/\1_input_files/' \
			| sed -e 's/^\(--i.*:input1,input2,input3:\)#$/\1_comma_separated _input_files/' \
			| sed -e 's/^\(--o.*:output:\)#$/\1_files/' \
			| sed -e 's/^\(--x.*:anyFileURI:\)#$/\1_files/' \
			| sed -e 's|^\(--x.*:anyDirURI:\)#$|\1_files -/|' \
			| sed -e 's/^\(--x.*:boolean:\)#$/\1(true false)/' \
			| sed -e 's/^\(-[fd].*\)#$/\1_zip_files/' \
			| sed -e 's/^\(-.*\)#$/\1 /' \
			| sed -e 's/^\(-[^,]*\),\(--[^\[]*\)\(\[.*\)$/(\2)\1\3\\n(\1)\2\3/' \
			| sed -e 's/(-b)/(-b -p --persistent)/' \
			| sed -e 's/(--background)/(--background -p --persistent)/'
		)
	fi
}

_dp2_scripts() { echo "$_DP2_CACHE_SCRIPTS" }
_dp2_scripts_long() { echo "$_DP2_CACHE_SCRIPTS_LONG" }
_dp2_general_commands() { echo "$_DP2_CACHE_GENERAL_COMMANDS" }
_dp2_general_commands_long() { echo "$_DP2_CACHE_GENERAL_COMMANDS_LONG" }
_dp2_script_options() { echo "$_DP2_CACHE_SCRIPT_OPTIONS[$1]" }

_dp2_jobs() {
	echo "$(dp2 jobs 2>/dev/null | grep '^\[DP2\] Job Id' | sed 's/^.*://')"
}

zstyle ':completion::complete:dp2::descriptions' format $'\e[01;33m -- %d --\e[0m'
zstyle ':completion::complete:dp2:*' group-name ''

compdef _dp2 dp2

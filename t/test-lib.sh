#!/bin/sh

. "$(dirname "$0")"/sharness.sh

GIT_AUTHOR_EMAIL=author@example.com
GIT_AUTHOR_NAME='A U Thor'
GIT_COMMITTER_EMAIL=committer@example.com
GIT_COMMITTER_NAME='C O Mitter'
export GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME
export GIT_COMMITTER_EMAIL GIT_COMMITTER_NAME

unset GIT_EDITOR

LF='
'

commit_file() {
	local filename="$1"
	echo "$2" > $filename &&
	git add -f $filename &&
	git commit -q -m "commit $filename"
}

write_script() {
	cat > "$1" &&
	chmod +x "$1"
}

test_cmp() {
	diff -u "$@"
}

test_must_fail() {
	"$@"
	exit_code=$?
	if test $exit_code = 0; then
		echo >&2 "test_must_fail: command succeeded: $*"
		return 1
	elif test $exit_code -gt 129 -a $exit_code -le 192; then
		echo >&2 "test_must_fail: died by signal: $*"
		return 1
	elif test $exit_code = 127; then
		echo >&2 "test_must_fail: command not found: $*"
		return 1
	fi
	return 0
}

test_when_finished() {
	test_cleanup="{ $*
		} && (exit \"\$eval_ret\"); eval_ret=\$?; $test_cleanup"
}

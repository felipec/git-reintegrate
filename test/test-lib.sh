#!/bin/sh

. ./sharness.sh

GIT_AUTHOR_EMAIL=author@example.com
GIT_AUTHOR_NAME='A U Thor'
GIT_COMMITTER_EMAIL=committer@example.com
GIT_COMMITTER_NAME='C O Mitter'
export GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME
export GIT_COMMITTER_EMAIL GIT_COMMITTER_NAME

unset GIT_EDITOR

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

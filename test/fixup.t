#!/bin/sh

#
# Copyright (C) 2013-2014 Felipe Contreras
# Copyright (C) 2013 John Keeping
#
# This file may be used under the terms of the GNU GPL version 2.
#

test_description='Test the "fixup" instruction'

. ./sharness.sh

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

test_expect_success 'setup branches' '
	git init -q &&
	commit_file base base &&
	git checkout -b branch1 &&
	commit_file branch1 branch1 &&
	git checkout -b branch2 master &&
	commit_file branch2 branch2
'

write_script .git/EDITOR <<\EOF
#!/bin/sh
cat >> "$1" <<EOM
merge branch1

 This merges branch 1.

merge branch2

 This merges branch 2.
EOM
EOF

test_expect_success 'create integration branch' '
	GIT_EDITOR=.git/EDITOR git reintegrate --create --edit --rebuild pu &&
	git checkout HEAD^0 &&
	commit_file fixup fixup &&
	git update-ref refs/merge-fix/branch2 HEAD
'

write_script .git/EDITOR <<\EOF
#!/bin/sh
cat >> "$1" <<EOM
fixup refs/merge-fix/branch2
EOM
EOF

test_expect_success 'rebuild with fixup added' '
	GIT_EDITOR=.git/EDITOR git reintegrate --edit --rebuild pu &&
	git symbolic-ref HEAD > actual &&
	echo refs/heads/pu > expect &&
	test_cmp expect actual &&
	git merge-base --is-ancestor branch1 HEAD &&
	git merge-base --is-ancestor branch2 HEAD
'

test_expect_success 'check fixup applied' '
	echo fixup > expect &&
	test_cmp expect fixup
'

test_expect_success 'check fixup squashed' '
	git log --oneline -- fixup > actual &&
	grep "branch .branch2. into pu" actual &&
	test $(wc -l <actual) = 1 || (
		echo >&2 "Expected only a single commit touching fixup"
		exit 1
	)
'

test_done

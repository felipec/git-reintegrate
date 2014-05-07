#!/bin/sh

#
# Copyright (C) 2013-2014 Felipe Contreras
# Copyright (C) 2013 John Keeping
#
# This file may be used under the terms of the GNU GPL version 2.
#

test_description="Test git reintegrate"

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
	git checkout -b branch1 master &&
	commit_file branch1 branch1 &&
	git checkout -b branch2 master &&
	commit_file branch2 branch2
'

test_expect_success 'create integration branch' '
	git checkout master &&
	git reintegrate --create pu &&
	git reintegrate --cat > actual &&
	echo "base master" > expect &&
	test_cmp expect actual &&
	git symbolic-ref HEAD > actual &&
	echo refs/heads/pu > expect &&
	test_cmp expect actual
'

write_script .git/EDITOR <<\EOF
#!/bin/sh
cat >> "$1" <<EOM
merge branch1

 This merges branch 1.

merge branch2

 This merges branch 2.

. branch3

 "branch3" is ignored for now.
EOM
EOF

check_int() {
	(
	local int=$1 IFS=':'
	while read branch msg
	do
		echo "* Merge branch '$branch' into $int$LF"
		test "$msg" && echo "$msg$LF" || true
	done > expected
	) &&

	git log --merges --format="* %B" > actual &&
	test_cmp expected actual
}

test_expect_success 'add branches to integration branch' '
	GIT_EDITOR=".git/EDITOR" git reintegrate --edit &&
	git reintegrate --rebuild &&
	git merge-base --is-ancestor branch1 HEAD &&
	git merge-base --is-ancestor branch2 HEAD &&
	test_must_fail git merge-base --is-ancestor branch3 HEAD &&
	check_int pu <<-EOF
	branch2:This merges branch 2.
	branch1:This merges branch 1.
	EOF
'

write_script .git/EDITOR <<\EOF
#!/bin/sh
cat >> "$1" <<EOM
merge branch3

  This merges branch 3.
EOM
EOF

test_expect_success 'add another branch and rebuild' '
	git checkout -b branch3 master &&
	commit_file branch3 branch3 &&
	GIT_EDITOR=.git/EDITOR git reintegrate --edit pu &&
	git reintegrate --rebuild pu &&
	git merge-base --is-ancestor branch1 HEAD &&
	git merge-base --is-ancestor branch2 HEAD &&
	git merge-base --is-ancestor branch3 HEAD &&
	check_int pu <<-EOF
	branch3:This merges branch 3.
	branch2:This merges branch 2.
	branch1:This merges branch 1.
	EOF
'

test_expect_success 'do not create empty commits' '
	git rev-parse --verify refs/int/pu > expect &&
	GIT_EDITOR=true git reintegrate --edit &&
	git rev-parse --verify refs/int/pu > actual &&
	test_cmp expect actual
'

test_expect_success 'generate instructions' '
	git init -q tmp &&
	test_when_finished "rm -rf tmp" &&
	(
	cd tmp &&
	commit_file base base &&
	git checkout -b branch1 master &&
	commit_file branch1 branch1 &&
	git checkout -b branch2 master &&
	commit_file branch2 branch2 &&
	git checkout -b branch3 master &&
	commit_file branch3 branch3 &&
	git checkout -b pu master &&
	git merge --no-ff branch1 &&
	git merge --no-ff branch2 &&
	git merge --no-ff branch3 &&
	git reintegrate --generate pu master &&
	git reintegrate --cat > ../actual
	) &&
	cat > expected <<-EOF &&
	base master
	merge branch1
	merge branch2
	merge branch3
	EOF
	test_cmp expected actual
'

write_script .git/EDITOR <<\EOF
#!/bin/sh
cat >> "$1" <<EOM
commit

 Empty commit.
EOM
EOF

test_expect_success 'empty commit' '
	GIT_EDITOR=.git/EDITOR git reintegrate --edit pu &&
	git reintegrate --rebuild pu &&
	git log --format="%B" -1 > actual &&
	cat > expected <<-EOF &&
	Empty commit.

	EOF
	test_cmp expected actual
'

write_script .git/EDITOR <<\EOF
#!/bin/sh
cat > "$1" <<EOM
base master
merge branch1
merge branch2
pause
merge branch3
EOM
EOF

test_expect_success 'pause command' '
	GIT_EDITOR=.git/EDITOR git reintegrate --edit pu &&
	test_must_fail git reintegrate --rebuild pu &&
	check_int pu <<-EOF &&
	branch2:
	branch1:
	EOF
	git reintegrate --continue &&
	check_int pu <<-EOF
	branch3:
	branch2:
	branch1:
	EOF
'

test_done

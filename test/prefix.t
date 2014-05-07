#!/bin/sh

#
# Copyright (C) 2013-2014 Felipe Contreras
# Copyright (C) 2013 John Keeping
#
# This file may be used under the terms of the GNU GPL version 2.
#

test_description="Test git reintegrate prefix support"

. ./sharness.sh

prefix="sub/"
git config --global integration.prefix $prefix

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

test_expect_success 'setup' '
	git init -q &&
	commit_file base base &&
	git checkout -b sub/master master &&
	git checkout -b sub/branch1 sub/master &&
	commit_file branch1 branch1 &&
	git checkout -b sub/branch2 sub/master &&
	commit_file branch2 branch2 &&
	git reintegrate --create pu
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
		echo "* Merge branch '$prefix$branch' into $int$LF"
		test "$msg" && echo "$msg$LF" || true
	done > expected
	) &&

	git log --merges --format="* %B" > actual &&
	test_cmp expected actual
}

test_expect_success 'add branches to integration branch' '
	GIT_EDITOR=".git/EDITOR" git reintegrate --edit pu &&
	git reintegrate --rebuild &&
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
	git checkout -b sub/branch3 master &&
	commit_file branch3 branch3 &&
	GIT_EDITOR=.git/EDITOR git reintegrate --edit pu &&
	git reintegrate --rebuild pu &&
	check_int pu <<-EOF
	branch3:This merges branch 3.
	branch2:This merges branch 2.
	branch1:This merges branch 1.
	EOF
'

test_expect_success 'generate instructions' '
	git init -q tmp &&
	test_when_finished "rm -rf tmp" &&
	(
	cd tmp &&
	commit_file base base &&
	git checkout -b sub/master master &&
	git checkout -b sub/branch1 sub/master &&
	commit_file branch1 branch1 &&
	git checkout -b sub/branch2 sub/master &&
	commit_file branch2 branch2 &&
	git checkout -b sub/branch3 sub/master &&
	commit_file branch3 branch3 &&
	git checkout -b pu sub/master &&
	git merge --no-ff sub/branch1 &&
	git merge --no-ff sub/branch2 &&
	git merge --no-ff sub/branch3 &&
	git reintegrate --generate pu sub/master &&
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

test_done

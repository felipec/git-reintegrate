#!/bin/sh

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
		echo "* Merge branch '$branch' into $int"
		echo "$LF$msg$LF"
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

test_done

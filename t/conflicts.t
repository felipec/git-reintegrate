#!/bin/sh

#
# Copyright (C) 2013-2014 Felipe Contreras
# Copyright (C) 2013 John Keeping
#
# This file may be used under the terms of the GNU GPL version 2.
#

test_description='Test git reintegrage branches with no conflicts'

. ./test-lib.sh

test_expect_success 'setup branches' '
	git init -q &&
	commit_file base base &&
	git checkout -b branch1 &&
	commit_file base branch1 &&
	git checkout -b branch2 master &&
	commit_file base branch2 &&
	git checkout -b branch3 master &&
	commit_file newfile newfile
'

write_script .git/EDITOR <<\EOF
#!/bin/sh
cat > "$1" <<EOM
base master
merge branch1
merge branch2
EOM
EOF

test_expect_success 'create integration branch' '
	git checkout master &&
	GIT_EDITOR=.git/EDITOR git reintegrate --create --edit pu &&
	git symbolic-ref HEAD > actual &&
	echo refs/heads/pu > expect &&
	test_cmp expect actual
'

test_expect_success 'conflict in last branch resolved' '
	test_must_fail git reintegrate --rebuild &&
	git merge-base --is-ancestor branch1 HEAD &&
	test_must_fail git merge-base --is-ancestor branch2 HEAD &&
	echo resolved > base &&
	git add base &&
	git reintegrate --continue > output &&
	cat output &&
	grep -q branch2 output &&
	git merge-base --is-ancestor branch2 HEAD
'

test_expect_success 'conflict in last branch try continue when unresolved' '
	test_must_fail git reintegrate --rebuild &&
	git merge-base --is-ancestor branch1 HEAD &&
	test_must_fail git merge-base --is-ancestor branch2 HEAD &&
	test_must_fail git reintegrate --continue &&
	echo resolved > base &&
	git add base &&
	git reintegrate --continue > output &&
	cat output &&
	grep -q branch2 output &&
	git merge-base --is-ancestor branch2 HEAD
'

test_expect_success 'conflict in last branch and abort' '
	git checkout pu &&
	git reset --hard master &&
	test_must_fail git reintegrate --rebuild &&
	git merge-base --is-ancestor branch1 HEAD &&
	test_must_fail git merge-base --is-ancestor branch2 HEAD &&
	git reintegrate --abort &&
	git rev-parse --verify master > expect &&
	git rev-parse --verify pu > actual &&
	test_cmp expect actual &&
	echo refs/heads/pu > expect &&
	git symbolic-ref HEAD > actual &&
	test_cmp expect actual &&
	test_must_fail git merge-base --is-ancestor branch1 HEAD &&
	test_must_fail git merge-base --is-ancestor branch2 HEAD
'

test_expect_success 'abort does not move other branches' '
	git checkout pu &&
	git reset --hard master &&
	git rev-parse --verify branch1 > expect &&
	test_must_fail git reintegrate --rebuild &&
	git checkout --force branch1 &&
	git reintegrate --abort &&
	git rev-parse --verify branch1 > actual &&
	test_cmp expect actual
'

write_script .git/EDITOR <<\EOF
#!/bin/sh
cat >> "$1" <<EOM
merge branch3
merge branch4
EOM
EOF

test_expect_success 'conflict in middle branch' '
	git checkout -b branch4 master &&
	commit_file b4 b4 &&
	git checkout pu &&
	GIT_EDITOR=.git/EDITOR git reintegrate --edit &&
	test_must_fail git reintegrate --rebuild &&
	git merge-base --is-ancestor branch1 HEAD &&
	test_must_fail git merge-base --is-ancestor branch2 HEAD &&
	echo resolved > base &&
	git add base &&
	git reintegrate --continue > output &&
	cat output &&
	grep -q branch2 output &&
	grep -q branch3 output &&
	git merge-base --is-ancestor branch2 HEAD &&
	git merge-base --is-ancestor branch3 HEAD
'

test_done

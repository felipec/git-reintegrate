#!/bin/sh

#
# Copyright (C) 2014 Felipe Contreras
#
# This file may be used under the terms of the GNU GPL version 2.
#

test_description='Test git reintegrage apply option'

. ./test-lib.sh

test_expect_success 'setup branches' '
	git init -q &&
	commit_file base base &&

	git checkout -b feature-1 master &&
	commit_file feature-1 feature-1 &&
	git checkout -b feature-2 master &&
	commit_file feature-2 feature-2 &&

	git checkout -b next master &&
	git merge --no-ff feature-1 &&
	git merge --no-ff feature-2
'

test_expect_success 'generate integration' '
	git reintegrate --create integration &&
	git reintegrate --add=feature-1 --add=feature-2 &&
	git reintegrate --rebuild &&
	> expected &&
	git diff next integration > actual &&
	test_cmp expected actual
'

test_expect_success 'update integration' '
	git checkout feature-1 &&
	commit_file feature-1-fix feature-1-fix &&
	git reintegrate --rebuild integration &&
	git diff feature-1^..feature-1 > expected &&
	git diff next integration > actual &&
	test_cmp expected actual
'

cat > expected <<EOF
Merge branch 'feature-1' into next
commit feature-1-fix
EOF

test_expect_success 'apply pending' '
	git checkout next &&
	git branch old &&
	git reintegrate --apply integration &&
	git log --format=%s old..next > actual &&
	test_cmp expected actual &&
	> expected &&
	git diff next integration > actual &&
	test_cmp expected actual
'

test_done

#!/bin/sh

#
# Copyright (C) 2021 Hubic SAS
#
# This file may be used under the terms of the GNU GPL version 2.
#

test_description="Test submodule reintegration"

. ./test-lib.sh

test_expect_success 'setup branches' '
	git init -q &&
	git config rerere.enabled true &&
	commit_file base base &&
	git init -q sub &&
	(cd sub && commit_file subbase subbase) &&
	git submodule add -- ./ sub &&
	git commit -q -m "add submodule" &&
	git checkout -b branch1 master &&
	commit_file branch branch1 &&
	git checkout -b branch2 master &&
	commit_file branch branch2 &&
	git checkout -b branch3 master &&
	(cd sub && commit_file subcontents subcontents) &&
	git commit sub -m "submodule change" &&
	git checkout master &&
	git submodule update
'

test_expect_success 'integrate a submodule change' '
	git checkout master &&
	git reintegrate --create pu &&
	git reintegrate --add=branch1 &&
	git reintegrate --apply &&
	git reintegrate --add=branch2 &&
	test_must_fail git reintegrate --apply &&
	echo "branch12" > branch &&
	git add branch &&
	git reintegrate --continue &&
	git reintegrate --add=branch3 &&
	git reintegrate --apply &&
	git submodule update
'

test_expect_success 'reintegrate' '
	git ls-tree HEAD^: > expected &&
	git reintegrate --rebuild --autocontinue &&
	git ls-tree HEAD^: > actual &&
	test_cmp expected actual
'

test_done

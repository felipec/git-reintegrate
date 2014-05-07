#!bash

_git_reintegrate () {
	case "$cur" in
	--add=*)
		__gitcomp_nl "$(__git_refs)" "" "${cur##--add=}"
		return
		;;
	-*)
		__gitcomp "
			--create --edit --rebuild --continue --abort
			--generate --cat --status
			--add= --prefix=
			--autocontinue"
		return
		;;
	esac

	__gitcomp_nl "$(git --git-dir="$(__gitdir)" \
		for-each-ref --format='%(refname)' refs/int | sed -e 's#^refs/int/##')"
}

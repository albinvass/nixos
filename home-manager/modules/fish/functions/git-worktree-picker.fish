function git-worktree-picker
    set -l worktree (tv git-worktrees)
    if test -n "$worktree"
        cd $worktree
        commandline -f repaint
    end
end

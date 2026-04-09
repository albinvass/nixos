function git-worktree-picker
    set -l worktree (tv --source-command "git worktree list --porcelain | grep '^worktree' | cut -d' ' -f2-" --preview-command "cd '{}' && git log --oneline -10 --color=always && echo && git status --short")
    if test -n "$worktree"
        cd $worktree
    end
    commandline -f repaint
end

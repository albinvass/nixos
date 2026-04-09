function sesh-kill
    set -l session (tv --source-command "sesh list -id | grep -v scratch" --source-output "{split: :1}" --no-preview --ansi)
    if test -n "$session"
        tmux kill-session -t $session
    end
end

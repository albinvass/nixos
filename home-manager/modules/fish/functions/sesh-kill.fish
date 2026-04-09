function sesh-kill
    set -l current (tmux display-message -p '#S')
    set -l session (tv --source-command "fish -c sesh-list" --source-output "{split: :1}" --no-preview --ansi --no-sort)
    if test -n "$session"
        if test "$session" = "$current"
            tmux switch-client -n
        end
        tmux kill-session -t $session
    end
end

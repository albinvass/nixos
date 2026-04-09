function sesh-kill
    set -l current (tmux display-message -p '#S')
    set -l sessions (tv --source-command "sesh list -it | grep -v scratch" --source-output "{split: :1}" --preview-command "fish -c 'sesh-preview {}'" --ansi --no-sort)
    if test -z "$sessions"
        return
    end
    # If killing the current session, switch away first
    if contains -- "$current" $sessions
        tmux switch-client -n
    end
    for session in $sessions
        tmux kill-session -t "$session"
    end
end

function sesh-connect-picker
    set -l session (tv --source-command "sesh-list" --source-output "{split: :1}" --no-preview --ansi)
    if test -n "$session"
        sesh connect $session
    end
end

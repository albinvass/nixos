function sesh-connect-picker
    set -l session (tv --source-command "fish -c sesh-list" --source-output "{split: :1}" --no-preview --ansi --no-sort)
    if test -n "$session"
        sesh connect $session
    end
end

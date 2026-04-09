function sesh-connect
    set -l session (tv --source-command "sesh list -id | grep -v scratch" --source-output "{split: :1}" --no-preview --ansi)
    if test -n "$session"
        sesh connect $session
    end
end

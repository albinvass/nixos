function sesh-connect
    set -l session (tv --source-command "sesh list -id" --no-preview --ansi)
    if test -n "$session"
        sesh connect $session
    end
end

function sesh-list
    set -l current (tmux display-message -p '#S')
    for line in (sesh list -id | grep -v scratch)
        set -l name (string split ' ' -- $line)[-1]
        if test "$name" = "$current"
            echo "$line (current)"
        else
            echo "$line"
        end
    end
end

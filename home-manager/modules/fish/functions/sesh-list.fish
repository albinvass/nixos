function sesh-list
    set -l current (tmux display-message -p '#S')
    set -l current_line
    set -l tmux_sessions

    # Tmux sessions from sesh (with icons, no zoxide)
    for line in (sesh list -itd | grep -v scratch)
        set -l name (string split ' ' -- $line)[-1]
        if test "$name" = "$current"
            set current_line "$line (current)"
        else
            set -a tmux_sessions "$line"
        end
    end

    # Print current session first
    if test -n "$current_line"
        echo $current_line
    end

    # Print other tmux sessions
    for line in $tmux_sessions
        echo $line
    end

    # Git repos from zoxide
    for d in (zoxide query -l)
        if test -d "$d/.git"
            echo $d
        end
    end
end

function sesh-preview
    set -l entry $argv[1]

    set -l clean (string replace -r '\s*\(current\)$' '' -- $entry)

    if string match -qr '^[/~]' -- $clean
        if test -e "$clean/.git"
            git -C $clean log --oneline --graph --color=always -20
        else
            ls -la $clean
        end
    else
        set -l session_name (string split ' ' -- $clean)[-1]
        echo ""
    end
end

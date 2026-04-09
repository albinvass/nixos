function sesh-connect-picker
    set -l selection (tv --source-command "fish -c sesh-list" --preview-command "fish -c 'sesh-preview \"{}\"'" --ansi --no-sort)
    if test -n "$selection"
        # Remove "(current)" suffix if present
        set selection (string replace -r '\s*\(current\)$' '' -- $selection)
        # If it starts with / or ~, it's a path — use as-is
        # Otherwise it's an icon-prefixed session name — take the last word
        if string match -qr '^[/~]' -- $selection
            sesh connect $selection
        else
            sesh connect (string split ' ' -- $selection)[-1]
        end
    end
end

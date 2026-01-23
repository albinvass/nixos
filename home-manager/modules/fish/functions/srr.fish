function srr --argument-names before after
     rg "$before" --vimgrep | cut -d: -f 1 | xargs sed -i "s/$before/$after/"
end

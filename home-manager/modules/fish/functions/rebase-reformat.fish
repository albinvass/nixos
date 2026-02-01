function rebase-reformat --argument-names revision
  set reformat_exec $argv[2..-1]

  git rebase $revision \
    --exec "\
  $reformat_exec && \
  git add -u && \
  git commit --allow-empty --fixup HEAD && \
  git revert --no-commit HEAD && \
  git commit --allow-empty --no-edit\
  "

  set VIM_DELETE_FIRST_COMMIT_MESSAGE "'g/^# This is the commit message #2:/1,.+1d'"
  set VIM_SAVE "'wq'"
  set VIM_DELETE_COMMENTS "'g/^#/d'"
  set VIM_DELETE_TWO_LAST_LINES "'normal! Gdk'"
  set VIM_PICK_TO_FIXUP "'g/^\w* \w* \(# \)\?fixup!/s/^pick/fixup/'"
  set VIM_MAKE_SQUASH_BELOW_REVERT "'g/^pick \w* \(# \)\?Revert \"fixup!/normal! j0ces'"

  env \
    GIT_EDITOR="vim --noplugin -es +$VIM_DELETE_FIRST_COMMIT_MESSAGE +$VIM_SAVE" \
    GIT_SEQUENCE_EDITOR="vim --noplugin -es +$VIM_DELETE_COMMENTS +$VIM_DELETE_TWO_LAST_LINES +$VIM_PICK_TO_FIXUP +$VIM_MAKE_SQUASH_BELOW_REVERT +$VIM_SAVE" \
    git rebase -i $revision
end

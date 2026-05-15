# Prompt
execx($(starship init xonsh))

# Directory jumper
execx($(zoxide init xonsh))

# Git aliases (mirroring fish)
aliases['gau'] = 'git add --update'
aliases['gd'] = 'git diff'
aliases['gst'] = 'git status'
aliases['gpr'] = 'git pull --rebase'
aliases['glol'] = "git log --graph --pretty=%Cred%h%Creset\\ -%C(auto)%d%Creset\\ %s\\ %Cgreen(%ar)\\ %C(bold\\ blue)<%an>%Creset"
aliases['gcn!'] = 'git commit -v --no-edit --amend'
aliases['gpristine'] = 'git reset --hard && git clean -dffx'

@aliases.register('gpsup')
def _gpsup(args):
    branch = $(git branch --show-current).strip()
    ![git push --set-upstream origin @(branch) @(args)]

# cd -> z (zoxide)
aliases['cd'] = 'z'

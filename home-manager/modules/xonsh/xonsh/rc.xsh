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

# television: Ctrl-T smart autocomplete, Ctrl-R history picker
import subprocess as _tv_subprocess

def _tv_run(cmd):
    try:
        r = _tv_subprocess.run(cmd, stdout=_tv_subprocess.PIPE, text=True)
    except FileNotFoundError:
        return ''
    return r.stdout.strip()

@events.on_ptk_create
def _tv_keybindings(bindings, **kw):
    from prompt_toolkit.keys import Keys
    from prompt_toolkit.application.run_in_terminal import run_in_terminal

    @bindings.add(Keys.ControlT)
    def _tv_smart(event):
        buf = event.current_buffer
        prefix = buf.text[: buf.cursor_position]
        cmd = ['tv', '.', '--autocomplete-prompt', prefix,
               '--inline', '--no-status-bar']
        def _insert():
            out = _tv_run(cmd)
            if out:
                buf.insert_text(out + ' ')
        run_in_terminal(_insert)

    @bindings.add(Keys.ControlR)
    def _tv_history(event):
        buf = event.current_buffer
        # Flush the in-memory buffer to disk so tv sees this session's commands.
        # at_exit=True makes the flush synchronous; flush() default is threaded.
        __xonsh__.history.flush(at_exit=True)
        cmd = ['tv', 'xonsh-history', '--input', buf.text,
               '--inline', '--no-status-bar']
        def _replace():
            out = _tv_run(cmd)
            if out:
                buf.text = out
                buf.cursor_position = len(out)
        run_in_terminal(_replace)

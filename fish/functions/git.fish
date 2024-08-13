function git
    if test "$argv[1]" = "push"
        if not set -q SSH_AUTH_SOCK
            echo "GIT SSH AGENT HELPER: ssh agent not started. restart xorg with `ssh-agent startx`"
        end

        set identities (ssh-add -l 2>/dev/null)
        if test "$identities" = "The agent has no identities."
            echo "GIT SSH AGENT HELPER: ssh agent has no identities. trying to add..."
            ssh-add
        end
    end

    command git $argv
end

function lid --description "реакция systemd-logind на закрытие крышки"
    set -l conf /etc/systemd/logind.conf.d/10-lid.conf
    set -l stale /etc/systemd/logind.conf.d/10-lid-hibernate.conf
    set -l bus org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager
    set -l action $argv[1]
    set -l mode

    if test -z "$action"
        set action status
    end

    switch $action
        case status
            for prop in HandleLidSwitch HandleLidSwitchExternalPower HandleLidSwitchDocked
                set -l val (busctl get-property $bus $prop | string replace -r '^s "(.*)"$' '$1')
                if test -z "$val"
                    set val "suspend (default)"
                end
                printf '%-30s %s\n' $prop $val
            end
            return 0
        case off ignore
            set mode ignore
        case on
            set mode suspend
        case suspend hibernate poweroff lock
            set mode $action
        case '*'
            echo "usage: lid [status|off|on|suspend|hibernate|poweroff|lock]" >&2
            return 1
    end

    printf '%s\n' '[Login]' "HandleLidSwitch=$mode" "HandleLidSwitchExternalPower=$mode" \
        "HandleLidSwitchDocked=$mode" | sudo tee $conf >/dev/null
    or return 1

    # дроп-ин из ~/.config был симлинком в /home, а logind работает с ProtectHome=yes -
    # для него он всегда был битым, поэтому убираем
    if test -L $stale; or test -e $stale
        sudo rm -f $stale
    end

    sudo systemctl reload systemd-logind
    or return 1

    echo "lid: $mode"
end

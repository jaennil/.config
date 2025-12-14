function stage-dns
    nmcli connection modify Kommo ipv4.dns "10.13.245.31"
    nmcli connection modify Kommo ipv4.ignore-auto-dns yes
    nmcli connection down Kommo && nmcli connection up Kommo
end

function default-dns
    nmcli connection modify Kommo ipv4.ignore-auto-dns no
    nmcli connection modify Kommo ipv4.dns ""
    nmcli connection down Kommo && nmcli connection up Kommo
end

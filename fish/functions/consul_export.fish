function consul_export
    docker compose exec consul consul kv export crm > .docker/dev/consul_kv_dev.json
    sed -i 's/\t/  /g' .docker/dev/consul_kv_dev.json
end

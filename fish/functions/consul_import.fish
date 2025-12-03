function consul_import
    docker cp .docker/dev/consul_kv_dev.json amojo-consul-1:/tmp
    docker compose exec consul consul kv import @/tmp/consul_kv_dev.json
end

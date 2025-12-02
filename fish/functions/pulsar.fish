function pulsar
    docker compose exec broker pulsar-admin tenants create amojo-local-ru
    docker compose exec broker pulsar-admin namespaces create amojo-local-ru/v3
    docker compose restart scheduler
end

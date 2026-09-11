function claude-review
    # Аккаунт для Daily Ticket Review: тот же конфиг-каталог, что в юните
    # kompas-ticket-review.service. Логин разово: claude-review auth login
    env CLAUDE_CONFIG_DIR=$HOME/.claude-review claude $argv
end

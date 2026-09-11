function dwhere --description 'Show which compose folder each docker container was launched from'
    set -l fmt '%-30s %-9s %s\n'

    if set -q argv[1]
        # Details for one container
        for c in $argv
            echo "=== $c ==="
            docker inspect $c -f 'project: {{index .Config.Labels "com.docker.compose.project"}}
service: {{index .Config.Labels "com.docker.compose.service"}}
workdir: {{index .Config.Labels "com.docker.compose.project.working_dir"}}
config:  {{index .Config.Labels "com.docker.compose.project.config_files"}}
restart: {{.HostConfig.RestartPolicy.Name}}
status:  {{.State.Status}}' 2>/dev/null
            or echo "no such container"
        end
        return
    end

    # Table for all running containers
    printf $fmt CONTAINER RESTART WORKDIR
    printf $fmt --------- ------- -------
    for c in (docker ps --format '{{.Names}}')
        set -l wd (docker inspect $c -f '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' 2>/dev/null)
        set -l rs (docker inspect $c -f '{{.HostConfig.RestartPolicy.Name}}' 2>/dev/null)
        test -n "$wd"; or set wd '(not compose)'
        printf $fmt $c $rs $wd
    end
end

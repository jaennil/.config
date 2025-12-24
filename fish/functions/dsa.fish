function dsa --description 'docker stop all running containers'
    docker stop (docker ps -q)
end

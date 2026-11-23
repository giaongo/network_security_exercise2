for lab_host in pc1 llm-server agent-runner printer proxy remote-user; do
    alias "$lab_host"="docker exec -it $lab_host bash"
done
unset lab_host

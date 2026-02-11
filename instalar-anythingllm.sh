###criar as pastas antes

mkdir -p storage logs

###dar permissão 

chown -R 1000:1000 storage logs
chmod -R 755 storage logs

###rodar o Docker composse
https://github.com/LuanLucasTS/docker/blob/main/docker-compose/compose-anythingllm.yml

###liberar o acesso de todos os hots

systemctl stop ollama

#colar no editor
[Service]
Environment="OLLAMA_HOST=0.0.0.0"

#executar
sudo systemctl daemon-reexec
sudo systemctl restart ollama

#teste local
curl http://localhost:11434/api/tags

#teste container
docker exec -it anythingllm bash
curl http://192.168.1.24:11434/api/tags







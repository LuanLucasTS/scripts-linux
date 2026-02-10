dnf update -y
dnf install -y curl zstd
curl -fsSL https://ollama.com/install.sh | sh
sudo systemctl enable ollama
sudo systemctl start ollama
systemctl status ollama
ollama run llama3
ollama run phi3

mkdir -p ~/.docker/cli-plugins
curl -sSfL https://raw.githubusercontent.com/docker/scout-cli/main/install.sh | sh -s -- -b ~/.docker/cli-plugins
chmod +x ~/.docker/cli-plugins/docker-scout
docker scout --help

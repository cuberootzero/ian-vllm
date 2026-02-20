#Multiarch build and push (adjust as necessary for local build without unnecessary archs)
docker buildx build --push -t yikching/vllm-openai:v1.16.0rc2-cu130 --platform=linux/amd64,linux/arm64 .

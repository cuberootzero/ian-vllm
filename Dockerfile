FROM vllm/vllm-openai:cu130-nightly-5bff999d12dd061c102381b0c9c5d364c5953ea2
RUN pip install --no-cache-dir fastsafetensors
COPY alt-nai-entry.sh ./
ENTRYPOINT ["./alt-nai-entry.sh"]

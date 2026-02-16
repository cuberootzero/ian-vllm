# Deploy Instructions
Assuming Helm Chart is extracted to `./nai-core/`.
Replace lines 157-159 in `nai-core/values.yaml` with the following:

      # supportedVLLMImage in model catalog
      supportedVLLMImage: docker.io/yikching/vllm-openai
      supportedVLLMCPUImageTag: v0.16.0rc2-cu130
      supportedVLLMGPUImageTag: v0.16.0rc2-cu130

Re-run `helm upgrade` to push the changes
 
    helm upgrade --install nai-core ./nai-core --version=2.5.0 -n nai-system --create-namespace --wait \
    [usual helm parameters follows]

Re-apply SSL certificate (assumes self-signed cert used previously)

    kubectl patch gateway nai-ingress-gateway -n nai-system --type='json' -p='[{"op": "replace", "path": "/spec/listeners/1/tls/certificateRefs/0/name", "value": "nai-letsencrypt-certificate"}]'
Proceed to resume endpoint in Web UI (if endpoint was already configured)

    Endpoint -> Action -> Resume
Have fun!

NOTE1: While not tested, `alt-nai-entry.sh` should work with both 2.5 & 2.6 (future), it is able to handle the different the presence and absence of `--model` argument automatically.

NOTE2: vLLM 0.15.1 docker image have library conflict issues with Blackwell, this is resolved in vLLM 0.16.2rc2 docker image (and hence used here).

# vLLM Argument Customisation
In the current release, Web UI doesn't allow custom vLLM argument.

`override.env` is a file that can be placed in the relevant NFS mount point (where predictor container `/mnt/models` points to) to change vLLM arguments in a persistent manner.

For example, `--gpu_memory_utilization=0.9` is vLLM default and this might be undesirable on unified memory platforms like GB10.
A closer value to the model type like `--gpu_memory_utilization=0.7` can be placed in `override.env`

`alt-nai-entry.sh` inside the vLLM image will take care of parsing `override.env`.

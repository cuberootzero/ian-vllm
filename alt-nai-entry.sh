#!/bin/bash

# --- 0. Debug: Print Raw Arguments ---
echo "DEBUG: Raw arguments received from K8s:"
printf "'%s' " "$@"
echo ""

# --- 1. Detect and Fix Single String Arguments ---
if [[ $# -eq 1 ]] && [[ "$1" == *"--"* ]] && [[ "$1" == *" "* ]]; then
    echo "DEBUG: Detected single string argument. Splitting..."
    set -- $1
fi

PASSTHROUGH_ARGS=()
OVERRIDE_ARGS=()
MODEL_ROOT=""
COMMAND="vllm serve"

# --- 2. Initialize Overrides (Top Priority) ---
# Added first so it is at the "top" of the override list
OVERRIDE_ARGS+=("--load-format=fastsafetensors")

# --- 3. Process Input Arguments ---
# Check for Implicit Model Path (First Argument)
if [[ -n "$1" && "$1" != -* ]]; then
    MODEL_ROOT="$1"
    shift 
fi

# Parse Remaining Arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --model)
            if [[ -n "$2" && "$2" != -* ]]; then
                MODEL_ROOT="$2"
                shift 
                shift 
            else
                echo "Error: --model flag provided but no value found."
                exit 1
            fi
            ;;
        --model=*)
            # Handle --model=/path/to/model
            val="${key#*=}"
            MODEL_ROOT="$val"
            shift 
            ;;
        *)
            PASSTHROUGH_ARGS+=("$1")
            shift 
            ;;
    esac
done

# --- 4. Validate Model Root ---
if [ -z "$MODEL_ROOT" ]; then
    echo "Error: No model path provided."
    echo "Usage: ./launch.sh [MODEL_PATH] [ARGS]"
    exit 1
fi

CLEAN_ROOT="${MODEL_ROOT%/}"

# --- 5. Modify Model Path (Find Snapshot) ---
if [ ! -d "$CLEAN_ROOT/snapshots" ]; then
    echo "Error: Directory '$CLEAN_ROOT/snapshots' does not exist."
    exit 1
fi

MODIFIED_MODEL_PATH=$(ls -d "$CLEAN_ROOT/snapshots/"* 2>/dev/null | head -n 1)

if [ -z "$MODIFIED_MODEL_PATH" ]; then
    echo "Error: No snapshot found in $CLEAN_ROOT/snapshots/"
    exit 1
fi

# --- 6. Process Override File ---
ENV_FILE="$CLEAN_ROOT/override.env"

if [ -f "$ENV_FILE" ]; then
    echo "Loading overrides from: $ENV_FILE"
    while IFS= read -r line || [ -n "$line" ]; do
        line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        if [[ -z "$line" || "$line" == \#* ]]; then continue; fi
        OVERRIDE_ARGS+=("$line")
    done < "$ENV_FILE"
fi

# --- 7. Print Final Command ---
echo "----------------------------------------------------------------"
echo "DEBUG: Final Executed Command:"
echo "----------------------------------------------------------------"
# Using [*] to print array elements separated by spaces
echo "$COMMAND $MODIFIED_MODEL_PATH ${PASSTHROUGH_ARGS[*]} ${OVERRIDE_ARGS[*]}"
echo "----------------------------------------------------------------"

# --- 8. Execute ---
exec $COMMAND \
    "$MODIFIED_MODEL_PATH" \
    "${PASSTHROUGH_ARGS[@]}" \
    "${OVERRIDE_ARGS[@]}"

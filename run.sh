#!/bin/bash
set -e
source /venv/main/bin/activate

WORKSPACE=${WORKSPACE:-/workspace}
COMFYUI_DIR="${WORKSPACE}/ComfyUI"

echo "Start provisioning..."

APT_PACKAGES=()
PIP_PACKAGES=()

NODES=(
    "https://github.com/kijai/ComfyUI-WanVideoWrapper"
    "https://github.com/chflame163/ComfyUI_LayerStyle"
    "https://github.com/yolain/ComfyUI-Easy-Use"
    "https://github.com/kijai/ComfyUI-KJNodes"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    "https://github.com/kijai/ComfyUI-segment-anything-2"
    "https://github.com/cubiq/ComfyUI_essentials"
    "https://github.com/fq393/ComfyUI-ZMG-Nodes"
    "https://github.com/kijai/ComfyUI-WanAnimatePreprocess"
    "https://github.com/rgthree/rgthree-comfy"
    "https://github.com/jnxmx/ComfyUI_HuggingFace_Downloader"
    "https://github.com/hanjangma41/NEW-UTILSs.git"
    "https://github.com/plugcrypt/CRT-Nodes.git"
    "https://github.com/evanspearman/ComfyMath.git"
    "https://github.com/teskor-hub/comfyui-teskors-utils.git"
    "https://github.com/reasj2/comfyui-animator-nodes.git"
)

CLIP_VISION_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
)

TEXT_ENCODER_MODELS=(
    "https://huggingface.co/f5aiteam/CLIP/resolve/main/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
)

VAE_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
)

DIFFUSION_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors"
)

LORA_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors"
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
    "https://huggingface.co/alibaba-pai/Wan2.2-Fun-Reward-LoRAs/resolve/main/Wan2.2-Fun-A14B-InP-low-noise-HPS2.1.safetensors"
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Pusa/Wan21_PusaV1_LoRA_14B_rank512_bf16.safetensors"
)

CONTROLNET_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/controlnet/wan21_u3c_controlnet_fp16.safetensors"
)

DETECTION_MODELS=(
    "https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx"
    "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_data.bin"
    "https://huggingface.co/Kijai/vitpose_comfy/resolve/main/onnx/vitpose_h_wholebody_model.onnx"
)

UPSCALER_MODELS=(
    "https://huggingface.co/GerbyHorty76/videoloras/resolve/main/4xUltrasharp_4xUltrasharpV10.pt"
)

function provisioning_start() {
    provisioning_get_apt_packages
    provisioning_clone_comfyui
    provisioning_install_base_reqs
    provisioning_get_nodes
    provisioning_get_pip_packages

    provisioning_get_files "${COMFYUI_DIR}/models/clip_vision"      "${CLIP_VISION_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/text_encoders"    "${TEXT_ENCODER_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/vae"              "${VAE_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/diffusion_models" "${DIFFUSION_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/loras"            "${LORA_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/controlnet"       "${CONTROLNET_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/detection"        "${DETECTION_MODELS[@]}"
    provisioning_get_files "${COMFYUI_DIR}/models/upscale_models"   "${UPSCALER_MODELS[@]}"

    provisioning_make_aliases

    echo "Provisioning complete."
}

function provisioning_clone_comfyui() {
    if [[ ! -d "${COMFYUI_DIR}" ]]; then
        git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}"
    fi
    cd "${COMFYUI_DIR}"
}

function provisioning_install_base_reqs() {
    if [[ -f requirements.txt ]]; then
        pip install --no-cache-dir -r requirements.txt
    fi
}

function provisioning_get_apt_packages() {
    if [[ ${#APT_PACKAGES[@]} -gt 0 ]]; then
        sudo apt update && sudo apt install -y "${APT_PACKAGES[@]}"
    fi
}

function provisioning_get_pip_packages() {
    if [[ ${#PIP_PACKAGES[@]} -gt 0 ]]; then
        pip install --no-cache-dir "${PIP_PACKAGES[@]}"
    fi
}

function provisioning_get_nodes() {
    mkdir -p "${COMFYUI_DIR}/custom_nodes"
    cd "${COMFYUI_DIR}/custom_nodes"

    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        dir="${dir%.git}"
        path="./${dir}"

        if [[ -d "$path" ]]; then
            echo "Updating node: $dir"
            (cd "$path" && git pull --ff-only 2>/dev/null || { git fetch && git reset --hard origin/HEAD; })
        else
            echo "Cloning node: $dir"
            git clone "$repo" "$path" --recursive || echo " [!] Clone failed: $repo"
        fi

        requirements="${path}/requirements.txt"
        if [[ -f "$requirements" ]]; then
            echo "Installing deps for $dir..."
            pip install --no-cache-dir -r "$requirements" || echo " [!] pip requirements failed for $dir"
        fi
    done

    pip install --no-cache-dir opencv-contrib-python psutil || true
}

function provisioning_get_files() {
    if [[ $# -lt 2 ]]; then return; fi
    local dir="$1"
    shift
    local files=("$@")

    mkdir -p "$dir"
    echo "Download ${#files[@]} file(s) -> $dir"

    for url in "${files[@]}"; do
        echo "-> $url"
        local auth_header=""
        if [[ -n "$HF_TOKEN" && "$url" =~ huggingface\.co ]]; then
            auth_header="--header=Authorization: Bearer $HF_TOKEN"
        elif [[ -n "$CIVITAI_TOKEN" && "$url" =~ civitai\.com ]]; then
            auth_header="--header=Authorization: Bearer $CIVITAI_TOKEN"
        fi

        wget $auth_header -nc --content-disposition --show-progress -e dotbytes=4M -P "$dir" "$url" || echo " [!] Download failed: $url"
        echo ""
    done
}

function provisioning_make_aliases() {
    mkdir -p "${COMFYUI_DIR}/models/clip_vision"
    mkdir -p "${COMFYUI_DIR}/models/text_encoders"
    mkdir -p "${COMFYUI_DIR}/models/vae"
    mkdir -p "${COMFYUI_DIR}/models/diffusion_models"
    mkdir -p "${COMFYUI_DIR}/models/loras"
    mkdir -p "${COMFYUI_DIR}/models/controlnet"

    ln -sf "${COMFYUI_DIR}/models/clip_vision/clip_vision_h.safetensors" \
          "${COMFYUI_DIR}/models/clip_vision/klip_vision.safetensors" || true

    ln -sf "${COMFYUI_DIR}/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
          "${COMFYUI_DIR}/models/text_encoders/text_enc.safetensors" || true

    ln -sf "${COMFYUI_DIR}/models/vae/wan_2.1_vae.safetensors" \
          "${COMFYUI_DIR}/models/vae/vae.safetensors" || true

    ln -sf "${COMFYUI_DIR}/models/diffusion_models/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors" \
          "${COMFYUI_DIR}/models/diffusion_models/WanModel.safetensors" || true

    ln -sf "${COMFYUI_DIR}/models/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors" \
          "${COMFYUI_DIR}/models/loras/light.safetensors" || true

    ln -sf "${COMFYUI_DIR}/models/loras/Wan2.2-Fun-A14B-InP-low-noise-HPS2.1.safetensors" \
          "${COMFYUI_DIR}/models/loras/wan.reworked.safetensors" || true

    ln -sf "${COMFYUI_DIR}/models/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" \
          "${COMFYUI_DIR}/models/loras/WanFun.reworked.safetensors" || true

    ln -sf "${COMFYUI_DIR}/models/loras/Wan21_PusaV1_LoRA_14B_rank512_bf16.safetensors" \
          "${COMFYUI_DIR}/models/loras/WanPusa.safetensors" || true

    ln -sf "${COMFYUI_DIR}/models/controlnet/wan21_u3c_controlnet_fp16.safetensors" \
          "${COMFYUI_DIR}/models/controlnet/Wan21_Uni3C_controlnet_fp16.safetensors" || true
}

if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi

echo "Script done!"
cd "${COMFYUI_DIR}"

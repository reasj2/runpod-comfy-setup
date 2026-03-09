#!/bin/bash
set -Eeuo pipefail

source /venv/main/bin/activate

WORKSPACE="${WORKSPACE:-/workspace}"
COMFYUI_DIR="${WORKSPACE}/ComfyUI"
PERSONAL_NODES_REPO="https://github.com/reasj2/comfyui-animator-nodes.git"
PERSONAL_TMP_DIR="/tmp/reasj2-comfyui-animator-nodes"

echo "Start provisioning..."

APT_PACKAGES=()
PIP_PACKAGES=()

# These are repo-based nodes installed normally
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

log() {
    echo "[INFO] $*"
}

warn() {
    echo "[WARN] $*" >&2
}

provisioning_start() {
    provisioning_get_apt_packages
    provisioning_clone_comfyui
    provisioning_install_base_reqs
    provisioning_get_nodes
    provisioning_get_personal_nodes
    provisioning_install_all_node_requirements
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

    log "Provisioning complete."
}

provisioning_clone_comfyui() {
    mkdir -p "${WORKSPACE}"

    if [[ ! -d "${COMFYUI_DIR}/.git" ]]; then
        log "Cloning ComfyUI..."
        git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}"
    else
        log "ComfyUI already exists, updating..."
        (
            cd "${COMFYUI_DIR}" || exit 1
            git pull --ff-only || warn "Could not fast-forward ComfyUI, keeping existing checkout"
        )
    fi

    cd "${COMFYUI_DIR}" || exit 1
}

provisioning_install_base_reqs() {
    cd "${COMFYUI_DIR}" || exit 1

    if [[ -f "requirements.txt" ]]; then
        log "Installing ComfyUI requirements..."
        pip install --no-cache-dir -r requirements.txt
    else
        warn "requirements.txt not found in ${COMFYUI_DIR}"
    fi
}

provisioning_get_apt_packages() {
    if [[ ${#APT_PACKAGES[@]} -gt 0 ]]; then
        log "Installing apt packages..."
        sudo apt update
        sudo apt install -y "${APT_PACKAGES[@]}"
    fi
}

provisioning_get_pip_packages() {
    if [[ ${#PIP_PACKAGES[@]} -gt 0 ]]; then
        log "Installing extra pip packages..."
        pip install --no-cache-dir "${PIP_PACKAGES[@]}"
    fi
}

provisioning_get_nodes() {
    mkdir -p "${COMFYUI_DIR}/custom_nodes"
    cd "${COMFYUI_DIR}/custom_nodes" || exit 1

    for repo in "${NODES[@]}"; do
        local dir path
        dir="${repo##*/}"
        dir="${dir%.git}"
        path="${COMFYUI_DIR}/custom_nodes/${dir}"

        if [[ -d "${path}/.git" ]]; then
            log "Updating node: ${dir}"
            (
                cd "${path}" || exit 1
                git pull --ff-only 2>/dev/null || {
                    warn "Fast-forward pull failed for ${dir}, resetting to origin/HEAD"
                    git fetch --all --prune
                    git reset --hard origin/HEAD
                    git submodule update --init --recursive
                }
            )
        else
            log "Cloning node: ${dir}"
            git clone --recursive "${repo}" "${path}" || {
                warn "Clone failed: ${repo}"
                continue
            }
        fi
    done
}

provisioning_get_personal_nodes() {
    log "Installing nodes from your GitHub repo..."

    rm -rf "${PERSONAL_TMP_DIR}"
    git clone --depth 1 "${PERSONAL_NODES_REPO}" "${PERSONAL_TMP_DIR}" || {
        warn "Failed to clone personal nodes repo"
        return 0
    }

    mkdir -p "${COMFYUI_DIR}/custom_nodes"

    # Copy every top-level directory from your repo into custom_nodes,
    # skipping repo metadata and junk folders.
    find "${PERSONAL_TMP_DIR}" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
        local name
        name="$(basename "${dir}")"

        case "${name}" in
            .git|.github|__pycache__)
                continue
                ;;
        esac

        log "Copying personal node folder: ${name}"
        rm -rf "${COMFYUI_DIR}/custom_nodes/${name}"
        cp -R "${dir}" "${COMFYUI_DIR}/custom_nodes/${name}"
    done

    # If the repo root itself is also a custom node package (your original one),
    # copy root-level python files into its own folder.
    if compgen -G "${PERSONAL_TMP_DIR}/*.py" > /dev/null || [[ -f "${PERSONAL_TMP_DIR}/__init__.py" ]]; then
        local root_node_dir="${COMFYUI_DIR}/custom_nodes/reasj2-comfyui-animator-nodes"
        mkdir -p "${root_node_dir}"

        find "${PERSONAL_TMP_DIR}" -maxdepth 1 -type f \( \
            -name "*.py" -o \
            -name "requirements.txt" -o \
            -name "README*" \
        \) -exec cp {} "${root_node_dir}/" \;

        log "Copied root-level personal node files into: reasj2-comfyui-animator-nodes"
    fi
}

provisioning_install_all_node_requirements() {
    log "Installing node requirements..."

    find "${COMFYUI_DIR}/custom_nodes" -name requirements.txt -type f | while read -r req; do
        log "Installing deps from ${req}"
        pip install --no-cache-dir -r "${req}" || warn "Failed requirements: ${req}"
    done

    pip install --no-cache-dir opencv-contrib-python psutil || warn "Failed installing shared extra packages"
}

provisioning_get_files() {
    if [[ $# -lt 2 ]]; then
        return 0
    fi

    local dir="$1"
    shift
    local files=("$@")

    mkdir -p "${dir}"
    log "Downloading ${#files[@]} file(s) into ${dir}"

    for url in "${files[@]}"; do
        log "Downloading: ${url}"

        if [[ -n "${HF_TOKEN:-}" && "${url}" =~ huggingface\.co ]]; then
            wget --header="Authorization: Bearer ${HF_TOKEN}" \
                -nc --content-disposition --show-progress -e dotbytes=4M \
                -P "${dir}" "${url}" || warn "Download failed: ${url}"
        elif [[ -n "${CIVITAI_TOKEN:-}" && "${url}" =~ civitai\.com ]]; then
            wget --header="Authorization: Bearer ${CIVITAI_TOKEN}" \
                -nc --content-disposition --show-progress -e dotbytes=4M \
                -P "${dir}" "${url}" || warn "Download failed: ${url}"
        else
            wget -nc --content-disposition --show-progress -e dotbytes=4M \
                -P "${dir}" "${url}" || warn "Download failed: ${url}"
        fi

        echo
    done
}

provisioning_make_aliases() {
    mkdir -p "${COMFYUI_DIR}/models/clip_vision"
    mkdir -p "${COMFYUI_DIR}/models/text_encoders"
    mkdir -p "${COMFYUI_DIR}/models/vae"
    mkdir -p "${COMFYUI_DIR}/models/diffusion_models"
    mkdir -p "${COMFYUI_DIR}/models/loras"
    mkdir -p "${COMFYUI_DIR}/models/controlnet"

    ln -sf "${COMFYUI_DIR}/models/clip_vision/clip_vision_h.safetensors" \
           "${COMFYUI_DIR}/models/clip_vision/klip_vision.safetensors"

    ln -sf "${COMFYUI_DIR}/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
           "${COMFYUI_DIR}/models/text_encoders/text_enc.safetensors"

    ln -sf "${COMFYUI_DIR}/models/vae/wan_2.1_vae.safetensors" \
           "${COMFYUI_DIR}/models/vae/vae.safetensors"

    ln -sf "${COMFYUI_DIR}/models/diffusion_models/Wan2_2-Animate-14B_fp8_scaled_e4m3fn_KJ_v2.safetensors" \
           "${COMFYUI_DIR}/models/diffusion_models/WanModel.safetensors"

    ln -sf "${COMFYUI_DIR}/models/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors" \
           "${COMFYUI_DIR}/models/loras/light.safetensors"

    ln -sf "${COMFYUI_DIR}/models/loras/Wan2.2-Fun-A14B-InP-low-noise-HPS2.1.safetensors" \
           "${COMFYUI_DIR}/models/loras/wan.reworked.safetensors"

    ln -sf "${COMFYUI_DIR}/models/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" \
           "${COMFYUI_DIR}/models/loras/WanFun.reworked.safetensors"

    ln -sf "${COMFYUI_DIR}/models/loras/Wan21_PusaV1_LoRA_14B_rank512_bf16.safetensors" \
           "${COMFYUI_DIR}/models/loras/WanPusa.safetensors"

    if [[ -f "${COMFYUI_DIR}/models/controlnet/wan21_u3c_controlnet_fp16.safetensors" ]]; then
        cp -f "${COMFYUI_DIR}/models/controlnet/wan21_u3c_controlnet_fp16.safetensors" \
              "${COMFYUI_DIR}/models/controlnet/Wan21_Uni3C_controlnet_fp16.safetensors"
    fi
}

main() {
    provisioning_start
    cd "${COMFYUI_DIR}" || exit 1
    log "Script done!"
}

main "$@"

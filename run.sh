#!/usr/bin/env bash
set -e

cd /workspace/ComfyUI/custom_nodes

clone_if_missing () {
  local url="$1"
  local dir="$2"
  if [ ! -d "$dir" ]; then
    git clone "$url" "$dir"
  fi
}

clone_if_missing https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git ComfyUI-VideoHelperSuite
clone_if_missing https://github.com/kijai/ComfyUI-KJNodes.git ComfyUI-KJNodes
clone_if_missing https://github.com/ltdrdata/ComfyUI-Manager.git ComfyUI-Manager
clone_if_missing https://github.com/zhangp365/ComfyUI-ZMG-Nodes.git ComfyUI-ZMG-Nodes
clone_if_missing https://github.com/chflame163/ComfyUI_LayerStyle.git ComfyUI_LayerStyle
clone_if_missing https://github.com/yolain/ComfyUI-Easy-Use.git ComfyUI-Easy-Use
clone_if_missing https://github.com/kijai/ComfyUI-WanVideoWrapper.git ComfyUI-WanVideoWrapper
clone_if_missing https://github.com/kijai/ComfyUI-WanAnimatePreprocess.git ComfyUI-WanAnimatePreprocess
clone_if_missing https://github.com/storyicon/comfyui_segment_anything_2.git ComfyUI-segment-anything-2
clone_if_missing https://github.com/rgthree/rgthree-comfy.git rgthree-comfy
clone_if_missing https://github.com/evanspearman/ComfyMath.git ComfyMath
clone_if_missing https://github.com/crystian/CRT-Nodes.git crt-nodes

clone_if_missing https://github.com/reasj2/comfyui-animator-nodes.git comfyui-animator-nodes

find /workspace/ComfyUI/custom_nodes -name requirements.txt -exec /venv/main/bin/python -m pip install -r {} \; || true

/venv/main/bin/python -m pip install opencv-contrib-python || true

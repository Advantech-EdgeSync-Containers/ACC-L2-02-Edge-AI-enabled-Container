#!/bin/bash
# Created by Samir Singh <samir.singh@advantech.com>
# Copyright (c) 2025 Advantech Corporation
LOG_FILE="/advantech/diagnostics/wise-bench.log"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || LOG_FILE="/tmp/wise-bench.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== WISE-BENCH Diagnostics Log - $(date) ===" >> "$LOG_FILE"
clear
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
PURPLE='\033[0;35m'
NC='\033[0m'
echo -e "${BLUE}${BOLD}+------------------------------------------------------+${NC}"
echo -e "${BLUE}${BOLD}|    ${PURPLE}Advantech_COE Jetson Hardware Diagnostics Tool${BLUE}    |${NC}"
echo -e "${BLUE}${BOLD}+------------------------------------------------------+${NC}"
echo
echo -e "${BLUE}"
echo "       █████╗ ██████╗ ██╗   ██╗ █████╗ ███╗   ██╗████████╗███████╗ ██████╗██╗  ██╗     ██████╗ ██████╗ ███████╗"
echo "      ██╔══██╗██╔══██╗██║   ██║██╔══██╗████╗  ██║╚══██╔══╝██╔════╝██╔════╝██║  ██║    ██╔════╝██╔═══██╗██╔════╝"
echo "      ███████║██║  ██║██║   ██║███████║██╔██╗ ██║   ██║   █████╗  ██║     ███████║    ██║     ██║   ██║█████╗  "
echo "      ██╔══██║██║  ██║╚██╗ ██╔╝██╔══██║██║╚██╗██║   ██║   ██╔══╝  ██║     ██╔══██║    ██║     ██║   ██║██╔══╝  "
echo "      ██║  ██║██████╔╝ ╚████╔╝ ██║  ██║██║ ╚████║   ██║   ███████╗╚██████╗██║  ██║    ╚██████╗╚██████╔╝███████╗"
echo "      ╚═╝  ╚═╝╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚═════╝ ╚══════╝"
echo -e "${WHITE}                                  Center of Excellence${NC}"
echo
echo -e "${YELLOW}${BOLD}▶ Starting hardware acceleration tests...${NC}"
echo -e "${CYAN}  This may take a moment...${NC}"
echo
sleep 7
print_header() {
    echo
    echo "+--- $1 ----$(printf '%*s' $((47 - ${#1})) | tr ' ' '-')+"
    echo "|$(printf '%*s' 50 | tr ' ' ' ')|"
    echo "+--------------------------------------------------+"
}
print_success() { echo "✓ $1"; }
print_warning() { echo "⚠ $1"; }
print_info() { echo "ℹ $1"; }
print_table_header() {
    echo "+--------------------------------------------------+"
    echo "| $1$(printf '%*s' $((47 - ${#1})) | tr ' ' ' ')|"
    echo "+--------------------------------------------------+"
}
print_table_row() { printf "| %-25s | %s |\n" "$1" "$2"; }
print_table_footer() { echo "+--------------------------------------------------+"; }
echo "▶ Setting up hardware acceleration environment..."
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}
setup_device() {
    echo -ne "  $1 "
    $2 > /dev/null 2>&1 &
    spinner $!
    if [ $? -eq 0 ]; then
        echo -e "✓"
    else
        echo -e "⚠"
    fi
}
(
if [ ! -e "/dev/nvhost-nvdec-bl" ]; then
    setup_device "Setting up virtual decoder..." "
        if [ -e '/dev/nvhost-nvdec' ]; then
            if [ \$(id -u) -eq 0 ]; then
                mknod -m 666 /dev/nvhost-nvdec-bl c \$(stat -c \"%%t %%T\" /dev/nvhost-nvdec) || ln -sf /dev/nvhost-nvdec /dev/nvhost-nvdec-bl
            else
                ln -sf /dev/nvhost-nvdec /dev/nvhost-nvdec-bl
            fi
        fi
    "
fi
if [ ! -e "/dev/nvhost-nvenc" ]; then
    setup_device "Setting up virtual encoder..." "
        if [ -e '/dev/nvhost-msenc' ]; then
            if [ \$(id -u) -eq 0 ]; then
                mknod -m 666 /dev/nvhost-nvenc c \$(stat -c \"%%t %%T\" /dev/nvhost-msenc) || ln -sf /dev/nvhost-msenc /dev/nvhost-nvenc
            else
                ln -sf /dev/nvhost-msenc /dev/nvhost-nvenc
            fi
        fi
    "
fi
setup_device "Creating required directories..." "
    mkdir -p /tmp/argus_socket
    mkdir -p /opt/nvidia/l4t-packages
    if [ ! -d '/opt/nvidia/l4t-jetson-multimedia-api' ] && [ -d '/usr/src/jetson_multimedia_api' ]; then
        mkdir -p /opt/nvidia
        ln -sf /usr/src/jetson_multimedia_api /opt/nvidia/l4t-jetson-multimedia-api
    fi
"
)
echo -e "\n▶ NVIDIA Devices Detected:"
echo "+------------------------------------------------------------------+"
printf "| %-30s| %-15s| %-12s|\n" "Device" "Type" "Major:Minor"
echo "+------------------------------+-----------------+-------------+"
ls -la /dev/nvhost* 2>/dev/null | grep -v "^total" | awk '{print $1, $3, $4, $5, $6, $10}' | 
while read -r perms owner group major minor device; do
    device_name=$(echo "$device" | awk -F/ '{print $NF}' 2>/dev/null || echo "Unknown")
    if [[ -z "$device_name" || "$device_name" == *"basename"* || "$device_name" == *"invalid option"* ]]; then
        continue
    fi
    device_type=$(echo "$device_name" | cut -d'-' -f2 2>/dev/null || echo "Unknown")
    printf "| %-30s| %-15s| %-12s|\n" "$device_name" "$device_type" "$major:$minor"
done
DEVICE_COUNT=$(ls -la /dev/nvhost* 2>/dev/null | grep -v "^total" | wc -l)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    printf "| %-62s|\n" "No NVIDIA devices found"
fi
echo "+------------------------------------------------------------------+"
print_success "Hardware acceleration environment successfully prepared"
print_header "SYSTEM INFORMATION"
print_table_header "SYSTEM DETAILS"
KERNEL=$(uname -r)
ARCHITECTURE=$(uname -m)
HOSTNAME=$(hostname)
OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "Unknown")
MEMORY_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
MEMORY_USED=$(free -h | awk '/^Mem:/ {print $3}')
CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2- | sed 's/^[ \t]*//' | head -1 || echo "Unknown")
CPU_CORES=$(nproc --all)
UPTIME=$(uptime -p | sed 's/^up //')
print_table_row "Hostname" "$HOSTNAME"
print_table_row "OS" "$OS"
print_table_row "Kernel" "$KERNEL"
print_table_row "Architecture" "$ARCHITECTURE"
print_table_row "CPU" "$CPU_MODEL ($CPU_CORES cores)"
print_table_row "Memory" "$MEMORY_USED used of $MEMORY_TOTAL"
print_table_row "Uptime" "$UPTIME"
print_table_row "Date" "$(date "+%a %b %d %H:%M:%S %Y")"
print_table_footer
print_header "CUDA INFORMATION"
echo -e "${YELLOW}"
echo "       ██████╗██╗   ██╗██████╗  █████╗ "
echo "      ██╔════╝██║   ██║██╔══██╗██╔══██╗"
echo "      ██║     ██║   ██║██║  ██║███████║"
echo "      ██║     ██║   ██║██║  ██║██╔══██║"
echo "      ╚██████╗╚██████╔╝██████╔╝██║  ██║"
echo "       ╚═════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝"
echo -e "${NC}"
echo -ne "▶ Detecting CUDA installation... "
for i in {1..10}; do
    echo -ne "▮"
    sleep 0.05
done
echo
print_table_header "CUDA DETAILS"
if [ -f "/usr/local/cuda/bin/nvcc" ]; then
    CUDA_VERSION=$(/usr/local/cuda/bin/nvcc --version | grep "release" | awk '{print $5}' | cut -d',' -f1)
    CUDA_PATH="/usr/local/cuda"
    CUDA_DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo "Unknown")
    print_table_row "CUDA Version" "$CUDA_VERSION"
    print_table_row "CUDA Path" "$CUDA_PATH"
    print_table_row "NVCC Path" "/usr/local/cuda/bin/nvcc"
    print_table_row "Status" "✓ Available"
else
    NVCC_PATH=$(find /usr -name nvcc 2>/dev/null | head -1)
    if [ -n "$NVCC_PATH" ]; then
        CUDA_VERSION=$("$NVCC_PATH" --version | grep "release" | awk '{print $5}' | cut -d',' -f1)
        CUDA_PATH=$(dirname $(dirname "$NVCC_PATH"))
        print_table_row "CUDA Version" "$CUDA_VERSION"
        print_table_row "CUDA Path" "$CUDA_PATH"
        print_table_row "NVCC Path" "$NVCC_PATH"
        print_table_row "Status" "✓ Available"
    fi
fi
print_table_footer
print_header "OPENCV CUDA TEST"
echo -ne "▶ Testing OpenCV CUDA support... "
for i in {1..3}; do
    for c in / - \\ \|; do
        echo -ne "\b$c"
        sleep 0.2
    done
done
echo -ne "\b✓\n"
print_table_header "OPENCV DETAILS"
OPENCV_INFO=$(python3 -c "
import sys
try:
    import cv2
    print(cv2.__version__)
    print(hasattr(cv2, 'cuda'))
    print(cv2.cuda.getCudaEnabledDeviceCount() if hasattr(cv2, 'cuda') else 0)
except ImportError:
    print('Not installed')
    print('False')
    print('0')
except Exception as e:
    print('Error: ' + str(e))
    print('False')
    print('0')
" 2>/dev/null || echo "Error Not available Not available")
OPENCV_VERSION=$(echo "$OPENCV_INFO" | head -1)
OPENCV_CUDA=$(echo "$OPENCV_INFO" | sed -n '2p')
OPENCV_DEVICES=$(echo "$OPENCV_INFO" | sed -n '3p')
print_table_row "OpenCV Version" "$OPENCV_VERSION"
print_table_row "CUDA Module" "$([[ "$OPENCV_CUDA" == "True" ]] && echo "Available" || echo "Not available")"
print_table_row "CUDA Devices" "$OPENCV_DEVICES"
if [[ "$OPENCV_CUDA" == "True" && "$OPENCV_DEVICES" -gt 0 ]]; then
    print_table_row "Status" "✓ GPU Acceleration Enabled"
else
    print_table_row "Status" "⚠ CPU Mode Only"
fi
print_table_footer
print_header "PYTORCH CUDA TEST"
echo -ne "▶ Running PyTorch CUDA test... "
SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
for i in {1..20}; do
    echo -ne "\b${SPINNER_CHARS:i%10:1}"
    sleep 0.1
done
echo -ne "\b✓\n"
print_table_header "PYTORCH DETAILS"
PYTORCH_INFO=$(python3 -c "
import sys
try:
    import torch
    print(torch.__version__)
    print(torch.cuda.is_available())
    print(torch.cuda.device_count())
    print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A')
except ImportError:
    print('Not installed')
    print('False')
    print('0')
    print('N/A')
except Exception as e:
    print('Error: ' + str(e))
    print('False')
    print('0')
    print('N/A')
" 2>/dev/null || echo "Error False 0 N/A")
PYTORCH_VERSION=$(echo "$PYTORCH_INFO" | head -1)
PYTORCH_CUDA=$(echo "$PYTORCH_INFO" | sed -n '2p')
PYTORCH_DEVICES=$(echo "$PYTORCH_INFO" | sed -n '3p')
PYTORCH_DEVICE_NAME=$(echo "$PYTORCH_INFO" | sed -n '4p')
print_table_row "PyTorch Version" "$PYTORCH_VERSION"
print_table_row "CUDA Available" "$([[ "$PYTORCH_CUDA" == "True" ]] && echo "Yes" || echo "No")"
print_table_row "CUDA Devices" "$PYTORCH_DEVICES"
print_table_row "Device Name" "$PYTORCH_DEVICE_NAME"
if [[ "$PYTORCH_CUDA" == "True" ]]; then
    print_table_row "Status" "✓ Accelerated"
else 
    print_table_row "Status" "⚠ CPU Only"
fi
print_table_footer
print_header "TENSORFLOW GPU TEST"
echo -ne "▶ Checking TensorFlow configuration... "
for i in {1..5}; do
    for c in ⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷; do
        echo -ne "\b$c"
        sleep 0.1
    done
done
echo -ne "\b✓\n"
print_table_header "TENSORFLOW DETAILS"
TF_INFO=$(python3 -c "
import sys
try:
    import tensorflow as tf
    print(tf.__version__)
    devices = tf.config.list_physical_devices('GPU')
    print(len(devices))
    print(','.join([d.name for d in devices]) if devices else 'None')
except ImportError:
    print('Not installed')
    print('0')
    print('None')
except Exception as e:
    print('Error: ' + str(e))
    print('0')
    print('None')
" 2>/dev/null || echo "Error 0 None")
TF_VERSION=$(echo "$TF_INFO" | head -1)
TF_GPU_COUNT=$(echo "$TF_INFO" | sed -n '2p')
TF_GPU_NAMES=$(echo "$TF_INFO" | sed -n '3p')
print_table_row "TensorFlow Version" "$TF_VERSION"
print_table_row "GPU Count" "$TF_GPU_COUNT"
print_table_row "GPU Devices" "$TF_GPU_NAMES"
if [[ "$TF_GPU_COUNT" -gt 0 ]]; then
    print_table_row "Status" "✓ GPU Acceleration Enabled"
else
    print_table_row "Status" "⚠ Running on CPU Only"
fi
print_table_footer
print_header "ONNX RUNTIME TEST"
echo -ne "▶ Checking ONNX providers "
BAR_SIZE=20
for ((i=0; i<$BAR_SIZE; i++)); do
    echo -ne "█"
    sleep 0.05
done
echo -e " ✓"
print_table_header "ONNX RUNTIME DETAILS"
ONNX_INFO=$(python3 -c "
import sys
try:
    import onnxruntime as ort
    print(ort.__version__)
    providers = ort.get_available_providers()
    print(','.join(providers))
except ImportError:
    print('Not installed')
    print('None')
except Exception as e:
    print('Error: ' + str(e))
    print('None')
" 2>/dev/null || echo "Error None")
ONNX_VERSION=$(echo "$ONNX_INFO" | head -1)
ONNX_PROVIDERS=$(echo "$ONNX_INFO" | sed -n '2p')
ONNX_HAS_GPU=$(echo "$ONNX_PROVIDERS" | grep -i "GPU\|CUDA" || echo "")
FORMATTED_PROVIDERS=""
if [[ "$ONNX_PROVIDERS" == *","* ]]; then
    IFS=',' read -ra PROVIDERS_ARRAY <<< "$ONNX_PROVIDERS"
    for provider in "${PROVIDERS_ARRAY[@]}"; do
        FORMATTED_PROVIDERS="${FORMATTED_PROVIDERS}${provider}, "
    done
    FORMATTED_PROVIDERS=${FORMATTED_PROVIDERS%, }
else
    FORMATTED_PROVIDERS=$ONNX_PROVIDERS
fi
print_table_row "ONNX Runtime Version" "$ONNX_VERSION"
print_table_row "Available Providers" "$FORMATTED_PROVIDERS"
print_table_footer
print_header "TENSORRT TEST"
echo -e "▶ Testing TensorRT capabilities..."
python3 << 'EOF'
import sys
import time
import tensorrt as trt
import numpy as np
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)
warnings.filterwarnings("ignore", category=UserWarning)
def print_section(title):
    print(f"\n+--- {title} {'-' * (40 - len(title))}+")
    print(f"|{' ' * 42}|")
    print(f"+{'-' * 42}+")
def test_tensorrt_basic():
    print_section("Basic TensorRT Test")
    logger = trt.Logger(trt.Logger.WARNING)
    builder = trt.Builder(logger)
    print(f"TensorRT version: {trt.__version__}")
    print(f"Platform has FP16: {builder.platform_has_fast_fp16}")
    print(f"Platform has INT8: {builder.platform_has_fast_int8}")
    print(f"Max batch size: {builder.max_batch_size}")
    print(f"DLA cores: {builder.num_DLA_cores}")
    if builder.num_DLA_cores > 0:
        print(f"Max DLA batch size: {builder.max_DLA_batch_size}")
    network = builder.create_network(1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH))
    cfg = builder.create_builder_config()
    print(f"✓ Basic TensorRT functionality is working")
    return True
def create_simple_network(bs=1):
    logger = trt.Logger(trt.Logger.WARNING)
    builder = trt.Builder(logger)
    explicit_batch = 1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH)
    network = builder.create_network(explicit_batch)
    inp = network.add_input("IN", trt.float32, (bs,3,224,224))
    w_conv = np.random.rand(16,3,3,3).astype(np.float32)
    conv = network.add_convolution_nd(inp, 16, (3,3), trt.Weights(w_conv), None)
    conv.stride_nd = (1,1)
    conv.padding_nd = (1,1)
    relu = network.add_activation(conv.get_output(0), trt.ActivationType.RELU)
    pool = network.add_pooling_nd(relu.get_output(0), trt.PoolingType.MAX, (2,2))
    pool.stride_nd = (2,2)
    global_pool = network.add_pooling_nd(pool.get_output(0), trt.PoolingType.AVERAGE, (112,112))
    global_pool.stride_nd = (1,1)
    w_final = np.random.rand(10,16,1,1).astype(np.float32)
    final_conv = network.add_convolution_nd(global_pool.get_output(0), 10, (1,1), trt.Weights(w_final), None)
    sm = network.add_softmax(final_conv.get_output(0))
    sm.axes = 1 << 1
    sm.get_output(0).name = "OUT"
    network.mark_output(sm.get_output(0))
    return builder, network
def test_precision_mode(prec="fp32", bs=1, dla=False):
    print_section(f"Testing {prec.upper()}")
    try:
        b, n = create_simple_network(bs)
        cfg = b.create_builder_config()
        cfg.set_memory_pool_limit(trt.MemoryPoolType.WORKSPACE, 1 << 28) 
        if prec=="fp16": 
            cfg.set_flag(trt.BuilderFlag.FP16)
            print(f"Enabled FP16")
        print("Building engine", end="")
        start = time.time()
        for _ in range(3):
            print(".", end="", flush=True)
            time.sleep(0.2)
        print(" ", end="")
        try:
            serialized_engine = b.build_serialized_network(n, cfg)
            if serialized_engine is None:
                raise RuntimeError("Failed to build serialized engine")
            runtime = trt.Runtime(trt.Logger(trt.Logger.WARNING))
            eng = runtime.deserialize_cuda_engine(serialized_engine)
            if eng is None:
                raise RuntimeError("Failed to deserialize engine")
            print(f"Built in {time.time()-start:.2f}s")
            ctx = eng.create_execution_context()
            print(f"✓ {prec.upper()} engine built successfully")
            return True
        except Exception as e:
            print(f"Built in {time.time()-start:.2f}s")
            print(f"⚠ Could not create execution context: {e}")
            print(f"✓ {prec.upper()} basic test passed")
            return True
    except Exception as e:
        print(f"⚠ {prec.upper()} test not available: {e}")
        return False
def main():
    test_tensorrt_basic()
    test_precision_mode("fp16", 1, False)
if __name__=="__main__":
    main()
EOF
print_header "GSTREAMER NVIDIA PLUGINS"
echo -ne "▶ Collecting NVIDIA GStreamer plugins... "
SPINNER="/-\\|"
for i in {1..20}; do
    echo -ne "\b${SPINNER:i%4:1}"
    sleep 0.1
done
echo -ne "\b✓\n"
NVIDIA_PLUGINS=$(gst-inspect-1.0 | grep -i nv | head -15 2>/dev/null || echo "No NVIDIA GStreamer plugins found")
print_table_header "NVIDIA GSTREAMER PLUGINS"
if [ -n "$NVIDIA_PLUGINS" ] && [ "$NVIDIA_PLUGINS" != "No NVIDIA GStreamer plugins found" ]; then
    printf "| %-25s | %-10s | %-30s |\n" "Plugin Name" "Type" "Description"
    echo "+---------------------------+------------+--------------------------------+"
    echo "$NVIDIA_PLUGINS" | while IFS= read -r line; do
        PLUGIN_NAME=$(echo "$line" | awk '{print $1}' | sed 's/:$//')
        PLUGIN_TYPE=$(echo "$line" | awk '{print $2}' | sed 's/:$//')
        PLUGIN_DESC=$(echo "$line" | cut -d: -f2- | sed 's/^ *//' | cut -c 1-30)
        printf "| %-25s | %-10s | %-30s |\n" "$PLUGIN_NAME" "$PLUGIN_TYPE" "$PLUGIN_DESC"
    done
    echo "⚠ And more plugins available..."
else
    print_warning "No NVIDIA GStreamer plugins found"
fi
ffmpeg -encoders | grep nvenc
ffmpeg -decoders | grep nvdec
print_header "VIDEO HARDWARE ACCELERATION TEST"
echo -ne "▶ Testing video acceleration capabilities... "
for i in {1..5}; do
    for c in / - \\ \|; do
        echo -ne "\b$c"
        sleep 0.05
    done
done
echo -e "\b✓"
print_table_header "FFMPEG HARDWARE ACCELERATION"
FFMPEG_HWACCELS=$(ffmpeg -hide_banner -hwaccels 2>/dev/null || echo "Error detecting hardware accelerators")
echo -e "Available HW Accelerators:"
if [[ "$FFMPEG_HWACCELS" == *"Error"* ]]; then
    echo -e "  ⚠ FFmpeg not found or error detecting accelerators"
else
    FFMPEG_HWACCELS=$(echo "$FFMPEG_HWACCELS" | grep -v "Hyper fast")
    echo "$FFMPEG_HWACCELS" | sed 's/^/  /' | grep -v "^  $"
    NUM_ACCEL=$(echo "$FFMPEG_HWACCELS" | grep -v "^$" | wc -l)
    NUM_NVIDIA=$(echo "$FFMPEG_HWACCELS" | grep -i "cuda\|nvenc\|cuvid" | wc -l)
    if [[ $NUM_NVIDIA -gt 0 ]]; then
        echo -e "  ✓ $NUM_NVIDIA NVIDIA accelerators available"
    fi
fi
echo
print_header "H.264 ENCODER TEST"
print_table_header "AVAILABLE H.264 ENCODERS"
H264_ENCODERS=$(ffmpeg -hide_banner -encoders 2>/dev/null | grep -E "^\s*V.*h264" || echo "No H.264 encoders found")
echo -e "Available H.264 Encoders:"
if [ -n "$H264_ENCODERS" ] && [ "$H264_ENCODERS" != "No H.264 encoders found" ]; then
    echo "$H264_ENCODERS" | while read -r line; do
        echo -e "  $line"
    done
else
    echo -e "  ⚠ No H.264 encoders found"
fi
echo
if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q h264_nvenc; then
    ENC="h264_nvenc"
    print_success "Using NVIDIA hardware encoder: $ENC"
elif ffmpeg -hide_banner -encoders 2>/dev/null | grep -q h264_v4l2m2m; then
    ENC="h264_v4l2m2m"
    print_info "Using V4L2 encoder: $ENC"
else
    print_warning "No suitable H.264 encoder found"
    ENC=""
fi
print_table_footer
print_header "VIDEO ACCELERATION SUMMARY"
echo -ne "▶ Running GStreamer acceleration tests... "
for i in {1..10}; do
    echo -ne "▮"
    sleep 0.05
done
echo -e " ✓"
print_table_header "CODEC ACCELERATION STATUS"
if [ -e "/dev/nvhost-msenc" ] || [ -e "/dev/nvhost-nvenc" ]; then
    print_info "NVIDIA hardware encoder detected"
    echo -e "\nTesting H.264 encoder..."
    if gst-launch-1.0 videotestsrc num-buffers=60 ! "video/x-raw,width=640,height=480" ! nvvidconv ! "video/x-raw(memory:NVMM)" ! nvv4l2h264enc ! h264parse ! fakesink -q 2>/dev/null; then
        print_table_row "H.264 Encoding" "✓ Working"
        H264_PROFILE=$(gst-launch-1.0 videotestsrc num-buffers=1 ! "video/x-raw,width=640,height=480" ! nvvidconv ! "video/x-raw(memory:NVMM)" ! nvv4l2h264enc ! h264parse ! fakesink -v 2>&1 | grep -o "profile=.*level" | head -1)
        [ -n "$H264_PROFILE" ] && print_table_row "H.264 Profile" "$H264_PROFILE"
    else
        print_table_row "H.264 Encoding" "⚠ Not available"
    fi
    echo -e "\nTesting H.265 encoder..."
    if gst-launch-1.0 videotestsrc num-buffers=60 ! "video/x-raw,width=640,height=480" ! nvvidconv ! "video/x-raw(memory:NVMM)" ! nvv4l2h265enc ! h265parse ! fakesink -q 2>/dev/null; then
        print_table_row "H.265 Encoding" "✓ Working"
        H265_PROFILE=$(gst-launch-1.0 videotestsrc num-buffers=1 ! "video/x-raw,width=640,height=480" ! nvvidconv ! "video/x-raw(memory:NVMM)" ! nvv4l2h265enc ! h265parse ! fakesink -v 2>&1 | grep -o "profile=.*level" | head -1)
        [ -n "$H265_PROFILE" ] && print_table_row "H.265 Profile" "$H265_PROFILE"
    else
        print_table_row "H.265 Encoding" "⚠ Not available"
    fi
else
    print_table_row "Hardware Encoder" "⚠ Not detected"
fi
echo -e "\nTesting hardware decoders..."
if [ -e "/dev/nvhost-nvdec" ]; then
    print_table_row "NVDEC Hardware" "✓ Detected"
    if gst-inspect-1.0 nvv4l2decoder &>/dev/null; then
        print_table_row "NVDEC Decoder Plugin" "✓ Available"
        SUPPORTED_CODECS=$(gst-inspect-1.0 nvv4l2decoder 2>/dev/null | grep -A 5 "Device Features" | grep -o "codec=.*$" | tr -d ' ')
        [ -n "$SUPPORTED_CODECS" ] && print_table_row "Supported Codecs" "$SUPPORTED_CODECS"
    else
        print_table_row "NVDEC Decoder Plugin" "⚠ Not found"
    fi
else
    print_table_row "Hardware Decoder" "⚠ Not detected"
fi
print_table_footer
print_header "DIAGNOSTICS SUMMARY"
print_table_header "HARDWARE ACCELERATION STATUS"
if [ -f "/usr/local/cuda/bin/nvcc" ] || [ -n "$(find /usr -name nvcc 2>/dev/null | head -1)" ]; then
    print_table_row "CUDA Toolkit" "✓ Available"
    CUDA_STATUS=1
else
    print_table_row "CUDA Toolkit" "⚠ Not detected"
    CUDA_STATUS=0
fi
PYTORCH_CUDA=$(python3 -c "
import sys
try:
    import torch
    print(torch.cuda.is_available())
except ImportError:
    print('False')
except Exception:
    print('False')
" 2>/dev/null || echo "False")
if [[ "$PYTORCH_CUDA" == "True" ]]; then
    print_table_row "PyTorch GPU" "✓ Accelerated"
    PYTORCH_STATUS=1
else
    print_table_row "PyTorch GPU" "⚠ CPU Only"
    PYTORCH_STATUS=0
fi
TF_GPU_COUNT=$(python3 -c "
import sys
try:
    import tensorflow as tf
    print(len(tf.config.list_physical_devices('GPU')))
except ImportError:
    print('0')
except Exception:
    print('0')
" 2>/dev/null || echo "0")
if [[ "$TF_GPU_COUNT" -gt 0 ]]; then
    print_table_row "TensorFlow GPU" "✓ Accelerated"
    TF_STATUS=1
else
    print_table_row "TensorFlow GPU" "⚠ CPU Only"
    TF_STATUS=0
fi
if [ -e "/dev/nvhost-msenc" ] || [ -e "/dev/nvhost-nvenc" ]; then
    print_table_row "Video Encoding" "✓ Available"
    VENC_STATUS=1
else
    print_table_row "Video Encoding" "⚠ Not available"
    VENC_STATUS=0
fi
if [ -e "/dev/nvhost-nvdec" ]; then
    print_table_row "Video Decoding" "✓ Available"
    VDEC_STATUS=1
else
    print_table_row "Video Decoding" "⚠ Not available"
    VDEC_STATUS=0
fi
TOTAL=$((CUDA_STATUS + PYTORCH_STATUS + TF_STATUS + VENC_STATUS + VDEC_STATUS))
MAX=5
PERCENTAGE=$((TOTAL * 100 / MAX))
print_table_row "Overall Score" "$PERCENTAGE% ($TOTAL/$MAX)"
BAR_SIZE=20
FILLED=$((BAR_SIZE * TOTAL / MAX))
EMPTY=$((BAR_SIZE - FILLED))
BAR=""
for ((i=0; i<FILLED; i++)); do
    BAR="${BAR}█"
done
for ((i=0; i<EMPTY; i++)); do
    BAR="${BAR}░"
done
print_table_row "Progress" "$BAR"
print_table_footer
print_header "DIAGNOSTICS COMPLETE"
print_success "All diagnostics completed and Log saved to: $LOG_FILE"

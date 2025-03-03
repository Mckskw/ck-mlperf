ARG BASE_IMAGE
ARG SDK_VER
FROM ${BASE_IMAGE}:${SDK_VER}

# Fixed group id = 1500.
ARG GROUP_ID
# Fixed user id = 2000.
ARG USER_ID
# Use CK <= 1.55.5 with known behaviour.
ARG CK_VER
# Use TensorFlow 2.7
ARG TF_VER

LABEL maintainer="Anton Lokhmotov <anton@krai.ai>"

# Use the Bash shell.
SHELL ["/bin/bash", "-c"]

# Allow stepping into the Bash shell interactively.
ENTRYPOINT ["/bin/bash", "-c"]

# Install known system dependencies and immediately clean up to make the image smaller.
# CK needs: git, wget, zip.
# TF needs: curl.
# TF Object Detection API needs ProtoBuf 3.0 which needs CMake.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update -y\
 && apt install -y apt-utils\
 && apt upgrade -y\
 && apt install -y\
 git wget zip libz-dev\
 curl\
 cmake\
 python3 python3-pip\
 vim\
 && apt clean

# Create a non-root user with a fixed group id 1500 and a fixed user id 2000
# (hopefully distinct from any host user id for security reasons).
# See the README for the gory details.
RUN groupadd -g ${GROUP_ID} kraig
RUN useradd -u ${USER_ID} -g kraig --create-home --shell /bin/bash krai
USER krai:kraig
WORKDIR /home/krai

# Install Collective Knowledge (CK). Make it group-executable.
ENV CK_ROOT="/home/krai/CK" \
    CK_REPOS="/home/krai/CK_REPOS" \
    CK_TOOLS="/home/krai/CK_TOOLS" \
    PATH="${CK_ROOT}/bin:/home/krai/.local/bin:${PATH}" \
    CK_CC=gcc \
    CK_PYTHON=python3 \
    GIT_USER="krai" \
    GIT_EMAIL="info@krai.ai" \
    LANG=C.UTF-8
RUN mkdir -p ${CK_ROOT} ${CK_REPOS} ${CK_TOOLS}\
 && git config --global user.name ${GIT_USER} && git config --global user.email ${GIT_EMAIL}\
 && git clone --branch V${CK_VER} https://github.com/ctuning/ck.git ${CK_ROOT}\
 && cd ${CK_ROOT} && ${CK_PYTHON} setup.py install --user\
 && ${CK_PYTHON} -c "import ck.kernel as ck; print ('Collective Knowledge v%s' % ck.__version__)"\
 && chmod -R g+rx /home/krai/.local

# Explicitly create a CK experiment entry, a folder that will be mounted
# (with '--volume=<folder_for_results>:/home/krai/CK_REPOS/local/experiment').
# as a shared volume between the host and the container, and make it group-writable.
# For consistency, use the "canonical" uid from ck-analytics:module:experiment.
RUN ck create_entry --data_uoa=experiment --data_uid=bc0409fb61f0aa82 --path=${CK_REPOS}/local\
 && chmod -R g+ws ${CK_REPOS}/local/experiment

# Pull CK repositories (including ck-env and ck-tensorflow).
RUN ck pull repo --url=http://github.com/krai/ck-mlperf.git

# Use generic Linux settings with dummy frequency setting scripts.
RUN ck detect platform.os --platform_init_uoa=generic-linux-dummy

# Detect C/C++ compiler (gcc).
RUN ck detect soft:compiler.gcc --full_path=$(which ${CK_CC})

# Detect Python.
RUN ck detect soft:compiler.python --full_path=$(which ${CK_PYTHON})
# Install the latest Python package installer (pip) and some dependencies.
RUN ${CK_PYTHON} -m pip install --ignore-installed pip setuptools --user


#-----------------------------------------------------------------------------#
# Step 1. Install prebuilt TensorFlow (via pip).
#-----------------------------------------------------------------------------#
RUN ck install package --tags=lib,tensorflow,python-package --force_version=${TF_VER}
# Remove NumPy v1.19.5 which conflicts with Python COCO API.
RUN find /home/krai/CK_TOOLS/lib-python-tensorflow* -maxdepth 5 -name 'numpy*' \
    -exec rm -r {} \;
# Install OpenVINO Inference Engine on top of TensorFlow v2.8.0.
RUN ${CK_PYTHON} -m pip install tensorflow==2.8.0 --user
RUN ck install package --tags=lib,tensorflow,python-package,openvino
#-----------------------------------------------------------------------------#


#-----------------------------------------------------------------------------#
# Step 2. INTENTIONALLY LEFT BLANK.
#-----------------------------------------------------------------------------#


#-----------------------------------------------------------------------------#
# Step 3. Install the COCO 2017 validation dataset (5,000 images).
#-----------------------------------------------------------------------------#
# Download the dataset to the default path. Remove all training annotations (~765 MB).
RUN echo | ck install package --tags=object-detection,dataset,coco.2017,val,original,full\
 && ck virtual env --tags=object-detection,dataset,coco.2017,val,original,full --shell_cmd=\
'rm $CK_ENV_DATASET_COCO_LABELS_DIR/*train2017.json'
# Install Python COCO API.
RUN ck install package --tags=lib,python-package,cython
RUN echo "" | ck install package --tags=lib,python-package,numpy
RUN ck install package --tags=lib,python-package,matplotlib
RUN ck install package --tags=tool,coco,api
# Install OpenCV (required for preprocessing).
RUN ck install package --tags=lib,python-package,cv2,opencv-python-headless
#-----------------------------------------------------------------------------#


#-----------------------------------------------------------------------------#
# Step 4. Install the object detection models.
#-----------------------------------------------------------------------------#
# Install TF model API, but remove useless API files to free up space.
RUN ck detect soft --tags=cmake --full_path=/usr/local/bin/cmake
RUN ck install package --tags=model,tensorflow,api\
 && ck virtual env --tags=model,tensorflow,api --shell_cmd=\
'cd $CK_ENV_TENSORFLOW_MODELS;\
 mv object_detection ..;\
 rm * -r;\
 mv ../object_detection .;\
 cd ..;\
 rm official -rf;\
 rm samples -rf;\
 rm tutorials -rf;\
 rm .git -rf'

RUN ck install package --tags=object-detection,tf1-zoo,rcnn-nas-lowproposals-coco\
 && ck install package --tags=object-detection,tf1-zoo,rcnn-resnet50-lowproposals-coco\
 && ck install package --tags=object-detection,tf1-zoo,rcnn-resnet101-lowproposals-coco\
 && ck install package --tags=object-detection,tf1-zoo,rcnn-inception-resnet-v2-lowproposals-coco\
 && ck install package --tags=object-detection,tf1-zoo,rcnn-inception-v2-coco\
 && ck install package --tags=object-detection,tf1-zoo,ssd-inception-v2-coco\
 && ck install package --tags=object-detection,tf1-zoo,ssd_mobilenet_v1_coco\
 && ck install package --tags=object-detection,tf1-zoo,ssd_mobilenet_v1_quantized_coco\
 && ck install package --tags=object-detection,tf1-zoo,ssd-mobilenet-v1-fpn-sbp-coco\
 && ck install package --tags=object-detection,tf1-zoo,ssd-resnet50-v1-fpn-sbp-coco\
 && ck install package --tags=object-detection,tf1-zoo,ssdlite-mobilenet-v2-coco\
 && ck install package --tags=object-detection,tf1-zoo,yolo-v3-coco\
 && ck install package --tags=object-detection,tf2-zoo,ssd_resnet50_v1_fpn_640x640\
 && ck install package --tags=object-detection,tf2-zoo,ssd_resnet50_v1_fpn_1024x1024\
 && ck install package --tags=object-detection,tf2-zoo,ssd_resnet101_v1_fpn_640x640\
 && ck install package --tags=object-detection,tf2-zoo,ssd_resnet101_v1_fpn_1024x1024\
 && ck install package --tags=object-detection,tf2-zoo,ssd_resnet152_v1_fpn_640x640\
 && ck install package --tags=object-detection,tf2-zoo,ssd_resnet152_v1_fpn_1024x1024\
 && ck install package --tags=object-detection,tf2-zoo,ssd_mobilenet_v2_320x320\
 && ck install package --tags=object-detection,tf2-zoo,ssd_mobilenet_v1_fpn_640x640\
 && ck install package --tags=object-detection,tf2-zoo,ssd_mobilenet_v2_fpnlite_320x320\
 && ck install package --tags=object-detection,tf2-zoo,ssd_mobilenet_v2_fpnlite_640x640
#-----------------------------------------------------------------------------#


#-----------------------------------------------------------------------------#
# Step 5. INTENTIONALLY LEFT BLANK.
#-----------------------------------------------------------------------------#


#-----------------------------------------------------------------------------#
# Step 6. Make final preparations to run the official vision app with CK mods.
#-----------------------------------------------------------------------------#
# NB: Apparently, we still need Pillow to run the official vision app.
RUN ck install package --tags=lib,python-package,pillow
# NB: While Abseil has already been installed above, we install and register it
# with CK here as well, as it is needed for LoadGen.
RUN ck install package --tags=lib,python-package,absl
# Install the official vision app with CK modifications
RUN ck install package --tags=mlperf,inference,source,krai.vision_with_ck
# Install loadGen
RUN ck install package --tags=lib,python-package,mlperf,loadgen
# Allow the program to create tmp files when running under an external user.
RUN chmod -R g+rwx $(ck find program:mlperf-inference-vision)
#-----------------------------------------------------------------------------#


#-----------------------------------------------------------------------------#
# Run the official MLPerf Inference vision app
# under the Offline scenario
# in the Accuracy mode on the first 50 images of the COCO 2017 validation dataset
# with the TensorFlow CPU backend and the SSD-MobileNet-FPN model.
#-----------------------------------------------------------------------------#
CMD ["ck run program:mlperf-inference-vision --cmd_key=direct --skip_print_timers \
  --env.CK_LOADGEN_EXTRA_PARAMS='--count 50 --performance-sample-count 64 --query-count 2048 --target-latency 35' \
  --env.CK_LOADGEN_SCENARIO=Offline \
  --env.CK_OPTIMIZE_GRAPH='True' \
  \
  --dep_add_tags.weights=tf1-zoo,ssd_mobilenet_v1_coco \
  --env.CK_MODEL_PROFILE=tf1_object_det_zoo \
  --env.CK_INFERENCE_ENGINE=tensorflow \
  --env.CK_INFERENCE_ENGINE_BACKEND=default.cpu \
  --env.CUDA_VISIBLE_DEVICES=-1"]

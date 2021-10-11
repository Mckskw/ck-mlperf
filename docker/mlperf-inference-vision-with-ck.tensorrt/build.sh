#/bin/bash

_BASE_IMAGE=${BASE_IMAGE:-nvcr.io/nvidia/tensorrt}
_SDK_VER=${SDK_VER:-21.08-py3}
_CK_VER=${CK_VER:-1.55.5}
_TF_VER=${TF_VER:-2.6.0}
_GROUP_ID=${GROUP_ID:-1500}
_USER_ID=${USER_ID:-2000}

CK_IMAGE=mlperf-inference-vision-with-ck.tensorrt

read -d '' CMD <<END_OF_CMD
cd $(ck find docker:${CK_IMAGE}) && \
time docker build \
--build-arg BASE_IMAGE=${_BASE_IMAGE} \
--build-arg SDK_VER=${_SDK_VER} \
--build-arg CK_VER=${_CK_VER} \
--build-arg GROUP_ID=${_GROUP_ID} \
--build-arg USER_ID=${_USER_ID} \
-t krai/${CK_IMAGE}:${_SDK_VER}_tf-${_TF_VER} \
-f Dockerfile .
END_OF_CMD
echo "Running: ${CMD}"
if [ -z "${DRY_RUN}" ]; then
  eval ${CMD}
fi

echo
echo "Done."
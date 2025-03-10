#!/bin/bash

#
# Copyright (c) 2021 Krai Ltd.
#
# SPDX-License-Identifier: BSD-3-Clause.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

function exit_if_error() {
  if [ "${?}" != "0" ]; then exit 1; fi
}

INSTALL_SCRIPT_NAME=install.sh

echo "${INSTALL_SCRIPT_NAME} : Converting ResNet101 TF model to ONNX ..."

TENSORFLOW_MODEL_PATH="$(dirname -- ${CK_ENV_TENSORFLOW_MODEL_TF_FROZEN_FILEPATH})"

${CK_ENV_COMPILER_PYTHON_FILE} -m tf2onnx.convert --saved-model ${TENSORFLOW_MODEL_PATH} --output ${INSTALL_DIR}/intermediate_model.onnx --verbose --fold_const --opset 11 --inputs input_tensor:0[1,640,640,3]

echo "${INSTALL_SCRIPT_NAME} : Removing NMS from SSD-ResNet101 ONNX model ..."
${CK_ENV_COMPILER_PYTHON_FILE} ${ORIGINAL_PACKAGE_DIR}/remove_nms.py ${INSTALL_DIR}/intermediate_model.onnx ${INSTALL_DIR}/${PACKAGE_NAME} ${INSTALL_DIR}/${PACKAGE_NAME}-nms
exit_if_error

echo "${INSTALL_SCRIPT_NAME} : Deleting intermediate files ..."
rm ${INSTALL_DIR}/intermediate_model.onnx

echo "${INSTALL_SCRIPT_NAME} : Done."

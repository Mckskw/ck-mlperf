# MLPerf Inference - Speech Recognition - RNNT

[This collection of images](https://hub.docker.com/r/ctuning/speech-recognition.rnnt) from [dividiti](http://dividiti.com)
tests automated, customizable and reproducible [Collective Knowledge](http://cknowledge.org) workflow for the [Speech Recognition RNNT](https://github.com/mlperf/inference/tree/master/v0.7/speech_recognition/rnnt/) workload. All images include the CK workflow, the latest PyTorch, the PyTorch model, and the (suitable preprocessed) [LibriSpeech](http://www.openslr.org/12/) Dev-Clean dataset.

| `Dockerfile`          | `CK_TAG`   | Python | GCC   | Comments |
|-|-|-|-|-|
| `Dockerfile.centos-7` | `centos-7` | 3.7.7  | 8.3.1 | Updated Python (from 2.7) and GCC (from 4.8) |
| `Dockerfile.centos-8` | `centos-8` | 3.7.7  | 8.3.1 | Updated Python (from 3.6) |
| `Dockerfile.centos-8.python3.6` | `centos-8.python3.6` | 3.6.8  | 8.3.1 | Fails to build due to weird lib/lib64 behaviour of `pip` |
| `Dockerfile.debian-9` | `debian-9` | 3.5.3  | 6.3.0 | `numba==0.47`, `llvmlite=0.31.0`  |
| `Dockerfile.debian-10` | `debian-10` | 3.7.3  | 8.3.0 |  |

## Build

To build an image e.g. from `Dockerfile.centos-7`:
```bash
$ export CK_IMAGE=speech-recognition.rnnt CK_TAG=centos-7
$ cd `ck find docker:$CK_IMAGE`
$ docker build -t ctuning/$CK_IMAGE:$CK_TAG -f Dockerfile.$CK_TAG .
```

### Show Python and GCC versions

To show the Python and GCC versions in use in an image built from `Dockerfile.centos-7`:
```bash
$ export CK_IMAGE=speech-recognition.rnnt CK_TAG=centos-7

$ docker run -it --rm ctuning/$CK_IMAGE:$CK_TAG "ck show env --tags=compiler,python"
Env UID:         Target OS: Bits: Name:  Version: Tags:

ef09a59ce5645ffc   linux-64    64 python 3.7.7    64bits,compiler,host-os-linux-64,lang-python,python,target-os-linux-64,v3,v3.7,v3.7.7

$ docker run -it --rm ctuning/$CK_IMAGE:$CK_TAG "ck show env --tags=compiler,gcc"
Env UID:         Target OS: Bits: Name:          Version: Tags:

511106845f6bfe42   linux-64    64 GNU C compiler 8.3.1    64bits,compiler,gcc,host-os-linux-64,lang-c,lang-cpp,target-os-linux-64,v8,v8.3,v8.3.1
```

### Check versions of Python packages

```bash
$ export CK_IMAGE=speech-recognition.rnnt CK_TAG=centos-7
$ docker run -it --rm ctuning/$CK_IMAGE:$CK_TAG \
'ck virtual env --tags=compiler,python \
  --shell_cmd='"'"'$CK_ENV_COMPILER_PYTHON_FILE -m pip show numpy'"'"'\
'
```
**NB**: See the quotes magic explained [here](https://stackoverflow.com/questions/1250079/how-to-escape-single-quotes-within-single-quoted-strings).

## Run the default command

To run the default command of an image e.g. built from `Dockerfile.centos-7`:
```bash
$ export CK_IMAGE=speech-recognition.rnnt
$ export CK_TAG=centos-7
$ docker run --rm ctuning/$CK_IMAGE:$CK_TAG
```
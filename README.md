## Docker Image Voice Privacy Challenge 2020
*Adaption for 2022 version is currently in progress*

This project provides a Voice Transformation Tool and Docker Images for the Voice Privacy Challenge 2020.


**As this implementation relies on kaldi and this [CURRENNT tool from NII](https://github.com/nii-yamagishilab/project-CURRENNT-public/tree/3b4648f1f4ec45635c217bbf52be74c54aae3b80), it requires a
CUDA-capable graphics card.**   

The transformation can be run locally using scripts or as a REST service. 
The transformation relies on kaldi and other tools. These are already installed in the provided docker images.   
  

## Overview
From the VPC 2020 repository :  

![](https://github.com/Voice-Privacy-Challenge/Voice-Privacy-Challenge-2020/raw/master/baseline/fig/baseline_git.jpg)


> The baseline system uses several independent models:  
> 1. ASR acoustic model to extract BN features (`1_asr_am`) - trained on LibriSpeech-train-clean-100 and LibriSpeech-train-other-500  
> 2. X-vector extractor (`2_xvect_extr`) - trained on VoxCeleb 1 & 2.  
> 3. Speech synthesis (SS) acoustic model (`3_ss_am`) - trained on LibriTTS-train-clean-100.  
> 4. Neural source filter (NSF) model (`4_nsf`) - trained on LibriTTS-train-clean-100.  




Please visit the [challenge website](https://www.voiceprivacychallenge.org/) for more information about the Challenge and this method.


## Quick start: use the RESTful API in Docker to transform an audio file

Prerequisites: docker and [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) should be installed.  

```
docker run -d --gpus all -p 5000:5000 tlautens/vpc-docker-registry:vpc-voice-transformer
```
*Depending on your docker installation, you might have to execute this command with sudo privilege*

*In case of needing help for running with podman please send a mail to the repo owner*

The service is running on the port 5000 and responds to the endpoint: http://localhost:5000/vpc

- Method: POST
- Input: original audio file, parameters (JSON) 
- Output: transformed audio file

Here is an example of the way to use it in python:

```
import requests
import json

API_URL = 'http://localhost:5000'  # replace localhost with the proper hostname

# Read the content from an audio file
input_file = 'io/inputs/e0003.wav'
with open(input_file, mode='rb') as fp:
    content = fp.read()

# Transformation parameters
params = {'wgender': 'm',
          'cross_gender': 'same',
          'distance': 'plda',
          'proximity': 'dense',
          'sample-frequency': 16000}

# Call the service
response = requests.post('{}/vpc'.format(API_URL), data=content, params=json.dumps(params))

# Save the result of the transformation in a new file
result_file = 'transformed.wav'
with open(result_file, mode='wb') as fp:
    fp.write(response.content)

```

## Configuration and parameters

```
transform.sh [--anon_pool <anon_pool_dir>|--sample-frequency <nb>|--cross-gender (same|other|random)|--distance (plda|cosine)|--proximity (dense|farthest|random)] --wgender (m|f) <input_file> <output_dir>
```

- `--wgender` (required): gender of the speaker in the audio file to transform
- `--cross-gender`: gender of the target speakers to select from the pool (same as the original speaker, the other one or randomly)
- `--anon-pool`: path to the anonymization pool of speakers to use
- `--distance`: plda or cosine
- `--proximity`: the strategy to choose the pool of target speakers (dense, farthest or random)
- `<input_file>` input path for the wav file to transform (wav format : RIFF (little-endian) data, WAVE audio, Microsoft PCM, 16 bit, mono 16000 Hz) 
- `<output_file>` output path: default is results

The transformer expects audio files sampled at a frequency of 16KHz, but other frequencies can be accepted using the `--sample-frequency` param.

## Use the dockerized environment to run the scripts

At a lower level, the implementation is a Kaldi recipe and can be used as is, for the use cases not fulfilled by the RESTful API (for example, building a new anonymization pool, or for batch processing): the entry points are then a set of scripts, one for each functionality. 
Because the execution environment can be tedious to install, we also provide another docker image with only the execution environment (including kaldi) to run these scripts. This is a way to use it:

From the root folder in this repository:
```
docker run --rm --gpus all \
  -v "$(pwd)"/vpc:/opt/vpc \
  -v "$(pwd)"/io:/opt/vpc/io \
  tlautens/vpc-docker-registry:vpc-env-base \
  vpc/transform.sh --wgender m io/inputs/e0003.wav
```
*Note: depending on your docker installation, you may have to run docker with sudo privileges*

*In case of needing help for running with podman please send a mail to the repo owner*

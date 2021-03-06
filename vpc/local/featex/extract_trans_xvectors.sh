#!/bin/bash

set -e

. path.sh
. cmd.sh

nj=$(nproc)

. utils/parse_options.sh

if [ $# != 3 ]; then
  echo "Usage: "
  echo "  $0 [options] <data-dir> <nnet-dir> <xvector-out-dir>"
  echo "Options"
  echo "   --nj=40     # Number of CPUs to use for feature extraction"
  exit 1;
fi

nnet_dir=$2
plda_dir=$1
data_dir=$1
out_dir=$3

mfccdir=`pwd`/mfcc
vaddir=`pwd`/mfcc

mkdir -p ${out_dir}
dataname=$(basename $data_dir)
src_xvectors_dir=$out_dir/xvectors_$dataname

steps/make_mfcc.sh --write-utt2num-frames true --mfcc-config conf/mfcc.conf \
    --nj $nj --cmd "$train_cmd" ${data_dir} exp/make_mfcc $mfccdir || exit 1

utils/fix_data_dir.sh ${data_dir} || exit 1
    
sid/compute_vad_decision.sh --nj $nj --cmd "$train_cmd" ${data_dir} exp/make_vad $vaddir || exit 1

utils/fix_data_dir.sh ${data_dir} || exit 1

sid/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd" --nj $nj \
    $nnet_dir ${data_dir} ${src_xvectors_dir} || exit 1


#TODO: Transform raw x-vectors into mean-normalized and LDA compressed 200d vectors
"ark:ivector-subtract-global-mean $plda_dir/mean.vec scp:${src_xvectors_dir}/xvector.scp ark:- | transform-vec $plda_dir/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \




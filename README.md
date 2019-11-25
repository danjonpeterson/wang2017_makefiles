# wang2017_makefiles

This repo contains the Makefile for the journal article "Evaluation of field map and nonlinear registration methods for correction of susceptibility artifacts in diffusion MRI", published in Frontiers in Neuroinformatics in 2017

[LINK TO THE PAPER](https://doi.org/10.3389/fninf.2017.00017)

The core of the process is in the following lines:

for "Method 1" the command-line call was:
>antsRegistrationSyN.sh -d 3 -f T1_inverse.nii.gz -m dti_b0_brain.nii.gz -o B0toT1 -t s

--- then ---

>antsApplyTransforms -d 3 -e 3 -i dti/mc_dti_geomCorrected.nii.gz -o mc_dti_unwarped.nii.gz -t B0toT11Warp.nii.gz -t B0toT10GenericAffine.mat -r T1_inverse.nii.gz


for "Method 2" the command-line call was:
>antsIntermodalityIntrasubject.sh -d 3 -i dti_b0_brain.nii.gz -r T1_robex_restore.nii.gz -x T1_robex_restore.nii.gz -w template -o B0toT1SmallWarp -t 2

--- then ---

>antsApplyTransforms -d 3 -e 3 -i dti/mc_dti_geomCorrected.nii.gz -o mc_dti_unwarped_small.nii.gz -t B0toT1SmallWarp1Warp.nii.gz -t B0toT1SmallWarp0GenericAffine.mat -r T1_robex_restore.nii.gz


Folks looking to apply this method should take a look at **qsiprep**, which is a fully supported diffusion image processing pipeline, which implements an improved version of the method described in our paper.

[LINK TO QSIPREP](https://github.com/pennbbl/qsiprep)

[qsiprep docs on fielmap-less unwarping](https://qsiprep.readthedocs.io/en/latest/api/index.html#sdc-fieldmapless)
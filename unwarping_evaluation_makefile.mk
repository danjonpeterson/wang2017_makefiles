BIN=/projects2/dtivbm/bin
ANTSpath=/usr/local/ANTs-2.1.0-rc3/bin

all: T1_inverse.nii.gz B0toT1Warped.nii.gz T1_robex_restore_mask.nii.gz unwarped_ants/dti_FA.nii.gz B0toT1SmallWarpanatomical.nii.gz mc_dti_unwarped_small.nii.gz unwarped_ants_small/dti_FA.nii.gz unwarped_ants_small/dti_FA_2mm.nii.gz unwarped_ants/dti_FA_2mm.nii.gz imagesimilarity.csv ants_FAtoFAstandardWarped.nii.gz   ants_FA_smalltoFAstandardWarped.nii.gz dti-dtifit/dti_FA_to_T1.nii.gz fieldmapSimilarity.csv dti-dtifit/dti_FA_mask.nii.gz dti-dtifit/dti_FA_ero.nii.gz  dtifit_FA_to_FAWarped.nii.gz

#
mc_dti_brain.nii.gz: dti/mc_dti.nii.gz
	fslroi dti/mc_dti.nii.gz mc_dti_brain.nii.gz 0 1 ;\
	bet mc_dti_brain.nii.gz mc_dti_brain.nii.gz -f 0.15 ;\

dti_b0.nii.gz: mc_dti_brain.nii.gz
	fslroi mc_dti_brain.nii.gz dti_b0 0 1

dti_b0_brain.nii.gz: dti_b0.nii.gz
	bet $< $@ -f .15 

# skull stripped & bias field correction
T1_robex.nii.gz: T1.nii.gz
	runROBEX.sh T1.nii.gz T1_robex.nii.gz
T1_robex_restore.nii.gz: T1_robex.nii.gz
	fast -B T1_robex.nii.gz

# create a mask for T1_robex_restore.nii.gz
T1_robex_restore_mask.nii.gz: T1_robex_restore.nii.gz
	fslmaths T1_robex_restore.nii.gz -thr 1 -bin T1_robex_restore_mask.nii.gz

# bias field correction 
#T1_bias_correct.nii.gz : T1.nii.gz
#	bet $< $@ -B -f 0.14

#T1_inverse.nii.gz -invert the contrast of the T1 image
T1_inverse.nii.gz: T1_robex_restore.nii.gz dti_b0_brain.nii.gz
	/project_space/Unwarping_evaluation/bin/inverse T1_robex_restore.nii.gz dti_b0_brain.nii.gz T1_inverse.nii.gz
	fslmaths T1_inverse.nii.gz -mas T1_robex_restore.nii.gz T1_inverse.nii.gz


#T1_inverse.nii.gz: T1_bias_correct.nii.gz dti_b0_brain.nii.gz
#	/project_space/Unwarping_evaluation/bin/inverse T1_bias_correct.nii.gz dti_b0_brain.nii.gz T1_inverse.nii.gz
#	fslmaths T1_inverse.nii.gz -mas T1_bias_correct.nii.gz T1_inverse.nii.gz


b0_to_T1_flirt.mat: T1_inverse.nii.gz dti_b0_brain.nii.gz
	flirt -in dti_b0_brain.nii.gz -ref T1_inverse.nii.gz -dof 6 -out b0_to_T1_flirt.nii.gz -omat $@

b0_to_T1_flirt.txt: b0_to_T1_flirt.mat T1_inverse.nii.gz
	c3d_affine_tool -ref T1_inverse.nii.gz -src dti_b0_brain.nii.gz b0_to_T1_flirt.mat -fsl2ras -oitk $@

B0toT1Warped.nii.gz: T1_inverse.nii.gz b0_to_T1_flirt.txt
	antsRegistrationSyN.sh -d 3 -f T1_inverse.nii.gz -m b0_to_T1_flirt.nii.gz -o B0toT1 -t s

b0_to_T1_flirt_small.mat: T1_robex_restore.nii.gz dti_b0_brain.nii.gz
	flirt -in dti_b0_brain.nii.gz -ref T1_robex_restore.nii.gz -dof 6 -out b0_to_T1_flirt_small.nii.gz -omat b0_to_T1_flirt_small.mat

b0_to_T1_flirt_small.txt: b0_to_T1_flirt_small.mat T1_robex_restore.nii.gz
	c3d_affine_tool -ref T1_robex_restore.nii.gz -src dti_b0_brain.nii.gz b0_to_T1_flirt_small.mat -fsl2ras -oitk b0_to_T1_flirt_small.txt

B0toT1SmallWarpanatomical.nii.gz: b0_to_T1_flirt_small.txt T1_robex_restore.nii.gz
	antsIntermodalityIntrasubject.sh -d 3 -i b0_to_T1_flirt_small.nii.gz -r T1_robex_restore.nii.gz -x T1_robex_restore.nii.gz -w template -o B0toT1SmallWarp -t 2

B0toT1SmallWarpanatomical.nii.gz:  dti_b0_brain.nii.gz T1_robex_restore.nii.gz
	antsIntermodalityIntrasubject.sh -d 3 -i dti_b0_brain.nii.gz -r T1_robex_restore.nii.gz -x T1_robex_restore.nii.gz -w template -o B0toT1SmallWarp -t 2


outputanatomical.nii.gz: dti_b0_brain.nii.gz T1_bias_correct.nii.gz
	antsIntermodalityIntrasubject.sh -d 3 -i dti_b0_brain.nii.gz -r T1_bias_#correct.nii.gz -x T1_bias_correct.nii.gz -w template -o output -t 2

# This is the unwarped image
mc_dti_unwarped.nii.gz: B0toT1Warped.nii.gz dti/mc_dti.nii.gz
	antsApplyTransforms -d 3 -e 3 -i dti/mc_dti.nii.gz -o mc_dti_unwarped.nii.gz -t B0toT11Warp.nii.gz -t B0toT10GenericAffine.mat -t b0_to_T1_flirt.txt -r T1_inverse.nii.gz

# This is the unwarped image - using the intermodality registration parameters
mc_dti_unwarped_small.nii.gz: B0toT1SmallWarpanatomical.nii.gz dti/mc_dti.nii.gz b0_to_T1_flirt_small.txt
	antsApplyTransforms -d 3 -e 3 -i dti/mc_dti.nii.gz -o mc_dti_unwarped_small.nii.gz -t B0toT1SmallWarp1Warp.nii.gz -t B0toT1SmallWarp0GenericAffine.mat -t b0_to_T1_flirt_small.txt -r T1_robex_restore.nii.gz


#T1_bias_correct_mask.nii.gz:  T1_bias_correct.nii.gz
	 bet $< $@ -m -f .15 


unwarped_ants/dti_FA.nii.gz: mc_dti_unwarped.nii.gz  T1_robex_restore_mask.nii.gz
	fit_tensor.sh -k mc_dti_unwarped.nii.gz -b dti.bval -r dti/bvec_mc.txt -M T1_robex_restore_mask.nii.gz -o unwarped_ants -f

unwarped_ants_small/dti_FA.nii.gz: mc_dti_unwarped_small.nii.gz  T1_robex_restore.nii.gz
	/project_space/Unwarping_evaluation/bin/fit_tensor.sh -k mc_dti_unwarped_small.nii.gz -b dti.bval -r dti/bvec_mc.txt -M  T1_robex_restore_mask.nii.gz  -o unwarped_ants_small -f

# downsample to 2mm
unwarped_ants_small/dti_FA_2mm.nii.gz: unwarped_ants_small/dti_FA.nii.gz T1_robex_restore.nii.gz
	flirt -in unwarped_ants_small/dti_FA.nii.gz -ref T1_robex_restore.nii.gz -out $@ -nosearch -applyisoxfm 2

# downsample to 2mm
unwarped_ants/dti_FA_2mm.nii.gz: unwarped_ants/dti_FA.nii.gz T1_robex_restore.nii.gz
	flirt -in unwarped_ants/dti_FA.nii.gz -ref T1_robex_restore.nii.gz -out $@ -nosearch -applyisoxfm 2

# Measure image similarity for two approaches
imagesimilarity.csv: unwarped_ants/dti_FA.nii.gz unwarped_ants_small/dti_FA.nii.gz T1_robex_restore.nii.gz
	MeasureImageSimilarity 3 2 unwarped_ants/dti_FA.nii.gz T1_robex_restore.nii.gz | grep metricvalue | awk '{print $$4}'  > $@ ;\
	MeasureImageSimilarity 3 2 unwarped_ants_small/dti_FA.nii.gz T1_robex_restore.nii.gz | grep metricvalue | awk '{print $$4}'  >> $@

#register ants_FA_2mm to FA standard_space image
ants_FAtoFAstandardWarped.nii.gz: FMRIB58_FA_1mm.nii.gz unwarped_ants/dti_FA_2mm.nii.gz
	antsRegistrationSyN.sh -d 3 -f FMRIB58_FA_1mm.nii.gz -m unwarped_ants/dti_FA_2mm.nii.gz -o ants_FAtoFAstandard -t s

#register ants_FA_small_2mm to FA standard_space image
ants_FA_smalltoFAstandardWarped.nii.gz: FMRIB58_FA_1mm.nii.gz unwarped_ants_small/dti_FA_2mm.nii.gz
	antsRegistrationSyN.sh -d 3 -f FMRIB58_FA_1mm.nii.gz -m unwarped_ants_small/dti_FA_2mm.nii.gz -o ants_FA_smalltoFAstandard -t s

# Rigid registration of FA map to T1 for registration comparison
dti-dtifit/dti_FA_to_T1.nii.gz: dti-dtifit/dti_FA.nii.gz T1_robex_restore.nii.gz
	flirt -in dti-dtifit/dti_FA.nii.gz -ref T1_robex_restore.nii.gz -dof 6 -out $@

# Calculation of similarity of fieldmap unwarped FA to T1
fieldmapSimilarity.csv: dti-dtifit/dti_FA_to_T1.nii.gz
	MeasureImageSimilarity 3 2 dti-dtifit/dti_FA_to_T1.nii.gz T1_robex_restore.nii.gz |grep metricvalue| awk '{print $$4}'> $@

#rim the ring of the FA iamge
dti-dtifit/dti_FA_mask.nii.gz: dti-dtifit/dti_FA.nii.gz
	/mnt/adrc/Unwarping_evaluation/bin/mask_out_top_and_bottom_slice.sh dti-dtifit/dti_FA.nii.gz dti-dtifit/dti_FA_mask.nii.gz 
dti-dtifit/dti_FA_ero.nii.gz: dti-dtifit/dti_FA_mask.nii.gz 
	fslmaths dti-dtifit/dti_FA_mask.nii.gz -ero dti-dtifit/dti_FA_ero.nii.gz

#register fieldmap_FA to FA standard_space image
# first linear registration, then nonlinear, then warp

dtifit_FA_to_std.mat: FMRIB58_FA_1mm.nii.gz dti-dtifit/dti_FA_ero.nii.gz
	flirt -in dti-dtifit/dti_FA_ero.nii.gz -ref FMRIB58_FA_1mm.nii.gz -out dtifit_FA_to_std.nii.gz -omat $@

dtifit_FA_to_std.txt: dtifit_FA_to_std.mat
	c3d_affine_tool -ref FMRIB58_FA_1mm.nii.gz -src dti-dtifit/dti_FA_ero.nii.gz dtifit_FA_to_std.mat -fsl2ras -oitk $@

dtifit_FA_to_FAWarped.nii.gz: FMRIB58_FA_1mm.nii.gz dtifit_FA_to_std.mat
	antsRegistrationSyNQuick.sh -d 3 -f FMRIB58_FA_1mm.nii.gz -m dtifit_FA_to_std.nii.gz -o  dtifit_FA_to_FA -t s

dtifit_FA_to_STDWarped.nii.gz: FMRIB58_FA_1mm.nii.gz dti-dtifit/dti_FA_ero.nii.gz dtifit_FA_to_std.txt dtifit_FA_to_FAWarped.nii.gz
	antsApplyTransforms 3 -i dti-dtifit/dti_FA_ero.nii.gz -r FMRIB58_FA_1mm.nii.gz -o dtifit_FA_to_STDWarped.nii.gz -t dtifit_FA_to_FAWarped.nii.gz -t dtifit_FA_to_FA0GenericAffine.mat -t dtifit_FA_to_std.txt

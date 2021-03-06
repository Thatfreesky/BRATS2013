#! /usr/bin/perl -w


###################################################
# Truth labels:  1 for necrosis
#                2 for edema
#                3 for non-enhancing tumor
#                4 for enhancing tumor
#
# The evaulation is done for 3 different tumor sub-compartements:
# Region 1: complete tumor (labels 1+2+3+4 for patient data, labesl 1+2 for synthetic data
# Region 2: Tumor core (labels 1+3+4 for patient data, label 2 for synthetic data
# Region 3: Enhancing tumor (label 4 for patient data, n.a. for synthetic data
###################################################


my $baseDir = '/Users/ntustison/Data/Public/BRATS-2/';
my $posteriorsDir = "${baseDir}/Posteriors2/";
my $refineDir = "${posteriorsDir}/REFINE_LABELS/";
my $gmmPosteriorsDir = "${posteriorsDir}/GMM_RF_POSTERIORS/";
my $mrfPosteriorsDir = "${posteriorsDir}/MAP_MRF_RF_POSTERIORS/";
my $truthDir = "${baseDir}/TruthLabels2/";

my @atroposTruthLabels = <${truthDir}/SimBRATS*atropos_truth.nii.gz>;

my $outputFile = "${baseDir}/SimBRATS_results.csv";

open( FILE, ">${outputFile}" );

print FILE "SubjectID,GMMxMRF,AllLabels,CompleteTumor,TumorCore,FalsePositiveCompleteTumor,FalseNegativeCompleteTumor\n";
for( my $i = 0; $i < @atroposTruthLabels; $i++ )
  {
  my @comps = split( '/', $atroposTruthLabels[$i] );

  my $prefix = $comps[-1];
  $prefix =~ s/_atropos_truth\.nii\.gz//;

  print "$prefix\n";

  my $trueLabels = $atroposTruthLabels[$i];
  my $trueCompleteTumor = "${truthDir}/${prefix}_COMPLETE_TUMOR.nii.gz";
  my $trueTumorCore = "${truthDir}/${prefix}_TUMOR_CORE.nii.gz";
  my $trueEnhancingTumor = "${truthDir}/${prefix}_ENHANCING_TUMOR.nii.gz";

  `ThresholdImage 3 $trueLabels $trueCompleteTumor 4 5 1 0`;
  `ThresholdImage 3 $trueLabels $trueTumorCore 5 5 1 0`;

  my $gmmLabels = "${gmmPosteriorsDir}/${prefix}_RF_LABELS.nii.gz";
#   if( ! -e $gmmLabels )
#     {
    my @gmmPosteriors = <${gmmPosteriorsDir}/${prefix}_RF_POSTERIORS*.nii.gz>;
    `MultipleOperateImages 3 seg $gmmLabels none @gmmPosteriors`;
#     }
  my $gmmCompleteTumor = "${gmmPosteriorsDir}/${prefix}_RF_LABELS_COMPLETE_TUMOR.nii.gz";
  my $gmmTumorCore = "${gmmPosteriorsDir}/${prefix}_RF_LABELS_TUMOR_CORE.nii.gz";
  my $gmmEnhancingTumor = "${gmmPosteriorsDir}/${prefix}_RF_LABELS_ENHANCING_TUMOR.nii.gz";

  `ThresholdImage 3 $gmmLabels $gmmCompleteTumor 4 5 1 0`;
  `ThresholdImage 3 $gmmLabels $gmmTumorCore 5 5 1 0`;

  my $mrfLabels = "${mrfPosteriorsDir}/${prefix}_RF_LABELS.nii.gz";
#   if( ! -e $mrfLabels )
#     {
    my @mrfPosteriors = <${mrfPosteriorsDir}/${prefix}_RF_POSTERIORS*.nii.gz>;
    `MultipleOperateImages 3 seg $mrfLabels none @mrfPosteriors`;
#     }
  my $mrfCompleteTumor = "${mrfPosteriorsDir}/${prefix}_RF_LABELS_COMPLETE_TUMOR.nii.gz";
  my $mrfTumorCore = "${mrfPosteriorsDir}/${prefix}_RF_LABELS_TUMOR_CORE.nii.gz";
  my $mrfEnhancingTumor = "${mrfPosteriorsDir}/${prefix}_RF_LABELS_ENHANCING_TUMOR.nii.gz";

  `ThresholdImage 3 $mrfLabels $mrfCompleteTumor 4 5 1 0`;
  `ThresholdImage 3 $mrfLabels $mrfTumorCore 5 5 1 0`;

#   my $stapleLabels = "${refineDir}/${prefix}_REFINEMENT_STAPLE_LABELS.nii.gz";
#   my $stapleCompleteTumor = "${refineDir}/${prefix}_REFINEMENT_STAPLE_LABELS_COMPLETE_TUMOR.nii.gz";
#   my $stapleTumorCore = "${refineDir}/${prefix}_REFINEMENT_STAPLE_LABELS_TUMOR_CORE.nii.gz";
#   my $stapleEnhancingTumor = "${refineDir}/${prefix}_REFINEMENT_STAPLE_LABELS_ENHANCING_TUMOR.nii.gz";
#
#   `ThresholdImage 3 $stapleLabels $stapleCompleteTumor 4 5 1 0`;
#   `ThresholdImage 3 $stapleLabels $stapleTumorCore 5 5 1 0`;

  ########################################################################

  my @gmmMeasuresLabels = `LabelOverlapMeasures 3 $gmmLabels $trueLabels`;
  my @gmmMeasuresCompleteTumor = `LabelOverlapMeasures 3 $gmmCompleteTumor $trueCompleteTumor`;
  my @gmmMeasuresTumorCore = `LabelOverlapMeasures 3 $gmmTumorCore $trueTumorCore`;
  my @gmmStatsLabels = split( ' ', $gmmMeasuresLabels[2] );
  my @gmmStatsCompleteTumor = split( ' ', $gmmMeasuresCompleteTumor[2] );
  my @gmmStatsTumorCore = split( ' ', $gmmMeasuresTumorCore[2] );
  print FILE "${prefix},GMM,${gmmStatsLabels[2]},${gmmStatsCompleteTumor[2]},${gmmStatsTumorCore[2]},${gmmStatsCompleteTumor[5]},${gmmStatsCompleteTumor[4]}\n";

  my @mrfMeasuresLabels = `LabelOverlapMeasures 3 $mrfLabels $trueLabels`;
  my @mrfMeasuresCompleteTumor = `LabelOverlapMeasures 3 $mrfCompleteTumor $trueCompleteTumor`;
  my @mrfMeasuresTumorCore = `LabelOverlapMeasures 3 $mrfTumorCore $trueTumorCore`;
  my @mrfStatsLabels = split( ' ', $mrfMeasuresLabels[2] );
  my @mrfStatsCompleteTumor = split( ' ', $mrfMeasuresCompleteTumor[2] );
  my @mrfStatsTumorCore = split( ' ', $mrfMeasuresTumorCore[2] );
  print FILE "${prefix},MRF,${mrfStatsLabels[2]},${mrfStatsCompleteTumor[2]},${mrfStatsTumorCore[2]},${mrfStatsCompleteTumor[5]},${mrfStatsCompleteTumor[4]}\n";

#   my @stapleMeasuresLabels = `LabelOverlapMeasures 3 $stapleLabels $trueLabels`;
#   my @stapleMeasuresCompleteTumor = `LabelOverlapMeasures 3 $stapleCompleteTumor $trueCompleteTumor`;
#   my @stapleMeasuresTumorCore = `LabelOverlapMeasures 3 $stapleTumorCore $trueTumorCore`;
#   my @stapleStatsLabels = split( ' ', $stapleMeasuresLabels[2] );
#   my @stapleStatsCompleteTumor = split( ' ', $stapleMeasuresCompleteTumor[2] );
#   my @stapleStatsTumorCore = split( ' ', $stapleMeasuresTumorCore[2] );
#   print FILE "${prefix},STAPLE,${stapleStatsLabels[2]},${stapleStatsCompleteTumor[2]},${stapleStatsTumorCore[2]},${stapleStatsCompleteTumor[5]},${stapleStatsCompleteTumor[4]}\n";
  }

close( FILE );

version 1.0

import "types.wdl"
import "subworkflows/sequence_to_bqsr_nonhuman.wdl" as stbn
import "subworkflows/qc_exome_no_verify_bam.wdl" as qenvb

workflow alignmentExomeNonhuman {
  input {
    File reference
    File reference_fai
    File reference_dict
    File reference_alt
    File reference_amb
    File reference_ann
    File reference_bwt
    File reference_pac
    File reference_sa
    Array[SequenceData] sequence
    TrimmingOptions? trimming
    String picard_metric_accumulation_level
    Int? qc_minimum_mapping_quality
    Int? qc_minimum_base_quality
    String? final_name
    File bait_intervals
    File target_intervals
    Array[LabelledFile] per_base_intervals
    Array[LabelledFile] per_target_intervals
    Array[LabelledFile] summary_intervals
  }


  call stbn.sequenceToBqsrNonhuman as alignment {
    input:
    reference=reference,
    reference_alt=reference_alt,
    reference_amb=reference_amb,
    reference_ann=reference_ann,
    reference_bwt=reference_bwt,
    reference_pac=reference_pac,
    reference_sa=reference_sa,
    unaligned=sequence,
    trimming=trimming,
    final_name=final_name
  }

  call qenvb.qcExomeNoVerifyBam as qc {
    input:
    bam=alignment.final_bam,
    bai=alignment.final_bam_bai,
    reference=reference,
    reference_fai=reference_fai,
    reference_dict=reference_dict,
    bait_intervals=bait_intervals,
    target_intervals=target_intervals,
    per_base_intervals=per_base_intervals,
    per_target_intervals=per_target_intervals,
    summary_intervals=summary_intervals,
    picard_metric_accumulation_level=picard_metric_accumulation_level,
    minimum_mapping_quality=qc_minimum_mapping_quality,
    minimum_base_quality=qc_minimum_base_quality
  }

  output {
    File bam = alignment.final_bam
    File bam_bai = alignment.final_bam_bai
    File mark_duplicates_metrics = alignment.mark_duplicates_metrics_file
    File insert_size_metrics = qc.insert_size_metrics
    File insert_size_histogram = qc.insert_size_histogram
    File alignment_summary_metrics = qc.alignment_summary_metrics
    File hs_metrics = qc.hs_metrics
    Array[File] per_target_coverage_metrics = qc.per_target_coverage_metrics
    Array[File] per_target_hs_metrics = qc.per_target_hs_metrics
    Array[File] per_base_coverage_metrics = qc.per_base_coverage_metrics
    Array[File] per_base_hs_metrics = qc.per_base_hs_metrics
    Array[File] summary_hs_metrics = qc.summary_hs_metrics
    File flagstats = qc.flagstats
  }
}

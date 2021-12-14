version 1.0

import "subworkflows/qc_wgs.wdl" as qw
import "subworkflows/sequence_to_bqsr.wdl" as stb
import "types.wdl"

workflow alignmentWgs {
  input {
    File reference
    File reference_fai
    File reference_dict
    File reference_amb
    File reference_ann
    File reference_bwt
    File reference_pac
    File reference_sa

    Array[SequenceData] sequence
    TrimmingOptions? trimming

    File omni_vcf
    File omni_vcf_tbi

    File intervals
    String picard_metric_accumulation_level
    Array[File] bqsr_known_sites
    Array[File] bqsr_known_sites_tbis

    Array[String]? bqsr_intervals
    Int? minimum_mapping_quality
    Int? minimum_base_quality
    Array[LabelledFile] per_base_intervals
    Array[LabelledFile] per_target_intervals
    Array[LabelledFile] summary_intervals
    String? sample_name
  }

  call stb.sequenceToBqsr as alignment {
    input:
    reference=reference,
    reference_fai=reference_fai,
    reference_dict=reference_dict,
    reference_amb=reference_amb,
    reference_ann=reference_ann,
    reference_bwt=reference_bwt,
    reference_pac=reference_pac,
    reference_sa=reference_sa,
    unaligned=sequence,
    trimming=trimming,
    bqsr_known_sites=bqsr_known_sites,
    bqsr_known_sites_tbi=bqsr_known_sites_tbi,
    bqsr_intervals=bqsr_intervals,
    final_name=sample_name
  }

  call qw.qcWgs as qc {
    input:
    sample_name=sample_name,
    bam=alignment.final_bam,
    reference=reference,
    reference_fai=reference_fai,
    reference_dict=reference_dict,
    omni_vcf=omni_vcf,
    omni_vcf_tbi=omni_vcf_tbi,
    intervals=intervals,
    picard_metric_accumulation_level=picard_metric_accumulation_level,
    minimum_mapping_quality=minimum_mapping_quality,
    minimum_base_quality=minimum_base_quality,
    per_base_intervals=per_base_intervals,
    per_target_intervals=per_target_intervals,
    summary_intervals=summary_intervals
  }

  output {
    File bam = alignment.final_bam
    File mark_duplicates_metrics = alignment.mark_duplicates_metrics_file
    File insert_size_metrics = qc.insert_size_metrics
    File insert_size_histogram = qc.insert_size_histogram
    File alignment_summary_metrics = qc.alignment_summary_metrics
    File gc_bias_metrics = qc.gc_bias_metrics
    File gc_bias_metrics_chart = qc.gc_bias_metrics_chart
    File gc_bias_metrics_summary = qc.gc_bias_metrics_summary
    File wgs_metrics = qc.wgs_metrics
    File flagstats = qc.flagstats
    File verify_bam_id_metrics = qc.verify_bam_id_metrics
    File verify_bam_id_depth = qc.verify_bam_id_depth
    Array[File] per_base_coverage_metrics = qc.per_base_coverage_metrics
    Array[File] per_base_hs_metrics = qc.per_base_hs_metrics
    Array[File] per_target_coverage_metrics = qc.per_target_coverage_metrics
    Array[File] per_target_hs_metrics = qc.per_target_hs_metrics
    Array[File] summary_hs_metrics = qc.summary_hs_metrics
  }
}
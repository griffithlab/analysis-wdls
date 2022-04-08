version 1.0

task pvacseq {
  input {
    Int n_threads = 8
    File input_vcf
    File input_vcf_tbi
    String sample_name
    Array[String] alleles
    Array[String] prediction_algorithms

    Array[Int]? epitope_lengths_class_i
    Array[Int]? epitope_lengths_class_ii
    Int? binding_threshold
    Int? percentile_threshold
    Int? iedb_retries

    String? normal_sample_name
    String? net_chop_method  # enum [cterm , 20s]
    String? top_score_metric  # enum [lowest, median]
    Float? net_chop_threshold
    String? additional_report_columns  # enum [sample_name]
    Int? fasta_size
    Int? downstream_sequence_length
    Boolean exclude_nas = false
    File? phased_proximal_variants_vcf
    File? phased_proximal_variants_vcf_tbi
    Float? minimum_fold_change
    Int? normal_cov
    Int? tdna_cov
    Int? trna_cov
    Float? normal_vaf
    Float? tdna_vaf
    Float? trna_vaf
    Float? expn_val
    Int? maximum_transcript_support_level  # enum [1, 2, 3, 4, 5]

    Boolean allele_specific_binding_thresholds = false
    Boolean keep_tmp_files = false
    Boolean netmhc_stab = false
    Boolean run_reference_proteome_similarity = false

    # TODO(john) where does blastp_db go in the call?
    String? blastp_db  # enum [refseq_select_prot, refseq_protein]
    Float? tumor_purity
  }

  Float input_size = size([input_vcf, input_vcf_tbi], "GB")
  Float phased_variants_size = size([phased_proximal_variants_vcf, phased_proximal_variants_vcf_tbi], "GB")
  Int space_needed_gb = 10 + round(input_size + phased_variants_size)
  runtime {
    memory: "16GB"
    cpu: n_threads
    docker: "griffithlab/pvactools:3.0.0"
    disks: "local-disk ~{space_needed_gb} SSD"
  }

  # explicit typing required, don't inline
  Array[Int] epitope_i = select_first([epitope_lengths_class_i, []])
  Array[Int] epitope_ii = select_first([epitope_lengths_class_ii, []])
  command <<<
    ln -s "$TMPDIR" /tmp/pvacseq && export TMPDIR=/tmp/pvacseq && \
    /usr/local/bin/pvacseq run --iedb-install-directory /opt/iedb \
    --blastp-path /opt/ncbi-blast-2.12.0+/bin/blastp \
    ~{if defined(blastp_db) then "--blastp-db " + select_first([blastp_db]) else ""} \
    --pass-only \
    ~{if defined(tumor_purity) then "--tumor-purity " + select_first([tumor_purity]) else ""} \
    ~{if defined(epitope_lengths_class_i ) then "-e1 " else ""} ~{sep="," epitope_i} \
    ~{if defined(epitope_lengths_class_ii) then "-e2 " else ""} ~{sep="," epitope_ii} \
    ~{if defined(binding_threshold) then "-b ~{binding_threshold}" else ""} \
    ~{if defined(percentile_threshold) then "--percentile-threshold ~{percentile_threshold}" else ""} \
    ~{if allele_specific_binding_thresholds then "--allele-specific-binding-thresholds" else ""} \
    ~{if defined(iedb_retries) then "-r ~{iedb_retries}" else ""} \
    ~{if keep_tmp_files then "-k" else ""} \
    ~{if defined(normal_sample_name) then "--normal-sample-name ~{normal_sample_name}" else ""} \
    ~{if defined(net_chop_method) then "--net-chop-method ~{net_chop_method}" else ""} \
    ~{if netmhc_stab then "--netmhc-stab" else ""} \
    ~{if run_reference_proteome_similarity then "--run-reference-proteome-similarity" else ""} \
    ~{if defined(top_score_metric) then "-m ~{top_score_metric}" else ""} \
    ~{if defined(net_chop_threshold) then "--net-chop-threshold ~{net_chop_threshold}" else ""} \
    ~{if defined(additional_report_columns) then "-m ~{additional_report_columns}" else ""} \
    ~{if defined(fasta_size) then "-s ~{fasta_size}" else ""} \
    ~{if defined(downstream_sequence_length) then "-d ~{downstream_sequence_length}" else ""} \
    ~{if exclude_nas then "--exclude-NAs" else ""} \
    ~{if defined(phased_proximal_variants_vcf) then "-p ~{phased_proximal_variants_vcf}" else ""} \
    ~{if defined(minimum_fold_change) then "-c ~{minimum_fold_change}" else ""} \
    ~{if defined(normal_cov) then "--normal-cov ~{normal_cov}" else ""} \
    ~{if defined(tdna_cov) then "--tdna-cov ~{tdna_cov}" else ""} \
    ~{if defined(trna_cov) then "--trna-cov ~{trna_cov}" else ""} \
    ~{if defined(normal_vaf) then "--normal-vaf ~{normal_vaf}" else ""} \
    ~{if defined(tdna_vaf) then "--tdna-vaf ~{tdna_vaf}" else ""} \
    ~{if defined(trna_vaf) then "--trna-vaf ~{trna_vaf}" else ""} \
    ~{if defined(expn_val) then "--expn-val ~{expn_val}" else ""} \
    ~{if defined(maximum_transcript_support_level) then "--maximum-transcript-support-level ~{maximum_transcript_support_level}" else ""} \
    --n-threads ~{n_threads} \
    ~{input_vcf} ~{sample_name} ~{sep="," alleles} ~{sep=" " prediction_algorithms} \
    pvacseq_predictions
  >>>

  output {
    File? mhc_i_all_epitopes = "pvacseq_predictions/MHC_Class_I/~{sample_name}.all_epitopes.tsv"
    File? mhc_i_aggregated_report = "pvacseq_predictions/MHC_Class_I/~{sample_name}.all_epitopes.aggregated.tsv"
    File? mhc_i_filtered_epitopes = "pvacseq_predictions/MHC_Class_I/~{sample_name}.filtered.tsv"
    File? mhc_i_aggregated_metrics_file = "pvacseq_predictions/MHC_Class_I/" + sample_name + ".all_epitopes.aggregated.metrics.json"
    File? mhc_ii_all_epitopes = "pvacseq_predictions/MHC_Class_II/~{sample_name}.all_epitopes.tsv"
    File? mhc_ii_aggregated_report = "pvacseq_predictions/MHC_Class_II/~{sample_name}.all_epitopes.aggregated.tsv"
    File? mhc_ii_filtered_epitopes = "pvacseq_predictions/MHC_Class_II/~{sample_name}.filtered.tsv"
    File? mhc_ii_aggregated_metrics_file = "pvacseq_predictions/MHC_Class_II/" + sample_name + ".all_epitopes.aggregated.metrics.json"
    File? combined_all_epitopes = "pvacseq_predictions/combined/~{sample_name}.all_epitopes.tsv"
    File? combined_aggregated_report = "pvacseq_predictions/combined/~{sample_name}.all_epitopes.aggregated.tsv"
    File? combined_filtered_epitopes = "pvacseq_predictions/combined/~{sample_name}.filtered.tsv"
    File? combined_aggregated_metrics_file = "pvacseq_predictions/combined/" + sample_name + ".all_epitopes.aggregated.metrics.json"
    Array[File] pvacseq_predictions = glob("pvacseq_predictions/**/*")
  }
}

workflow wf {
  input {
    Int? n_threads
    File input_vcf
    File input_vcf_tbi
    String sample_name
    Array[String] alleles
    Array[String] prediction_algorithms

    Array[Int]? epitope_lengths_class_i
    Array[Int]? epitope_lengths_class_ii
    Int? binding_threshold
    Int? percentile_threshold
    Int? iedb_retries

    String? normal_sample_name
    String? net_chop_method  # enum [cterm , 20s]
    String? top_score_metric  # enum [lowest, median]
    Float? net_chop_threshold
    String? additional_report_columns  # enum [sample_name]
    Int? fasta_size
    Int? downstream_sequence_length
    Boolean exclude_nas = false
    File? phased_proximal_variants_vcf
    File? phased_proximal_variants_vcf_tbi
    Float? minimum_fold_change
    Int? normal_cov
    Int? tdna_cov
    Int? trna_cov
    Float? normal_vaf
    Float? tdna_vaf
    Float? trna_vaf
    Float? expn_val
    String? maximum_transcript_support_level  # enum [1, 2, 3, 4, 5]

    Boolean? allele_specific_binding_thresholds
    Boolean? keep_tmp_files
    Boolean? netmhc_stab
    Boolean? run_reference_proteome_similarity
  }
  call pvacseq {
    input:
    n_threads=n_threads,
    input_vcf=input_vcf,
    input_vcf_tbi=input_vcf_tbi,
    sample_name=sample_name,
    alleles=alleles,
    prediction_algorithms=prediction_algorithms,
    epitope_lengths_class_i=epitope_lengths_class_i,
    epitope_lengths_class_ii=epitope_lengths_class_ii,
    binding_threshold=binding_threshold,
    percentile_threshold=percentile_threshold,
    iedb_retries=iedb_retries,
    normal_sample_name=normal_sample_name,
    net_chop_method=net_chop_method,
    top_score_metric=top_score_metric,
    net_chop_threshold=net_chop_threshold,
    additional_report_columns=additional_report_columns,
    fasta_size=fasta_size,
    downstream_sequence_length=downstream_sequence_length,
    exclude_nas=exclude_nas,
    phased_proximal_variants_vcf=phased_proximal_variants_vcf,
    phased_proximal_variants_vcf_tbi=phased_proximal_variants_vcf_tbi,
    minimum_fold_change=minimum_fold_change,
    normal_cov=normal_cov,
    tdna_cov=tdna_cov,
    trna_cov=trna_cov,
    normal_vaf=normal_vaf,
    tdna_vaf=tdna_vaf,
    trna_vaf=trna_vaf,
    expn_val=expn_val,
    maximum_transcript_support_level=maximum_transcript_support_level,
    allele_specific_binding_thresholds=allele_specific_binding_thresholds,
    keep_tmp_files=keep_tmp_files,
    netmhc_stab=netmhc_stab,
    run_reference_proteome_similarity=run_reference_proteome_similarity
  }
}

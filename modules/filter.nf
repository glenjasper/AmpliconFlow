process FILTER {
  tag { fastq.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/filtered", mode: 'copy', overwrite: true

  input:
    path fastq
    val maxee
    val minlen
    val maxlen
    val threads

  output:
    tuple path('filtered.fq'), path('filtered.fa')

  script:
  """
  set -euo pipefail

  MAXLEN_OPT=""
  if [ -n "${maxlen}" ]; then
    MAXLEN_OPT="--fastq_maxlen ${maxlen}"
  fi

  vsearch --fastq_filter ${fastq} \
          --fastq_maxee ${maxee} \
          --fastq_minlen ${minlen} \
          --eeout \
          --fastqout filtered.fq \
          --fastaout filtered.fa \
          --fasta_width 0 \
          --fastq_qmax 45 \
          --threads ${threads} \$MAXLEN_OPT
  """
}

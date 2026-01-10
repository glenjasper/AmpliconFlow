process SUBSAMPLE {
  tag { fastq.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/subsample", mode: 'copy', overwrite: true

  input:
    path fastq
    val subset_size
    val threads

  output:
    path 'subset.fq'

  script:
  """
  set -euo pipefail

  vsearch --fastx_subsample ${fastq} \
          --sample_size ${subset_size} \
          --fastqout subset.fq \
          --threads ${threads}
  """
}

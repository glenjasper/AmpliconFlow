process FASTQC {
  tag { fastq.getName() }
  cpus Math.min(params.threads as int, 4)

  publishDir "${params.output_path}/qc", mode: 'copy', overwrite: true

  input:
    path fastq

  output:
    tuple path("${fastq.baseName}_fastqc.zip"), path("${fastq.baseName}_fastqc.html")

  script:
  """
  set -euo pipefail

  fastqc -t ${task.cpus} -o . ${fastq}
  """
}

process FASTQC {
  tag { fastq.getName() }
  cpus Math.min(params.threads as int, 4)

  conda "${projectDir}/envs/fastqc.yml"

  publishDir "${params.output_path}/qc", mode: 'copy', overwrite: true

  input:
    path fastq

  output:
    tuple path("*_fastqc.zip"), path("*_fastqc.html")

  script:
  """
  set -euo pipefail

  fastqc -t ${task.cpus} -o . ${fastq}
  """
}

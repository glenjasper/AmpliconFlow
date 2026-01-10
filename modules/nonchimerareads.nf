process NONCHIMERA_READS {
  tag { "map reads → nonchimera" }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/nonchimera_reads", mode: 'copy', overwrite: true

  input:
    path fasta_reads
    path uc_derep
    path fasta_nonchim_derep

  output:
    tuple path('nonchimeras.fa'), path('status.txt')

  script:
  """
  set -euo pipefail

  python3 ${params.scripts_path}/map.py \
          ${fasta_reads} \
          ${uc_derep} \
          ${fasta_nonchim_derep} \
          nonchimeras.fa

  if [[ ! -s nonchimeras.fa ]]; then
    echo "EMPTY" > status.txt
  else
    echo "OK" > status.txt
  fi
  """
}

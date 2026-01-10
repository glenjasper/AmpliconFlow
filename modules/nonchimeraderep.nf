process NONCHIMERA_DEREP {
  tag { "map derep → nonchimera" }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/nonchimera_derep", mode: 'copy', overwrite: true

  input:
    path fasta_derep
    path uc_precust
    path fasta_nonchim_ref

  output:
    tuple path('nonchimeras.dereplicated.fa'), path('status.txt')

  script:
  """
  set -euo pipefail

  python3 ${params.scripts_path}/map.py \
          ${fasta_derep} \
          ${uc_precust} \
          ${fasta_nonchim_ref} \
          nonchimeras.dereplicated.fa

  if [[ ! -s nonchimeras.dereplicated.fa ]]; then
    echo "EMPTY" > status.txt
  else
    echo "OK" > status.txt
  fi
  """
}

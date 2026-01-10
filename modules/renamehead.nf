process RENAME_HEAD {
  tag { db_fasta.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/database", mode: 'copy', overwrite: true

  input:
    path db_fasta
    val db_type

  output:
    tuple path("${db_type}_for_asv.fa"), path('status.txt')

  script:
  """
  set -euo pipefail

  python3 ${params.scripts_path}/rename_database.py \
          ${db_type} \
          ${db_fasta}

  if [[ ! -s "${db_type}_for_asv.fa" ]]; then
    echo "EMPTY" > status.txt
  else
    echo "OK" > status.txt
  fi
  """
}

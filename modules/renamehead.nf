process RENAME_HEAD {
  tag { db_fasta.getName() }
  cpus 1
  time '2h'

  conda "${projectDir}/envs/python.yml"

  publishDir "${params.output_path}/database", mode: 'copy', overwrite: true

  input:
    path db_fasta
    val db_type
    val taxmap
    val taxslv

  output:
    tuple path("${db_type}.fa"), path('status.txt')

  script:
  """
  set -euo pipefail

  if [[ "${db_type}" == "silva" ]]; then
      python3 ${params.scripts_path}/rename_database.py \
              -d ${db_type} \
              -i ${db_fasta} \
              --taxmap ${taxmap} \
              --taxslv ${taxslv}
  else
      python3 ${params.scripts_path}/rename_database.py \
              -d ${db_type} \
              -i ${db_fasta}
  fi

  if [[ ! -s "${db_type}.fa" ]]; then
    echo "EMPTY" > status.txt
  else
    echo "OK" > status.txt
  fi
  """
}

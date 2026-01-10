process MAKE_DB {
  tag { db_fasta.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/database", mode: 'copy', overwrite: true

  input:
    path db_fasta
    val db_type

  output:
    tuple val("${db_type}_db"),
          path("${db_type}_db.*"),
          path('status.txt')

  script:
  """
  set -euo pipefail

  makeblastdb -in ${db_fasta} \
              -dbtype nucl \
              -out ${db_type}_db

  if [[ ! -s "${db_type}_db.nsq" ]]; then
    echo "EMPTY" > status.txt
  else
    echo "OK" > status.txt
  fi
  """
}

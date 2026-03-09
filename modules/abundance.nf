process ABUNDANCE {
  tag { file_taxonomy.getName() }
  cpus 1
  time '2h'

  conda "${projectDir}/envs/python.yml"

  publishDir "${params.output_path}/abundance", mode: 'copy', overwrite: true

  input:
    path file_taxonomy
    path file_counts
    val database_type
    val approach

  output:
    path 'abundances.csv'

  script:
  """
  set -euo pipefail

  python3 ${params.scripts_path}/get_abundances_table.py \
          -a ${approach} \
          -f ${database_type} \
          -c ${file_taxonomy} \
          -b ${file_counts} \
          -o abundances.csv
  """
}

process ABUNDANCE_ASV {
  tag { file_taxonomy.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/abundance", mode: 'copy', overwrite: true

  input:
    path file_counts
    path file_taxonomy

  output:
    path 'asv.abundances.csv'

  script:
  """
  set -euo pipefail

  python3 ${params.scripts_path}/get_abundances_table_asv.py \
          ${file_taxonomy} \
          ${file_counts} \
          asv.abundances.csv
  """
}

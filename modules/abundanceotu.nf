process ABUNDANCE_OTU {
  tag { file_taxonomy.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/abundance", mode: 'copy', overwrite: true

  input:
    path file_taxonomy
    path file_otutab
    val database_type

  output:
    path 'otu.abundances.csv'

  script:
  """
  set -euo pipefail

  python3 ${params.scripts_path}/get_abundances_table_otu.py \
          ${database_type} \
          ${file_taxonomy} \
          ${file_otutab} \
          otu.abundances.csv
  """
}

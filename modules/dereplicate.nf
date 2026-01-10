process DEREPLICATE {
  tag { fasta.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/dereplicated", mode: 'copy', overwrite: true

  input:
    path fasta
    val entity

  output:
    tuple path('dereplicated.fa'), path('dereplicated.uc')

  when:
    entity in ['asv', 'otu']

  script:
  """
  set -euo pipefail

  NON_SINGLETON_OPT=""
  if [[ "${entity}" == "otu" ]]; then
    NON_SINGLETON_OPT="--minuniquesize 2"
  fi

  vsearch --derep_fulllength ${fasta} \
          --strand plus \
          --sizein \
          --sizeout \
          --fasta_width 0 \
          --uc dereplicated.uc \
          --output dereplicated.fa \$NON_SINGLETON_OPT
  """
}

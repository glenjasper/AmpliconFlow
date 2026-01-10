process COUNT {
  tag { fasta_asv.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/counted", mode: 'copy', overwrite: true

  input:
    path fasta_asv
    path fasta_filtered
    val high_identity
    val threads

  output:
    tuple path('asv.counts.txt'), path('status.txt')

  script:
  """
  set -euo pipefail

  vsearch --usearch_global ${fasta_filtered} \
          --db ${fasta_asv} \
          --id ${high_identity} \
          --otutabout asv.counts.txt \
          --threads ${threads}

  if [[ ! -s asv.counts.txt ]]; then
    echo "EMPTY" > status.txt
  else
    echo "OK" > status.txt
  fi
  """
}

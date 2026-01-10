process DECHIMERA_REF {
  tag { fasta.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/dechimered_ref", mode: 'copy', overwrite: true

  input:
    path fasta
    path fasta_db
    val threads

  output:
    tuple path('ref.nonchimeras.fa'), path('status.txt')

  script:
  """
  set -euo pipefail

  vsearch --uchime_ref ${fasta} \
          --db ${fasta_db} \
          --sizein \
          --sizeout \
          --fasta_width 0 \
          --nonchimeras ref.nonchimeras.fa \
          --threads ${threads}

  if [[ ! -s ref.nonchimeras.fa ]]; then
    echo "EMPTY" > status.txt
  else
    echo "OK" > status.txt
  fi
  """
}

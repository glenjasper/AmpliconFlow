process PRECLUSTER {
  tag { fasta.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/preclustered", mode: 'copy', overwrite: true

  input:
    path fasta
    val cluster_identity
    val threads

  output:
    tuple path('preclustered.fa'), path('preclustered.uc'), path('status.txt')

  script:
  """
  set -euo pipefail

  vsearch --cluster_size ${fasta} \
          --id ${cluster_identity} \
          --strand plus \
          --sizein \
          --sizeout \
          --fasta_width 0 \
          --uc preclustered.uc \
          --centroids preclustered.fa \
          --threads ${threads}

  if [[ ! -s preclustered.fa ]]; then
    echo "EMPTY" > status.txt
  else
    echo "OK" > status.txt
  fi
  """
}

process DENOISE {
  tag { fasta.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/denoised", mode: 'copy', overwrite: true

  input:
    path fasta
    val threads

  output:
    tuple path('denoised.centroids.fa'), path('status.txt')

  script:
  """
  set -euo pipefail

  vsearch --cluster_unoise ${fasta} \
          --sizein \
          --sizeout \
          --centroids denoised.centroids.fa \
          --minsize 8 \
          --threads ${threads}

  if [[ ! -s denoised.centroids.fa ]]; then
    echo "EMPTY" > status.txt
  else
    echo "OK" > status.txt
  fi
  """
}

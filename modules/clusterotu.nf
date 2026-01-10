process CLUSTER_OTU {
  tag { "cluster OTUs ${(cluster_identity * 100).toInteger()}%" }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/cluster_otu", mode: 'copy', overwrite: true

  input:
    path fasta_nonchim
    val cluster_identity
    val threads

  output:
    tuple path('otu.fa'),
          path('clustered.uc'),
          path('otutab.txt'),
          path('otutab.biom'),
          path('status.txt')

  script:
  """
  set -euo pipefail

  vsearch --cluster_size ${fasta_nonchim} \
          --id ${cluster_identity} \
          --strand plus \
          --sizein \
          --sizeout \
          --fasta_width 0 \
          --relabel OTU_ \
          --uc clustered.uc \
          --centroids otu.fa \
          --otutabout otutab.txt \
          --biomout otutab.biom \
          --threads ${threads}

  if [[ ! -s otu.fa ]]; then
    echo "EMPTY" > status.txt
  else
    echo "OK" > status.txt
  fi
  """
}

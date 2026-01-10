process TAXONOMY_ASV {
  tag { fasta_asv.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/taxonomy", mode: 'copy', overwrite: true

  input:
    path fasta_asv
    path fasta_db
    val cutoff
    val threads

  output:
    tuple path('asv.taxonomy.txt'), path('status.txt')

  script:
  """
  set -euo pipefail

  vsearch --sintax ${fasta_asv} \
          --db ${fasta_db} \
          --strand both \
          --sintax_cutoff ${cutoff} \
          --tabbedout asv.taxonomy.txt \
          --threads ${threads}

  if [[ ! -s asv.taxonomy.txt ]]; then
    echo "EMPTY" > status.txt
  else
    echo "OK" > status.txt
  fi
  """
}

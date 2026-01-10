process TAXONOMY_OTU {
  tag { fasta_otu.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/taxonomy", mode: 'copy', overwrite: true

  input:
    path fasta_otu
    val blast_identity
    val database_prefix
    path database_bins
    val threads

  output:
    tuple path('taxonomy.blast'), path('status.txt')

  script:
  """
  set -euo pipefail

  blastn -db ${database_prefix} \
         -query ${fasta_otu} \
         -perc_identity ${blast_identity} \
         -qcov_hsp_perc 90.0 \
         -outfmt "6 qseqid sseqid stitle pident length mismatch gapopen qstart qend sstart send evalue bitscore qcovhsp qcovs" \
         -out taxonomy.blast \
         -num_threads ${threads}

  if [[ ! -s taxonomy.blast ]]; then
    echo "EMPTY" > status.txt
  else
    echo "OK" > status.txt
  fi
  """
}

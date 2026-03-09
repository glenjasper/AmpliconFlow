process TAXONOMY_OTU {
  tag { fasta_otu.getName() }
  cpus 1
  time '2h'

  conda "${projectDir}/envs/blast.yml"

  publishDir "${params.output_path}/taxonomy", mode: 'copy', overwrite: true

  input:
    path fasta_otu
    val blast_identity
    val blast_coverage
    val blast_max_target
    val blast_evalue
    val database_prefix
    path database_bins
    val threads

  output:
    tuple path('taxonomy.blast'), path('status.txt')

  script:
  """
  set -euo pipefail

  IDENTITY=\$(awk 'BEGIN { printf "%.2f", ${blast_identity} * 100 }')
  COVEGARE=\$(awk 'BEGIN { printf "%.2f", ${blast_coverage} * 100 }')

  blastn -db ${database_prefix} \
         -query ${fasta_otu} \
         -perc_identity \${IDENTITY} \
         -qcov_hsp_perc \${COVEGARE} \
         -max_target_seqs ${blast_max_target} \
         -evalue ${blast_evalue} \
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

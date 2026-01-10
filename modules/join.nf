process JOIN {
  tag { "unify all" }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/joined", mode: 'copy', overwrite: true

  input:
    path merged_files

  output:
    tuple path('joined.fq'), path('joined.stats.txt')

  script:
  """
  set -euo pipefail

  cat ${merged_files.join(' ')} > joined.fq

  if [ -s joined.fq ]; then
      nlines=\$(wc -l < joined.fq)
      nseq=\$((nlines / 4))
  else
      nseq=0
  fi

  echo "Number_of_sequences=\$nseq" > joined.stats.txt
  """
}

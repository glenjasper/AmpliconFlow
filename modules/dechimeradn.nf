process DECHIMERA_DENOVO {
  tag { fasta.getName() }
  cpus 1
  time '2h'

  conda "${projectDir}/envs/vsearch.yml"

  publishDir "${params.output_path}/dechimered_denovo", mode: 'copy', overwrite: true

  input:
    path fasta
    val approach
    val out_name
    val threads

  output:
    tuple path("${out_name}.fa"), path('status.txt')

  script:
  """
  set -euo pipefail

  RAW_OUT="raw.fa"
  FINAL_OUT="${out_name}.fa"

  vsearch --uchime3_denovo ${fasta} \
          --sizein \
          --sizeout \
          --fasta_width 0 \
          --nonchimeras \${RAW_OUT} \
          --threads ${threads}

  if [[ "${approach}" == "asv" ]]; then
    PREFIX="${approach.toUpperCase()}"

    # Header rename: >anything → >ASV_1, >ASV_2, ...
    awk -v prefix="\${PREFIX}" '/^>/ { n++
                                        print ">" prefix "_" n
                                        next
                                        }
                                        { print }' "\${RAW_OUT}" > "\${FINAL_OUT}"
  else
    cp "\${RAW_OUT}" "\${FINAL_OUT}"
  fi

  if [[ ! -s "\${FINAL_OUT}" ]]; then
    echo "EMPTY" > status.txt
  else
    echo "OK" > status.txt
  fi
  """
}

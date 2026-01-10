process TRIMMER {
  tag { fastq.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/trimmed", mode: 'copy', overwrite: true

  input:
    path fastq
    path primers
    val type

  output:
    path 'trimmed*.fq'

  script:
  """
  set -euo pipefail

  primer_fwd=\$(awk 'NR==2' "${primers}")
  primer_rev=\$(awk 'NR==4' "${primers}")

  rc=\$(python "${params.scripts_path}/reverse_complement.py" "\$primer_rev")
  primer_rev_rc=\$(echo "\$rc" | awk '{print \$2}')

  if [ "${type}" = "F" ]; then
    PRIMER="\${primer_fwd}"
    OUT="trimmed.fwd.fq"
  elif [ "${type}" = "R" ]; then
    PRIMER="\${primer_rev_rc}"
    OUT="trimmed.rev.fq"
  fi

  if [ -z "\${PRIMER}" ]; then
    echo "ERROR: primer is empty for file '${fastq}' (type='${type}')." >&2
    exit 2
  fi

  if [ "${type}" = "F" ]; then
    cutadapt -g "\${PRIMER}" \\
             --discard-untrimmed \\
             -o "\${OUT}" \\
             "${fastq}"
  else
    cutadapt -a "\${PRIMER}" \\
             --discard-untrimmed \\
             -o "\${OUT}" \\
             "${fastq}"
  fi
  """
}

process MERGE {
  tag { "samples" }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/merged", mode: 'copy', overwrite: false

  input:
    tuple val(sample), path(r1), path(r2)
    val min_ovlen
    val threads

  output:
    path "${sample}.merged.fq"

  script:
  """
  set -euo pipefail

  R1="\$(realpath ${r1})"
  R2="\$(realpath ${r2} 2>/dev/null || echo '')"
  OUT="${sample}.merged.fq"

  echo "Merging sample ${sample}:"
  echo "  R1=\$R1"
  echo "  R2=\$R2"
  echo "  min_ovlen=${min_ovlen}"
  echo "  threads=${threads}"

  if [ -z "\$R2" ] || [ ! -s "\$R2" ]; then
    echo "WARNING: Mate R2 for sample ${sample} not found or empty. Skipping merge for this sample." >&2
    exit 0
  fi

  vsearch --fastq_mergepairs "\$R1" \
          --reverse "\$R2" \
          --fastq_minovlen ${min_ovlen} \
          --threads ${threads} \
          --fastqout "\$OUT" \
          --relabel ${sample}. \
          --fastq_eeout
  """
}

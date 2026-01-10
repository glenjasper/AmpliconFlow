process CHECK_PRIMERS {
  tag { fastq.getName() }
  cpus 1
  time '2h'

  publishDir "${params.output_path}/check_primers", mode: 'copy', overwrite: true

  input:
    path fastq
    path primers
    val threads

  output:
    path 'primers.stats.txt'

  script:
  """
  set -euo pipefail

  id_fwd=\$(awk 'NR==1 {print substr(\$0,2)}' "${primers}")
  primer_fwd=\$(awk 'NR==2' "${primers}")

  id_rev=\$(awk 'NR==3 {print substr(\$0,2)}' "${primers}")
  primer_rev=\$(awk 'NR==4' "${primers}")

  echo "[INFO] Primer forward: ID=\$id_fwd  SEQ=\$primer_fwd"
  echo "[INFO] Primer reverse: ID=\$id_rev  SEQ=\$primer_rev"

  arr_ids=("\$id_fwd" "\$id_rev")
  arr_seqs=("\$primer_fwd" "\$primer_rev")

  echo -e "primer_id\tprimer_seq\tstrand\tmatches\tpercent_reads\ttotal_reads" > primers.stats.txt

  for idx in "\${!arr_ids[@]}"; do
      pid="\${arr_ids[\$idx]}"
      pseq="\${arr_seqs[\$idx]}"

      echo "[INFO] Testing primer \$pid: \$pseq"

      # (+) Forward
      cutadapt -j ${threads} \
               -b "\$pseq" \
               -o /dev/null "${fastq}" \
               > "\${pid}.fwd.log" 2>&1

      matches_fwd=\$(grep -E "Reads with adapters" "\${pid}.fwd.log" | sed -E 's/.*: *([0-9]+).*/\\1/')
      percent_fwd=\$(grep -E "Reads with adapters" "\${pid}.fwd.log" | sed -E 's/.*\\((.*)%\\).*/\\1/')
      total_fwd=\$(grep -E "Total reads" "\${pid}.fwd.log" | sed -E 's/.*: *([0-9]+).*/\\1/')

      matches_fwd=\${matches_fwd:-0}
      percent_fwd=\${percent_fwd:-0.00}
      total_fwd=\${total_fwd:-0}

      echo -e "\$pid\t\$pseq\t+\t\$matches_fwd\t\$percent_fwd\t\$total_fwd" >> primers.stats.txt

      # (-) Reverse complement
      rc=\$(python3 "${params.scripts_path}/reverse_complement.py" "\$pseq")
      pseq_rc=\$(echo "\$rc" | awk '{print \$2}')

      cutadapt -j ${threads} \
               -b "\$pseq_rc" \
               -o /dev/null "${fastq}" \
               > "\${pid}.rev.log" 2>&1

      matches_rev=\$(grep -E "Reads with adapters" "\${pid}.rev.log" | sed -E 's/.*: *([0-9]+).*/\\1/')
      percent_rev=\$(grep -E "Reads with adapters" "\${pid}.rev.log" | sed -E 's/.*\\((.*)%\\).*/\\1/')
      total_rev=\$(grep -E "Total reads" "\${pid}.rev.log" | sed -E 's/.*: *([0-9]+).*/\\1/')

      matches_rev=\${matches_rev:-0}
      percent_rev=\${percent_rev:-0.00}
      total_rev=\${total_rev:-0}

      echo -e "\$pid\t\$pseq_rc\t-\t\$matches_rev\t\$percent_rev\t\$total_rev" >> primers.stats.txt
  done
  """
}

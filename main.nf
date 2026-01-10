#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { FASTQC as FASTQC_RAW } from './modules/qc.nf'
include { FASTQC as FASTQC_MERGED } from './modules/qc.nf'
include { FASTQC as FASTQC_JOINED } from './modules/qc.nf'
include { FASTQC as FASTQC_TRIMMED } from './modules/qc.nf'
include { FASTQC as FASTQC_FILTERED } from './modules/qc.nf'
include { MERGE } from './modules/merge.nf'
include { JOIN } from './modules/join.nf'
include { SUBSAMPLE } from './modules/subsample.nf'
include { CHECK_PRIMERS } from './modules/checkprimers.nf'
include { TRIMMER as TRIMMER_FORWARD } from './modules/trimmer.nf'
include { TRIMMER as TRIMMER_REVERSE } from './modules/trimmer.nf'
include { FILTER } from './modules/filter.nf'
include { DEREPLICATE } from './modules/dereplicate.nf'
include { DENOISE } from './modules/denoise.nf'
include { DECHIMERA_DENOVO } from './modules/dechimeradn.nf'
include { COUNT } from './modules/count.nf'
include { RENAME_HEAD } from './modules/renamehead.nf'
include { TAXONOMY_ASV } from './modules/taxonomyasv.nf'
include { ABUNDANCE_ASV } from './modules/abundanceasv.nf'

include { PRECLUSTER } from './modules/precluster.nf'
include { DECHIMERA_REF } from './modules/dechimeraref.nf'
include { NONCHIMERA_DEREP } from './modules/nonchimeraderep.nf'
include { NONCHIMERA_READS } from './modules/nonchimerareads.nf'
include { CLUSTER_OTU } from './modules/clusterotu.nf'
include { MAKE_DB } from './modules/makedb.nf'
include { TAXONOMY_OTU } from './modules/taxonomyotu.nf'
include { ABUNDANCE_OTU } from './modules/abundanceotu.nf'

class PipelineState { static stopped = false }

def pprint(String text, String colorName = null) {
  def colorMap = [
    'reset': "\u001B[0m",

    'black': "\u001B[30m",
    'red': "\u001B[31m",
    'green': "\u001B[32m",
    'yellow': "\u001B[33m",
    'blue': "\u001B[34m",
    'magenta': "\u001B[35m",
    'cyan': "\u001B[36m",
    'white': "\u001B[37m",

    'bright_black': "\u001B[90m",
    'bright_red': "\u001B[91m",
    'bright_green': "\u001B[92m",
    'bright_yellow': "\u001B[93m",
    'bright_blue': "\u001B[94m",
    'bright_magenta': "\u001B[95m",
    'bright_cyan': "\u001B[96m",
    'bright_white': "\u001B[97m",

    'soft_white': "\u001B[38;5;250m",
    'soft_cyan': "\u001B[38;5;81m",
    'soft_blue': "\u001B[38;5;75m",
    'soft_green': "\u001B[38;5;114m",
    'soft_yellow': "\u001B[38;5;221m",

    'bold': "\u001B[1m",
    'dim': "\u001B[2m",
    'italic': "\u001B[3m",
    'underline': "\u001B[4m"
  ]

  if (colorName) {
    def code = colorMap[colorName.toLowerCase()]
    if (code) println code + text + colorMap.reset
    else println text
  } else {
    println text
  }
}

def checkTools() {
  final List REQUIRED_TOOLS = ['python3', 'vsearch', 'cutadapt', 'blastn', 'makeblastdb']
  final List OPTIONAL_TOOLS = ['fastqc']

  def missingRequired = []
  def missingOptional = []

  REQUIRED_TOOLS.each { t ->
    def p = ["bash","-lc","command -v ${t} >/dev/null 2>&1"].execute()
    p.waitFor()
    if (p.exitValue() != 0) missingRequired << t
  }

  OPTIONAL_TOOLS.each { t ->
    def p = ["bash","-lc","command -v ${t} >/dev/null 2>&1"].execute()
    p.waitFor()
    if (p.exitValue() != 0) missingOptional << t
  }

  if (missingRequired) {
    throw new IllegalStateException(
      "Required tools missing: ${missingRequired.join(', ')}\n" +
      "Please install them before running the pipeline."
    )
  }

  if (missingOptional) {
    pprint("WARNING: Optional tools not found: ${missingOptional.join(', ')}\n", "yellow")
  }

  pprint("Tools check: OK\n", "green")
}

def maybeCheckTools() {
  if (!workflow.containerEngine) {
    pprint("Running in LOCAL mode – checking required tools", "soft_green")
    checkTools()
  } else {
    pprint("Container engine detected (${workflow.containerEngine})\n", "soft_yellow")
  }
}

def getValidFastqFiles() {
  def samplesDir = file(params.samples_path)

  def validFiles = samplesDir.listFiles()?.findAll { f ->
    def name = f.name.toLowerCase()
    name.endsWith('.fastq') || 
    name.endsWith('.fq') || 
    name.endsWith('.fastq.gz') || 
    name.endsWith('.fq.gz')
  } ?: []

  if (validFiles.empty) {
    def msg = "No FASTQ files found\n"
    msg += "   Expected: .fastq .fq .fastq.gz .fq.gz\n"
    msg += "   Path: ${params.samples_path}"

    def compressed = samplesDir.listFiles()?.findAll { f ->
      def name = f.name.toLowerCase()
      name.endsWith('.tar.gz') || name.endsWith('.tgz') || name.endsWith('.zip')
    }

    if (compressed) {
      msg += "\n\n   Found ${compressed.size()} archive file(s):"
      compressed.take(3).each { f -> msg += "\n   - ${f.name}" }
      if (compressed.size() > 3) msg += "\n   ... and ${compressed.size() - 3} more"
      msg += "\n\n   Extract first: tar -xzf *.tar.gz  OR  unzip *.zip"
    }

    throw new IllegalStateException(msg)
  }

  pprint("Found ${validFiles.size()} FASTQ file(s)\n", "green")
  return validFiles
}

def checkStep(stepName, ch) {
  def validated = ch.map { t ->
    def elems = t as List
    def statusFile = elems[-1]
    def status = statusFile.text.trim()

    if (status == "EMPTY") {
      pprint("\n[WARN] No sequences after ${stepName}. Stopping pipeline.", "yellow")
      PipelineState.stopped = true
      return null
    }

    return t
  }

  return validated.filter { it != null }
}

def normalizeRead(id) {
  id = id.toLowerCase()

  if (id in ["1", "r1", "f", "fwd", "forward"]) return "R1"
  if (id in ["2", "r2", "r", "rev", "reverse"]) return "R2"

  return null
}

def validateFloatParam(String name,
                       def value,
                       BigDecimal defaultValue,
                       BigDecimal min = null,
                       BigDecimal max = null) {
  if (value == null)
    value = defaultValue

  try {
    value = value as BigDecimal
  }
  catch (Exception e) {
    throw new IllegalStateException("Parameter '${name}' must be a number, got '${value}'")
  }

  if (min != null && value < min)
    throw new IllegalStateException("Parameter '${name}' must be >= ${min}, got ${value}")

  if (max != null && value > max)
    throw new IllegalStateException("Parameter '${name}' must be <= ${max}, got ${value}")

  return value
}

def validateIntParam(String name,
                     def value,
                     Integer defaultValue,
                     Integer min = null,
                     Integer max = null) {
  if (value == null)
    value = defaultValue

  try {
    value = value as Integer
  }
  catch (Exception e) {
    throw new IllegalStateException("Parameter '${name}' must be an integer, got '${value}'")
  }

  if (min != null && value < min)
    throw new IllegalStateException("Parameter '${name}' must be >= ${min}, got ${value}")

  if (max != null && value > max)
    throw new IllegalStateException("Parameter '${name}' must be <= ${max}, got ${value}")

  return value
}

maybeCheckTools()

// Optional maxlen: empty value disables --maxlen in FILTER
ch_maxlen = Channel.value( params.maxlen ?: '' )

params.quality_check = (params.quality_check == null) ? false : params.quality_check
params.cut_primers = (params.cut_primers == null) ? false : params.cut_primers

def LABELS = ['approach': ['asv': 'ASV (Amplicon Sequence Variants)',
                           'otu': 'OTU (Operational Taxonomic Units)'],
              'database': ['SILVA': 'SILVA rRNA database',
                           'UNITE': 'UNITE ITS database']]

def approach = null
def allowedApproaches = LABELS.approach.keySet() as List
if (!params.approach) {
  throw new IllegalStateException("params.approach is required (allowed values: ${allowedApproaches.join(', ')})")
} else {
  approach = params.approach.toString().trim().toLowerCase()
  if (!(approach in allowedApproaches))
    throw new IllegalStateException("Invalid params.approach='${params.approach}'. Allowed values: ${allowedApproaches.join(', ')}")
}

if (!params.samples_path) {
  throw new IllegalStateException("params.samples_path is required but not set")
} else {
  def samplesDir = file(params.samples_path)
  if (!samplesDir.exists())
    throw new IllegalStateException("samples_path '${params.samples_path}' does not exist")
  if (!samplesDir.isDirectory())
    throw new IllegalStateException("samples_path '${params.samples_path}' is not a directory")
}

if (!params.database_fasta) {
  throw new IllegalStateException("params.database_fasta is required but not set")
} else {
  def dbFile = file(params.database_fasta)
  if (!dbFile.exists())
    throw new IllegalStateException("database file '${params.database_fasta}' does not exist")
  if (!dbFile.isFile())
    throw new IllegalStateException("database_fasta '${params.database_fasta}' is not a file")
}

def database_type = null
def allowedDBs = LABELS.database.keySet() as List
if (!params.database_type) {
  throw new IllegalStateException("params.database_type is required (allowed values: ${allowedDBs.join(', ')})")
} else {
  database_type = params.database_type.toString().trim().toUpperCase()
  if (!(database_type in allowedDBs))
    throw new IllegalStateException("Invalid params.database_type='${params.database_type}'. Allowed values: ${allowedDBs.join(', ')}")
}

if (params.cut_primers) {
  if (!params.primers_fasta)
    throw new IllegalStateException("params.primers_fasta is required when params.cut_primers = true")
  def primersFile = file(params.primers_fasta)
  if (!primersFile.exists())
    throw new IllegalStateException("primers file '${params.primers_fasta}' does not exist")
  if (!primersFile.isFile())
    throw new IllegalStateException("primers path '${params.primers_fasta}' is not a file")
}

params.threads = validateIntParam('threads', params.threads, 4, 1, null)

params.min_ovlen = validateIntParam('min_ovlen', params.min_ovlen, 20, 1, null)
params.subset_size = validateIntParam('subset_size', params.subset_size, 1000, 1, null)

params.maxee = validateFloatParam('maxee', params.maxee, 0.8, 0, null)
params.minlen = validateIntParam('minlen', params.minlen, 350, 1, null)

if (approach == 'asv') {
  params.high_identity = validateFloatParam('high_identity', params.high_identity, 0.99, 0, 1)
  params.cutoff = validateFloatParam('cutoff', params.cutoff, 0.8, 0, 1)
}

if (approach == 'otu') {
  params.cluster_identity = validateFloatParam('cluster_identity', params.cluster_identity, 0.97, 0, 1)
  params.blast_identity = validateFloatParam('blast_identity', params.blast_identity, 0.97, 0, 1)
}

pprint("Pipeline starting with configuration:", "soft_white")
pprint(" • approach: ${LABELS.approach[approach]}", "soft_white")
pprint(" • samples_path: ${params.samples_path}", "soft_white")
pprint(" • output_path: ${params.output_path}", "soft_white")
if (params.cut_primers) {
  pprint(" • primers: ${params.primers_fasta}", "soft_white")
}
pprint(" • database (type): ${LABELS.database[database_type]}", "soft_white")
pprint(" • database (sequences): ${params.database_fasta}", "soft_white")
pprint(" • threads: ${params.threads}\n", "soft_white")

workflow {
  main:
  {
    def validFiles = getValidFastqFiles()
    
    if (params.quality_check) {
      def validPaths = validFiles.collect { it.toString() }
      raw_reads = Channel.from(validPaths)
      qc_raw_reports = FASTQC_RAW(raw_reads)
    }

    pairs = Channel
      .from(validFiles)
      .map { f ->
        def name = f.name
        def m = name =~ /(.+?)(?:[_\.\-]?)(?:R?)([12]|[Ff](?:wd|orward)?|[Rr](?:ev|everse)?)(?:[_\.\-]?)\.(?:f(ast)?q|fq)(?:\.gz)?$/

        if (!m.matches())
          throw new IllegalStateException("Cannot identify R1/R2 in filename: ${name}")

        def prefix = m[0][1]
        def rawId  = m[0][2]
        def idNormalized = normalizeRead(rawId)

        if (!idNormalized)
          throw new IllegalStateException("Unrecognized read ID '${rawId}' in file: ${name}")

        tuple(prefix, tuple(idNormalized, f))
      }
      .groupTuple()
      .map { prefix, tuples ->
        def r1 = tuples.find { it[0] == "R1" }?.getAt(1)
        def r2 = tuples.find { it[0] == "R2" }?.getAt(1)

        if (!r1 || !r2)
          throw new IllegalStateException("Missing R1 or R2 for sample '${prefix}'")

        tuple(prefix, r1, r2)
      }

    // pairs.view { s, r1, r2 -> "Pair: ${r1.name}  |  ${r2.name}" }

    merged_files = MERGE(pairs, params.min_ovlen, params.threads)

    if (params.quality_check) {
      qc_merged_reports = FASTQC_MERGED(merged_files)
    }

    // merged_list = merged_files.collect()

    merged_list = merged_files
      .collect()
      .ifEmpty {
        throw new IllegalStateException("MERGE produced no output files")
      }

    joined_files = JOIN(merged_list)
    joined_fq = joined_files.map { fq, stats -> fq }

    if (params.quality_check) {
      qc_joined_reports = FASTQC_JOINED(joined_fq)
    }

    if (params.cut_primers) {
      subsample_file = SUBSAMPLE(joined_fq, params.subset_size, params.threads)

      primers_file = Channel.fromPath(params.primers_fasta, checkIfExists: true)
      checkprimer_file = CHECK_PRIMERS(subsample_file, primers_file, params.threads)

      trimmed_f_file = TRIMMER_FORWARD(joined_fq, primers_file, 'F')

      trimmed_r_file = TRIMMER_REVERSE(trimmed_f_file, primers_file, 'R')

      if (params.quality_check) {
        qc_trimmed_reports = FASTQC_TRIMMED(trimmed_r_file)
      }

      file_fq = trimmed_r_file
    } else {
      file_fq = joined_fq
    }

    filtered_files = FILTER(file_fq, params.maxee, params.minlen, ch_maxlen, params.threads)
    filtered_fq = filtered_files.map { fq, fa -> fq }
    filtered_fa = filtered_files.map { fq, fa -> fa }

    if (params.quality_check) {
      qc_filtered_reports = FASTQC_FILTERED(filtered_fq)
    }

    dereplicated_files = DEREPLICATE(filtered_fa, approach)
    dereplicated_fa = dereplicated_files.map { fa, uc -> fa }
    dereplicated_uc = dereplicated_files.map { fa, uc -> uc }

    if (approach == 'asv') {
      denoised_tuple = DENOISE(dereplicated_fa, params.threads)
      denoised_files = checkStep("DENOISE", denoised_tuple)
      denoised_fa = denoised_files.map { fa, status -> fa }

      dechimered_tuple = DECHIMERA_DENOVO(denoised_fa, approach, approach, params.threads)
      dechimered_files = checkStep("DECHIMERA_DENOVO", dechimered_tuple)
      dechimered_fa = dechimered_files.map { fa, status -> fa }

      counted_tuple = COUNT(dechimered_fa, filtered_fa, params.high_identity, params.threads)
      counted_files = checkStep("COUNT", counted_tuple)
      counted_file = counted_files.map { tab, status -> tab }

      database_tuple = RENAME_HEAD(params.database_fasta, database_type.toLowerCase())
      database_files = checkStep("RENAME_HEAD", database_tuple)
      database_fa = database_files.map { fa, status -> fa }

      taxonomy_tuple = TAXONOMY_ASV(dechimered_fa, database_fa, params.cutoff, params.threads)
      taxonomy_files = checkStep("TAXONOMY_ASV", taxonomy_tuple)
      taxonomy_file = taxonomy_files.map { tab, status -> tab }

      abundance_file = ABUNDANCE_ASV(counted_file, taxonomy_file)
    } else {
      preclustered_tuple = PRECLUSTER(dereplicated_fa, params.cluster_identity, params.threads)
      preclustered_files = checkStep("PRECLUSTER", preclustered_tuple)
      preclustered_fa = preclustered_files.map { fa, uc, status -> fa }
      preclustered_uc = preclustered_files.map { fa, uc, status -> uc }

      dechimered_dn_tuple = DECHIMERA_DENOVO(preclustered_fa, approach, 'denovo.nonchimeras', params.threads)
      dechimered_dn_files = checkStep("DECHIMERA_DENOVO", dechimered_dn_tuple)
      dechimered_dn_fa = dechimered_dn_files.map { fa, status -> fa }

      dechimered_ref_tuple = DECHIMERA_REF(dechimered_dn_fa, params.database_fasta, params.threads)
      dechimered_ref_files = checkStep("DECHIMERA_REF", dechimered_ref_tuple)
      dechimered_ref_fa = dechimered_ref_files.map { fa, status -> fa }

      nonchimera_derep_tuple = NONCHIMERA_DEREP(dereplicated_fa, preclustered_uc, dechimered_ref_fa)
      nonchimera_derep_files = checkStep("NONCHIMERA_DEREP", nonchimera_derep_tuple)
      nonchimera_derep_fa = nonchimera_derep_files.map { fa, status -> fa }

      nonchimera_reads_tuple = NONCHIMERA_READS(filtered_fa, dereplicated_uc, nonchimera_derep_fa)
      nonchimera_reads_files = checkStep("NONCHIMERA_READS", nonchimera_reads_tuple)
      nonchimera_reads_fa = nonchimera_reads_files.map { fa, status -> fa }

      clustered_tuple = CLUSTER_OTU(nonchimera_reads_fa, params.cluster_identity, params.threads)
      clustered_files = checkStep("CLUSTER_OTU", clustered_tuple)
      clustered_fa = clustered_files.map { fa, uc, tab, biom, status -> fa }
      clustered_tab = clustered_files.map { fa, uc, tab, biom, status -> tab }

      database_tuple = MAKE_DB(params.database_fasta, database_type.toLowerCase())
      database_files = checkStep("MAKE_DB", database_tuple)
      database_prefix = database_files.map { prefix, bins, status -> prefix }
      database_bins = database_files.map { prefix, bins, status -> bins }

      taxonomy_tuple = TAXONOMY_OTU(clustered_fa, params.blast_identity, database_prefix, database_bins, params.threads)
      taxonomy_files = checkStep("TAXONOMY_OTU", taxonomy_tuple)
      taxonomy_file = taxonomy_files.map { tab, status -> tab }

      abundance_file = ABUNDANCE_OTU(taxonomy_file, clustered_tab, database_type.toLowerCase())
    }
  }
}

workflow.onComplete {
  def stoppedEarly = PipelineState.stopped

  if (stoppedEarly) {
    pprint("Pipeline stopped due to biological emptiness, not an error.", "yellow")
  } else {
    if (workflow.success) {
      pprint("\nPipeline completed successfully!", "green")

      def dir = new File("${params.output_path}/abundance_${approach}")
      if (dir.exists()) {
        def files = dir.listFiles()?.findAll { it.isFile() }
        if (files) {
          pprint("Output files:", "soft_white")
          files.each { file ->
            pprint(" • ${params.output_path}/abundance_${approach}/${file.getName()}", "soft_white")
          }
        }
      }
    }
    else {
      pprint("\nPipeline failed due to an error. Check logs.", "red")
    }
  }
}

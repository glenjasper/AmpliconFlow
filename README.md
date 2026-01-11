# AmpliconFlow

**AmpliconFlow** é um pipeline reprodutível e escalável, desenvolvido em **Nextflow DSL2**, para análise de dados de sequenciamento de amplicons (por exemplo, 16S rRNA e ITS), suportando abordagens **ASV (Amplicon Sequence Variants)** e **OTU (Operational Taxonomic Units)**.

O pipeline foi projetado para rodar de forma **consistente e transparente** em diferentes ambientes computacionais, incluindo:

- execução local (PATH do sistema),
- execução com **Conda** (modo fallback, sem containers),
- ambientes com **Docker**,
- ambientes **HPC** com **Singularity/Apptainer**.

## 📌 Principais características

- Implementado em **Nextflow DSL2**
- Suporte a **ASV** e **OTU** em um único workflow
- Múltiplos modos de execução (**local / conda / Docker / Singularity**)
- Detecção automática do ambiente de execução
- Verificação de dependências apenas quando necessário
- Arquitetura modular e extensível
- Resultados reprodutíveis e auditáveis

## 🧬 Abordagens suportadas

### 🔹 ASV (Amplicon Sequence Variants)

Fluxo geral:
1. Merge de reads pareados  
2. Controle de qualidade (FastQC – opcional)  
3. Remoção de primers (opcional)  
4. Filtragem por qualidade e comprimento  
5. Dereplicação  
6. Denoising  
7. Remoção de quimeras (de novo)  
8. Contagem de variantes  
9. Classificação taxonômica  
10. Tabela final de abundância  

### 🔹 OTU (Operational Taxonomic Units)

Fluxo geral:
1. Merge de reads pareados  
2. Controle de qualidade (FastQC – opcional)  
3. Remoção de primers (opcional)  
4. Filtragem por qualidade e comprimento  
5. Dereplicação  
6. Pré-clusterização  
7. Remoção de quimeras (de novo + referência)  
8. Clusterização em OTUs  
9. Classificação taxonômica  
10. Tabela final de abundância  

## ⚙️ Parâmetros de configuração

O comportamento do **AmpliconFlow** é controlado por um arquivo de parâmetros `.yml`, passado via `-params-file`.

A tabela abaixo descreve todos os parâmetros suportados, seus valores padrão e o significado biológico ou computacional de cada opção.

### Parâmetros gerais do pipeline

| Parâmetro | Tipo | Obrigatório | Valor padrão | Descrição |
|----------|------|-------------|--------------|-----------|
| approach | string | sim | — | Define a abordagem analítica do pipeline. `asv` executa a inferência de **Amplicon Sequence Variants**. `otu` executa a **clusterização em Operational Taxonomic Units**. |
| samples_path | path | sim | — | Diretório contendo os arquivos FASTQ pareados (R1 / R2) de entrada. |
| output_path | path | sim | results | Diretório onde todos os resultados do pipeline serão escritos. |
| threads | integer | sim | 10 | Número máximo de threads utilizadas pelos processos paralelizáveis. |
| quality_check | boolean | condicional | false | Se `true`, gera relatórios FastQC em múltiplas etapas do pipeline. |

### Banco de dados de referência

| Parâmetro | Tipo | Obrigatório | Valor padrão | Descrição |
|----------|------|-------------|--------------|-----------|
| database_type | string | sim | — | Tipo do banco de dados taxonômico. `silva` indica banco de rRNA (ex.: 16S/18S). `unite` indica banco específico para ITS (fungos). |
| database_fasta | path | sim | — | Arquivo FASTA contendo o banco de dados de referência correspondente ao `database_type`. |

### Merge de reads pareados

| Parâmetro | Tipo | Obrigatório | Valor padrão | Descrição |
|----------|------|-------------|--------------|-----------|
| min_ovlen | integer | sim | 20 | Comprimento mínimo de sobreposição exigido para o merge de reads R1/R2. |

### Remoção de primers

| Parâmetro | Tipo | Obrigatório | Valor padrão | Descrição |
|----------|------|-------------|--------------|-----------|
| cut_primers | boolean | não | false | Ativa ou desativa a remoção de primers a partir das sequências merged. |
| primers_fasta | path | condicional | — | Arquivo FASTA contendo os primers forward e reverse. Obrigatório quando `cut_primers = true`. |

### Subamostragem (checagem de primers)

| Parâmetro | Tipo | Obrigatório | Valor padrão | Descrição |
|----------|------|-------------|--------------|-----------|
| subset_size | integer | não | 1000 | Número de reads subamostrados para avaliar a presença e orientação dos primers. |

### Filtragem de reads

| Parâmetro | Tipo | Obrigatório | Valor padrão | Descrição |
|----------|------|-------------|--------------|-----------|
| maxee | float | sim | 0.8 | Número máximo de erros esperados (expected errors) permitido por read. |
| minlen | integer | sim | 350 | Comprimento mínimo do read após filtragem por qualidade. |
| maxlen | integer | sim | vazio | Comprimento máximo do read. Se vazio ou não definido, o filtro de comprimento máximo é desativado. |

### Parâmetros específicos para ASV

| Parâmetro | Tipo | Obrigatório | Valor padrão | Descrição |
|----------|------|-------------|--------------|-----------|
| high_identity | float | sim | 0.99 | Identidade mínima utilizada para mapear reads filtrados de volta às ASVs inferidas. |
| cutoff | float | sim | 0.8 | Cutoff de confiança para classificação taxonômica via método SINTAX. |

### Parâmetros específicos para OTU

| Parâmetro | Tipo | Obrigatório | Valor padrão | Descrição |
|----------|------|-------------|--------------|-----------|
| cluster_identity | float | sim | 0.97 | Identidade mínima utilizada para a clusterização de reads em OTUs. |
| blast_identity | float | sim | 0.97 | Identidade mínima exigida para atribuição taxonômica via BLAST. |

## 📄 Exemplo de arquivo de configuração (para `ASV`)

Abaixo está um exemplo completo de arquivo de configuração para execução do AmpliconFlow no modo `ASV` (Amplicon Sequence Variants).

```bash
# ---------------------------------
# AmpliconFlow configuration file
# ---------------------------------

# Pipeline mode (asv or otu)
approach: asv

# Input / Output
samples_path: /your_path/data
output_path: /your_path/output

# Reference database (silva or unite)
database_type: silva
database_fasta: /your_path/db/SILVA_138.2_SSURef_NR99_tax_silva.fasta

# Resources
threads: 20

# Quality control (true: enable FastQC reports)
quality_check: true

# Read merging
min_ovlen: 20           # minimum overlap length

# Primer handling
cut_primers: true
primers_fasta: /your_path/illumina.primers.16s.fa

# Subsampling (primer check)
subset_size: 1000

# Read filtering
maxee: 0.8              # maximum expected errors
minlen: 350             # minimum read length
maxlen: 500             # maximum read length (optional: empty disables)

# ASV-specific parameters (used only when approach: asv)
high_identity: 0.99     # identity for ASV counting
cutoff: 0.8             # taxonomy confidence cutoff

# OTU-specific parameters (used only when approach: otu)
cluster_identity:       # identity threshold for OTU clustering
blast_identity:         # minimum identity for BLAST taxonomic assignment
```

## ⚙️ Modos de execução e ambientes

O **executor** utilizado é sempre `local` (os processos são executados no nó atual).  
O que muda entre os modos é **como as dependências são providas**.

| Profile       | Ambiente de execução        | Uso recomendado            |
|---------------|-----------------------------|----------------------------|
| `standard`    | PATH do sistema             | Uso local pessoal          |
| `conda`       | Conda environments isolados | HPC sem containers         |
| `docker`      | Docker container            | Workstations / servidores |
| `singularity` | Singularity / Apptainer     | HPC                        |

## ⚙️ Dependências

### 🔹 Execução local (`-profile standard`)

Quando executado **sem Conda ou containers**, as seguintes ferramentas devem estar disponíveis no `PATH`:

#### Obrigatórias
- `python3`
- `vsearch`
- `cutadapt`
- `blastn`
- `makeblastdb`
- `fastqc`

> No modo `standard`, o pipeline verifica automaticamente a presença dessas ferramentas antes da execução.

### 🔹 Execução com Conda (`-profile conda`)

- As dependências são resolvidas automaticamente via arquivos em `envs/`
- Não requer Docker nem Singularity
- Ideal para ambientes HPC restritivos

> No modo `conda`, **não é feita verificação do PATH do sistema**, pois todas as ferramentas são fornecidas pelos environments Conda.

## 🐳 Containers

### Docker

- A imagem contém todas as dependências do pipeline:
  - VSEARCH
  - Cutadapt
  - BLAST+
  - FastQC
  - Python + bibliotecas científicas
- Requer acesso ao Docker daemon (usuário no grupo `docker`)

### Singularity / Apptainer

- A imagem é derivada automaticamente da imagem Docker
- Compatível com ambientes HPC
- Não requer privilégios de root
- `autoMounts = true` habilitado no profile

## ⚠️ Requisitos do sistema

### Docker
- Docker instalado
- Usuário no grupo `docker`
- Não é necessário `sudo`

### Singularity / Apptainer
- Apptainer ≥ 1.1
- Instalado sem `setuid`
- User namespaces habilitados

## 🚀 Modos de execução

### ASV – Local (PATH do sistema)
```bash
nextflow run AmpliconFlow -profile standard -params-file config_asv.yml
```
### OTU – Local (PATH do sistema)
```bash
nextflow run AmpliconFlow -profile standard -params-file config_otu.yml
```
### ASV – Conda (sem containers)
```bash
nextflow run AmpliconFlow -profile conda -params-file config_asv.yml
```
### OTU – Conda (sem containers)
```bash
nextflow run AmpliconFlow -profile conda -params-file config_otu.yml
```
### ASV + Docker
```bash
nextflow run AmpliconFlow -profile docker -params-file config_asv.yml
```
### OTU + Docker
```bash
nextflow run AmpliconFlow -profile docker -params-file config_otu.yml
```
### ASV + Singularity (HPC)
```bash
nextflow run AmpliconFlow -profile singularity -params-file config_asv.yml
```
### OTU + Singularity (HPC)
```bash
nextflow run AmpliconFlow -profile singularity -params-file config_otu.yml
```

## 🧪 Dados de teste

O pipeline foi validado utilizando:

- FASTQ pareados (R1 / R2)

### Extensões suportadas

- `.fastq`
- `.fq`
- `.fastq.gz`
- `.fq.gz`

## 📤 Saídas do pipeline

As saídas finais são organizadas por abordagem.

### 🔹 ASV

```text
output_path/
└── abundance/
    └── *.csv
```

### 🔹 OTU

```text
output_path/
└── abundance/
    └── *.csv
```

## 👤 Autor

**Glen Jasper**  
GitHub: <https://github.com/glenjasper>

## 📄 Licença

Este projeto é distribuído sob a licença **MIT**.









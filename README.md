[![Nextflow](https://img.shields.io/badge/Nextflow-%3E%3D22.10.0-brightgreen)](https://www.nextflow.io/)
[![Docker](https://img.shields.io/badge/Docker-Enabled-blue)](https://docker.com)
[![Singularity](https://img.shields.io/badge/Singularity-Enabled-blue)](https://sylabs.io/singularity/)
[![Conda](https://img.shields.io/badge/Conda-Enabled-green)](https://conda.io)
[![GitHub license](https://img.shields.io/github/license/glenjasper/AmpliconFlow)](https://github.com/glenjasper/AmpliconFlow/blob/main/LICENSE)
[![Bioinformatics](https://img.shields.io/badge/Bioinformatics-16S%20rRNA%20%7C%20ITS-red)](https://github.com/glenjasper/AmpliconFlow)

<div align="center">
  <img src="assets/ampliconflow_logo.svg" alt="AmpliconFlow Logo" width="1010">
</div>

# AmpliconFlow

**AmpliconFlow** é um pipeline reprodutível e escalável, desenvolvido em **Nextflow DSL2**, para análise de dados de sequenciamento de amplicons (por exemplo, 16S rRNA e ITS), suportando abordagens **ASV (Amplicon Sequence Variants)** e **OTU (Operational Taxonomic Units)**.

O pipeline foi projetado para rodar de forma **consistente** em diferentes ambientes computacionais, incluindo:

- execução local (PATH do sistema)
- execução com **Conda** (modo fallback, sem containers)
- ambientes com **Docker**
- ambientes **HPC** com **Singularity/Apptainer**

## Tabela de conteúdo

- [Principais características](#principais-características)
- [Abordagens suportadas](#abordagens-suportadas)
  - [ASV (Amplicon Sequence Variants)](#asv-amplicon-sequence-variants)
  - [OTU (Operational Taxonomic Units)](#otu-operational-taxonomic-units)
- [Parâmetros de configuração](#parâmetros-de-configuração)
  - [Parâmetros gerais do pipeline](#parâmetros-gerais-do-pipeline)
  - [Banco de dados de referência](#banco-de-dados-de-referência)
  - [Merge de reads pareados](#merge-de-reads-pareados)
  - [Remoção de primers](#remoção-de-primers)
  - [Subamostragem (checagem de primers)](#subamostragem-checagem-de-primers)
  - [Filtragem de reads](#filtragem-de-reads)
  - [Parâmetros específicos para ASV](#parâmetros-específicos-para-asv)
  - [Parâmetros específicos para OTU](#parâmetros-específicos-para-otu)
- [Exemplo de arquivo de configuração (ASV)](#exemplo-de-arquivo-de-configuração-para-asv)
- [Modos de execução](#modos-de-execução)
  - [Modo Docker](#modo-docker-recomendado)
  - [Modo Singularity / Apptainer](#modo-singularity--apptainer)
  - [Modo Conda](#modo-conda)
  - [Modo Local (manual)](#modo-local-manual)
- [Dica importante](#dica-importante)
- [Dados de teste](#dados-de-teste)
- [Saídas do pipeline](#saídas-do-pipeline)
  - [ASV](#asv)
  - [OTU](#otu)
- [Autor](#autor)
- [Licença](#licença)

## Principais características

- Implementado em **Nextflow DSL2**
- Suporte a **ASV** e **OTU** em um único workflow
- Múltiplos modos de execução (**local / conda / Docker / Singularity**)
- Detecção automática do ambiente de execução
- Verificação de dependências apenas quando necessário
- Arquitetura modular e extensível
- Resultados reprodutíveis e auditáveis

## Abordagens suportadas

### ASV (Amplicon Sequence Variants)

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

### OTU (Operational Taxonomic Units)

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

## Parâmetros de configuração

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

## Exemplo de arquivo de configuração (para `ASV`)

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
blast_coverage:         # minimum query coverage per HSP for BLAST assignment
blast_max_target:       # maximum number of target sequences returned by BLAST
blast_evalue:           # e-value cutoff for BLAST hits
```

## Modos de execução

O AmpliconFlow pode ser executado em diferentes ambientes:

| Profile       | Ambiente de execução        | Uso recomendado            |
|---------------|-----------------------------|----------------------------|
| `standard`    | PATH do sistema             | Uso local pessoal          |
| `conda`       | Conda environments          | HPC sem containers         |
| `docker`      | Docker container            | Workstations / servidores |
| `singularity` | Singularity / Apptainer     | HPC                        |

Todos os modos executam o mesmo pipeline e produzem resultados equivalentes.

### Requisito geral

O AmpliconFlow é executado via **Nextflow**, necessário para todos os modos.

Instale o Nextflow antes de usar o pipeline:

```bash
curl -s https://get.nextflow.io | bash
chmod +x nextflow
sudo mv nextflow /usr/local/bin/
```

### Modo Docker (recomendado)

🐳 Executa o pipeline dentro de um container com todas as dependências já instaladas.
Nenhuma ferramenta bioinformática precisa ser instalada manualmente.

#### Requisitos

- Docker instalado
- Usuário no grupo `docker`

#### Instalação

```bash
sudo apt install docker.io
sudo usermod -aG docker user_local
```

> Substitua **user_local** pelo usuário que irá executar o pipeline. Após adicionar o usuário ao grupo docker, é necessário encerrar e iniciar a sessão novamente (ou reconectar via SSH) para que a alteração tenha efeito.

#### Obter o pipeline

```bash
git clone https://github.com/glenjasper/AmpliconFlow.git
```

#### Executar

```bash
nextflow run AmpliconFlow/main.nf -profile docker -params-file config.yml
```

#### Notas

- A imagem é baixada automaticamente do Docker Hub na primeira execução (requer internet)
- Execuções seguintes são mais rápidas, pois a imagem é armazenada localmente
- A imagem é compartilhada entre usuários no sistema (dependendo da configuração do Docker)
- Não é necessário instalar dependências manualmente
- Recomendado para a maioria dos usuários

### Modo Singularity / Apptainer

🧬 Executa o pipeline em ambientes HPC utilizando containers sem necessidade de permissões de root.

#### Requisitos

- Apptainer ≥ 1.1

#### Obter o pipeline

```bash
git clone https://github.com/glenjasper/AmpliconFlow.git
```

#### Executar

```bash
nextflow run AmpliconFlow/main.nf -profile singularity -params-file config.yml
```

#### Notas

- A imagem é baixada automaticamente do Docker Hub na primeira execução (requer internet)
- A imagem é convertida para formato SIF e armazenada no cache do usuário
- Execuções seguintes são mais rápidas, pois a imagem é reutilizada do cache
- Cada usuário mantém seu próprio cache de imagens
- Não é necessário instalar dependências manualmente
- Recomendado para ambientes HPC

### Modo Conda

🧪 Executa o pipeline criando automaticamente ambientes Conda com todas as dependências necessárias.

#### Requisitos

- Conda, Mamba ou Micromamba instalado

#### Instalação (micromamba recomendado)

```bash
curl -Ls https://micro.mamba.pm/install.sh | bash
source ~/.bashrc
```

#### Obter o pipeline

```bash
git clone https://github.com/glenjasper/AmpliconFlow.git
```

#### Executar

```bash
nextflow run AmpliconFlow/main.nf -profile conda -params-file config.yml
```

#### Notas

- Não requer Docker
- Ideal para ambientes HPC
- As dependências são instaladas automaticamente na primeira execução

### Modo Local (manual)

🧰 Execução sem Conda ou containers. Todas as ferramentas devem ser instaladas manualmente.

#### Dependências obrigatórias

- python3
- vsearch
- cutadapt
- blastn
- makeblastdb
- fastqc

#### Obter o pipeline

```bash
git clone https://github.com/glenjasper/AmpliconFlow.git
```

#### Executar

```bash
nextflow run AmpliconFlow/main.nf -profile standard -params-file config.yml
```

#### Notas

- Todas as ferramentas devem estar no PATH
- O pipeline verifica automaticamente a presença das dependências
- Recomendado apenas para usuários avançados

## Dica importante

⚡ Use -resume para continuar execuções anteriores e evitar reprocessamento. Útil após falhas ou ajustes de parâmetros:

```bash
nextflow run AmpliconFlow/main.nf -profile docker -params-file config.yml -resume
```

## Dados de teste

O pipeline foi validado utilizando:

- FASTQ pareados (R1 / R2)

### Extensões suportadas

- `.fastq`
- `.fq`
- `.fastq.gz`
- `.fq.gz`

## Saídas do pipeline

As saídas finais são organizadas por abordagem.

### ASV

```text
output_path/
└── abundance/
    └── *.csv
```

### OTU

```text
output_path/
└── abundance/
    └── *.csv
```

## Autor

**Glen Jasper**  
GitHub: <https://github.com/glenjasper>

## Licença

Este projeto é distribuído sob a licença **MIT**.

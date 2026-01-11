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

## 📂 Estrutura do projeto

```text
AmpliconFlow/
├── main.nf
├── nextflow.config
├── conf/
│   ├── base.config
│   └── profiles.config
├── modules/
│   ├── merge.nf
│   ├── join.nf
│   ├── filter.nf
│   ├── dereplicate.nf
│   ├── denoise.nf
│   ├── taxonomyasv.nf
│   ├── taxonomyotu.nf
│   └── ...
├── scripts/
│   ├── rename_database.py
│   ├── get_abundances_table_asv.py
│   ├── get_abundances_table_otu.py
│   └── ...
├── envs/
│   ├── trimmer.yml
│   ├── vsearch.yml
│   ├── blast.yml
│   ├── python.yml
│   └── ...
├── docker/
│   ├── Dockerfile
│   └── requirements.txt
└── README.md
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




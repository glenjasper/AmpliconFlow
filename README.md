[![Nextflow](https://img.shields.io/badge/Nextflow-%3E%3D22.10.0-brightgreen)](https://www.nextflow.io/)
[![Docker](https://img.shields.io/badge/Docker-Enabled-blue)](https://docker.com)
[![Singularity](https://img.shields.io/badge/Singularity-Enabled-blue)](https://sylabs.io/singularity/)
[![Conda](https://img.shields.io/badge/Conda-Enabled-green)](https://conda.io)
[![Bioinformatics](https://img.shields.io/badge/Bioinformatics-16S%20rRNA%20%7C%20ITS-red)](https://github.com/glenjasper/AmpliconFlow)
[![GitHub license](https://img.shields.io/github/license/glenjasper/AmpliconFlow)](https://github.com/glenjasper/AmpliconFlow/blob/main/LICENSE)

<div align="center">
  <img src="assets/ampliconflow_logo.svg" alt="AmpliconFlow Logo" width="80%">
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
  - [1. Modo Docker (recomendado)](#1-modo-docker-recomendado)
  - [2. Modo Singularity / Apptainer](#2-modo-singularity--apptainer)
  - [3. Modo Conda](#3-modo-conda)
  - [4. Modo Local / Standard (manual)](#4-modo-local--standard-manual)
- [Dica Importante: Retomando Execuções](#dica-importante-retomando-execuções)
- [Dados de teste](#dados-de-teste)
- [Estrutura de saídas](#estrutura-de-saídas)
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
| silva_taxmap | path | condicional | — | Arquivo de mapeamento taxonômico do SILVA (ex.: `*_tax_silva.txt`). Obrigatório apenas quando `database_type = silva`. |
| silva_taxslv | path | condicional | — | Arquivo de sequências taxonômicas do SILVA (ex.: `*_tax_silva.fasta`). Obrigatório apenas quando `database_type = silva`. |

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
| blast_coverage | float | sim | 0.90 | Cobertura mínima de consulta (query coverage) por HSP exigida pelo BLAST. |
| blast_max_target | integer | sim | 20 | Número máximo de sequências-alvo retornadas pelo BLAST. |
| blast_evalue | float | sim | 1e-5 | Cutoff de valor esperado (E-value) para filtragem de hits do BLAST. |

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

# Required only for SILVA database
silva_taxmap: /your_path/db/taxmap_slv_ssu_ref_nr_138.2.txt.gz
silva_taxslv: /your_path/db/tax_slv_ssu_138.2.txt.gz

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

O AmpliconFlow detecta automaticamente o ambiente computacional através do perfil (`-profile`) selecionado. Todos os modos executam exatamente o mesmo fluxo analítico e produzem resultados biológicos equivalentes.

| Profile       | Ambiente de execução        | Uso recomendado            |
|---------------|-----------------------------|----------------------------|
| `docker`      | Docker container            | Workstations / servidores  |
| `singularity` | Singularity / Apptainer     | HPC                        |
| `conda`       | Conda environments          | HPC sem containers         |
| `standard`    | PATH do sistema             | Uso local pessoal          |

### Requisito geral

O AmpliconFlow é gerenciado e executado via **Nextflow**. O único requisito obrigatório instalado diretamente no sistema hospedeiro é o **Java 17 (ou superior)** acompanhado do binário do Nextflow.

#### 1. Instalar o Java 17 e dependências (Ubuntu/Debian)
```bash
sudo apt update && sudo apt install -y openjdk-17-jre-headless curl
```
*(Para sistemas RedHat/CentOS/Fedora, utilize: `sudo dnf install -y java-17-openjdk-headless curl`)*

#### 2. Instalar o Nextflow
Com o Java configurado no sistema, baixe e configure o executável:
```bash
curl -s https://get.nextflow.io | bash
chmod +x nextflow
sudo mv nextflow /usr/local/bin
```

#### 3. Obter o pipeline e testar
Clone o repositório oficial e visualize o menu de ajuda para validar se todas as dependências básicas estão respondendo:
```bash
git clone https://github.com/glenjasper/AmpliconFlow.git

# Help do pipeline
nextflow run AmpliconFlow/main.nf --help
```

### 1. Modo Docker (recomendado)
🐳 Executa todo o pipeline isolado dentro de um container com todas as dependências bioinformáticas pré-instaladas de fábrica. Nenhuma ferramenta precisa ser instalada manualmente.

* **Requisitos:** Docker instalado e seu usuário adicionado ao grupo `docker`.
```bash
# Instalação rápida do Docker (caso necessário)
sudo apt install docker.io
sudo usermod -aG docker user_local
```
> *Substitua **user_local** pelo seu usuário local. Após adicioná-lo ao grupo, encerre a sessão ou reconecte via SSH para que as permissões tenham efeito.*

#### Execução:
```bash
nextflow run AmpliconFlow/main.nf -profile docker -params-file config.yml
```

#### Notas Técnicas:
- **Download automático:** A imagem é baixada diretamente do Docker Hub na primeira execução (requer conexão com a internet).
- **Uso do cache local:** As execuções seguintes são muito mais rápidas, pois a imagem fica armazenada localmente na máquina.
- **Compartilhamento de recursos:** A imagem pode ser compartilhada entre múltiplos usuários no mesmo sistema (dependendo das políticas do seu Docker).
- **Conveniência absoluta:** Não é necessário instalar nenhuma dependência de bioinformática manualmente no hospedeiro.

### 2. Modo Singularity / Apptainer
🧬 Ideal para clusters institucionais e ambientes multiusuário de Computação de Alto Desempenho (HPC), onde restrições rígidas de segurança impedem o uso de permissões de `root`.

* **Requisitos:** Apptainer (≥ 1.1) ou Singularity instalado no cluster.

#### Execução:
```bash
nextflow run AmpliconFlow/main.nf -profile singularity -params-file config.yml
```

#### Notas Técnicas:
- **Conversão dinâmica:** O Nextflow baixa a imagem do Docker Hub na primeira corrida (requer internet) e a converte automaticamente para o formato nativo `.sif`.
- **Isolamento de cache:** O arquivo `.sif` resultante é armazenado na pasta de cache do próprio usuário, tornando as execuções seguintes imediatas.
- **Ambiente multiusuário:** Cada pesquisador mantém e gerencia seu próprio cache de imagens dentro do cluster de forma independente.
- **Conveniência:** Dispensa completamente a instalação manual de ferramentas pelos administradores do cluster.

### 3. Modo Conda
🧪 Cria e gerencia ambientes virtuais isolados dinamicamente para cada processo do pipeline em tempo de execução.

* **Requisitos:** Devido aos requisitos nativos e de performance do Nextflow moderno, o **Micromamba** é o gerenciador padrão obrigatório para este perfil.
```bash
# Instalação do Micromamba
curl -Ls https://micro.mamba.pm/install.sh | bash
sudo cp $HOME/.local/bin/micromamba /usr/local/bin
sudo chmod +x /usr/local/bin/micromamba
```

#### Execução:
```bash
nextflow run AmpliconFlow/main.nf -profile conda -params-file config.yml
```

#### Notas Técnicas:
- **Performance Nativa:** O uso do Micromamba garante que a resolução e o download das dependências bioinformáticas ocorram na velocidade máxima permitida pela rede.
- **Independência de Docker:** Não requer a presença de Docker, Singularity/Apptainer ou privilégios de administrador (`root`) na máquina hospedeira.
- **HPC Fallback:** É o modo ideal para submissão de tarefas e gerenciamento de filas em clusters institucionais (como Slurm ou PBS) que não possuem suporte a virtualização.
- **Isolamento Total:** Os ambientes de cada ferramenta são construídos automaticamente na primeira corrida do pipeline e armazenados com segurança na pasta de cache do usuário.

### 4. Modo Local / Standard (manual)
🧰 Execução nativa utilizando as ferramentas diretamente instaladas no sistema operacional da sua máquina física.

* **Ferramentas obrigatórias no PATH:** `python3`, `vsearch`, `cutadapt`, `blastn`, `makeblastdb` e `fastqc`.

#### Execução:
```bash
nextflow run AmpliconFlow/main.nf -profile standard -params-file config.yml
```

#### Notas Técnicas:
- **Uso estrito do PATH:** Todas as ferramentas citadas precisam estar obrigatoriamente configuradas e acessíveis nas variáveis de ambiente do seu sistema.
- **Validação prévia:** O pipeline conta com uma rotina automatizada que verifica rigorosamente a presença e a integridade de todas as dependências antes de começar a processar os FASTQs.
- **Perfil de usuário:** Altamente recomendado apenas para usuários avançados ou para debuggers do código do workflow.

## Dica Importante: Retomando Execuções

Se o seu pipeline falhar ou se você precisar ajustar um parâmetro no arquivo de configuração, use a flag **`-resume`**. Isso fará com que o Nextflow reaproveite os resultados armazenados em cache das etapas que não sofreram alterações, poupando tempo computacional:

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

## Estrutura de saídas

Ao final da execução com sucesso, os resultados (ASV ou OTU) consolidados estarão organizados no diretório configurado:

```text
results/
└── abundance/
    └── abundances.tsv
```

## Autor

**Glen Jasper**  
GitHub: <https://github.com/glenjasper>

## Licença

Este projeto é distribuído sob a licença **MIT**.

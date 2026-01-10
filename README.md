# AmpliconFlow

**AmpliconFlow** é um pipeline reprodutível e escalável, desenvolvido em **Nextflow DSL2**, para análise de dados de sequenciamento de amplicons (por exemplo, 16S rRNA e ITS), suportando abordagens **ASV (Amplicon Sequence Variants)** e **OTU (Operational Taxonomic Units)**.

O pipeline foi projetado para rodar de forma **idêntica** em:
- execução local,
- ambientes com **Docker**,
- ambientes **HPC** com **Singularity/Apptainer**.

---

## 📌 Principais características

- Implementado em **Nextflow DSL2**
- Suporte a **ASV** e **OTU** em um único workflow
- Execução transparente em **local / Docker / Singularity**
- Verificação automática de dependências no modo local
- Interrupção controlada em caso de “vazio biológico”
- Arquitetura modular e extensível
- Resultados reprodutíveis e auditáveis

---

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

---

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
9. Construção de banco BLAST  
10. Classificação taxonômica  
11. Tabela final de abundância  

---

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
├── docker/
│   └── Dockerfile
└── README.md
```

## ⚙️ Dependências (execução local)

Quando executado **sem containers**, as seguintes ferramentas devem estar disponíveis no `PATH`.

### 🔹 Obrigatórias

- `python3`
- `vsearch`
- `cutadapt`
- `blastn`
- `makeblastdb`

### 🔹 Opcionais

- `fastqc`

> O pipeline verifica automaticamente essas dependências ao iniciar no modo local.

---

## 🐳 Containers

O pipeline possui suporte nativo a containers.

### Docker

- **Imagem**:
- Contém todas as dependências do pipeline, incluindo:
  - VSEARCH
  - Cutadapt
  - BLAST+
  - FastQC
  - Python 3 + Biopython

### Singularity / Apptainer

- A imagem é construída automaticamente a partir do Docker
- Compatível com ambientes HPC
- `autoMounts = true` habilitado no profile

---

## 🚀 Modos de execução

Todos os modos abaixo foram **testados com sucesso**.

### 🔹 Execução local / Docker / Singularity

```bash
nextflow run /home/data/glen/workstation/nf/AmpliconFlow \
  -profile standard \
  -params-file /home/data/glen/workstation/nf/config/config_server_asv.yml \
  --threads 15
```
```bash
nextflow run /home/data/glen/workstation/nf/AmpliconFlow \
  -profile standard \
  -params-file /home/data/glen/workstation/nf/config/config_server_otu.yml
```
```bash
nextflow run /home/data/glen/workstation/nf/AmpliconFlow \
  -profile docker \
  -params-file /home/data/glen/workstation/nf/config/config_server_asv.yml \
  --threads 15
```
```bash
nextflow run /home/data/glen/workstation/nf/AmpliconFlow \
  -profile docker \
  -params-file /home/data/glen/workstation/nf/config/config_server_otu.yml
```
```bash
nextflow run /home/data/glen/workstation/nf/AmpliconFlow \
  -profile singularity \
  -params-file /home/data/glen/workstation/nf/config/config_server_asv.yml \
  --threads 15
```
```bash
nextflow run /home/data/glen/workstation/nf/AmpliconFlow \
  -profile singularity \
  -params-file /home/data/glen/workstation/nf/config/config_server_otu.yml
```

## 🧪 Dados de teste

O pipeline foi validado utilizando:

- FASTQ pareados (R1 / R2)

### Extensões suportadas

- `.fastq`
- `.fq`
- `.fastq.gz`
- `.fq.gz`

Inclui conjuntos pequenos de dados para testes rápidos.

O pipeline valida automaticamente:

- existência dos arquivos
- pareamento correto R1/R2
- formatos suportados

---

## 📤 Saídas do pipeline

As saídas finais são organizadas por abordagem.

### 🔹 ASV

```text
output_path/
└── abundance_asv/
    └── *.tsv
```

### 🔹 OTU

```text
output_path/
└── abundance_otu/
    └── *.tsv
```

Além disso, o pipeline gera:

- FASTA finais (ASVs ou OTUs)
- Tabelas intermediárias
- Bancos BLAST (OTU)
- Relatórios FastQC (quando habilitado)

---

## 👤 Autor

**Glen Jasper**  
GitHub: <https://github.com/glenjasper>

---

## 📄 Licença

Este projeto é distribuído sob a licença **MIT**.



#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import argparse
import pandas as pd
from tqdm import tqdm
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord

'''
python rename_database.py -d silva -i SILVA_138.2_SSURef_NR99_tax_silva.fasta --taxmap taxmap_slv_ssu_ref_nr_138.2.txt.gz --taxslv tax_slv_ssu_138.2.txt.gz
python rename_database.py -d silva -i SILVA_138.2_SSURef_tax_silva.fasta --taxmap taxmap_slv_ssu_ref_138.2.txt.gz --taxslv tax_slv_ssu_138.2.txt.gz
python rename_database.py -d unite -i utax_reference_dataset_19.02.2025.fasta
python rename_database.py -d unite -i UNITE_public_19.02.2025.fasta
python rename_database.py -d unite -i uchime_reference_dataset_untrimmed_16_10_2022.fasta
'''

def format_lineage(lineage, db_type = 'silva'):
    if db_type == 'silva':
        ranks = ['d','k','p','c','o','f','g','s']
    elif db_type == 'unite':
        ranks = ['d','p','c','o','f','g','s']

    parts = []
    for rank, tax in zip(ranks, lineage):
        tax = tax.replace(' ', '_').replace(',', '.')
        parts.append(f'{rank}:{tax}')

    return 'tax=' + ','.join(parts)

def parse_unite_utax(header):
    """
    >ID|SHxxxx;tax=d:Fungi,p:Ascomycota,...
    """
    if 'tax=' not in header:
        return None, None

    id_part = header.split(';')[0]
    tax_part = header.split('tax=')[1].rstrip(';')

    lineage = []
    for t in tax_part.split(','):
        if ':' in t:
            lineage.append(t.split(':', 1)[1])

    return id_part, lineage

def parse_unite_others(header):
    """
    UCHIME:
      >ID|UDBxxxx|SHxxxx|reps|k__Fungi;p__Ascomycota;...
    PUBLIC:
      >UDBxxxx|k__Fungi;p__Basidiomycota;...;s__Cystoderma_amianthinum|SHxxxx
    """
    if '|k__' not in header:
        return None, None

    id_part = header.split('|k__')[0]
    id_part = '|'.join(id_part.split('|')[0:3])

    lineage_raw = header.split('|k__')[1]
    lineage_raw = lineage_raw.split('|')[0]

    lineage_raw = (lineage_raw
                   .replace('k__', '')
                   .replace('p__', '')
                   .replace('c__', '')
                   .replace('o__', '')
                   .replace('f__', '')
                   .replace('g__', '')
                   .replace('s__', ''))

    lineage = [x for x in lineage_raw.split(';') if x]

    return id_part, lineage

def load_taxmap(taxmap_file):
    df = pd.read_csv(taxmap_file, sep = '\t', compression = 'infer', dtype = str, usecols = ['primaryAccession', 'path', 'organism_name', 'taxid'])

    taxmap = {}
    for row in df.itertuples(index = False):
        lineage = [tax for tax in row.path.split(';') if tax]

        taxmap[row.primaryAccession] = {'path': row.path,
                                        'lineage': lineage,
                                        'organism': row.organism_name,
                                        'taxid': int(row.taxid)}
    return taxmap

def load_taxslv(taxslv_file):
    df = pd.read_csv(taxslv_file, sep = '\t', compression = 'infer', dtype = str, header = None, usecols = [0, 1, 2], names = ['path', 'taxid', 'rank'])

    taxslv = {}
    for row in df.itertuples(index = False):
        taxslv[row.path] = {'taxid': int(row.taxid),
                            'rank': row.rank}
    return taxslv

def split_lineage(path: str):
    taxa = [x for x in path.split(';') if x]

    if not taxa:
        return None, None

    current = taxa[-1]

    if len(taxa) == 1:
        return None, current

    parent = ';'.join(taxa[:-1]) + ';'

    return parent, current

def build_taxonomy(taxpath, organism, dict_taxslv):
    taxonomy = {}
    taxonomy['species'] = organism

    current_path = taxpath
    while current_path:
        info = dict_taxslv.get(current_path)

        if not info:
            break

        rank = info['rank']
        parent, taxon = split_lineage(current_path)
        taxonomy[rank] = taxon
        current_path = parent

    return taxonomy

def taxonomy_to_lineage(taxonomy):
    default = ''
    lineage = [taxonomy.get('domain', default),
               taxonomy.get('kingdom', default),
               taxonomy.get('phylum', default),
               taxonomy.get('class', default),
               taxonomy.get('order', default),
               taxonomy.get('family', default),
               taxonomy.get('genus', default),
               taxonomy.get('species', default)]

    return lineage

def edit_database_fasta(fasta_file, db_type = 'silva', taxmap_file = None, taxslv_file = None, output_file = None):
    if db_type == 'silva':
        dict_taxmap = load_taxmap(taxmap_file)
        dict_taxslv = load_taxslv(taxslv_file)

    records = SeqIO.index(fasta_file, 'fasta')
    total = len(records)

    records = []
    with tqdm(total = total) as pbar:
        for record in SeqIO.parse(fasta_file, 'fasta'):
            if db_type == 'silva':
                _id = record.id
                _accession = _id.split('.')[0]

                taxpath = dict_taxmap[_accession]['path']
                organism = dict_taxmap[_accession]['organism']
                taxonomy = build_taxonomy(taxpath, organism, dict_taxslv)

                lineage = taxonomy_to_lineage(taxonomy)

                _lineage_format = format_lineage(lineage, db_type)
                _id = f'{_id};{_lineage_format};'

                rec = SeqRecord(Seq(str(record.seq)), id = _id, description = '')
                records.append(rec)
            elif db_type == 'unite':
                header = record.description

                id_part, lineage = parse_unite_utax(header)

                if id_part is None:
                    id_part, lineage = parse_unite_others(header)

                if id_part is None or not lineage:
                    continue

                _lineage_format = format_lineage(lineage, db_type)
                _id = f'{id_part};{_lineage_format};'

                rec = SeqRecord(Seq(str(record.seq)), id = _id, description = '')
                records.append(rec)
            pbar.update(1)

    if not output_file:
        _path = os.path.dirname(fasta_file)
        output_file = os.path.join(_path, f'{db_type}.fa')

    SeqIO.write(records, output_file, 'fasta')

def existing_file(path: str):
    if not os.path.isfile(path):
        raise argparse.ArgumentTypeError(f"File not found: {path}")
    return path

def main():
    parser = argparse.ArgumentParser(description = 'Rename reference database FASTA headers to UTAX format')
    parser.add_argument('-d', '--db-type', required = True, choices = ['silva', 'unite'], help = 'Database type')
    parser.add_argument('-i', '--input', required = True, type = existing_file, help = 'Input fasta file')
    parser.add_argument('--taxmap', type = existing_file, help = 'SILVA taxmap file (.txt/.gz)')
    parser.add_argument('--taxslv', type = existing_file, help = 'SILVA tax_slv file (.txt/.gz)')
    parser.add_argument('-o', '--output', help = 'Output fasta (default: auto *.fa)')
    args = parser.parse_args()

    if args.db_type == 'silva':
        if not args.taxmap or not args.taxslv:
            parser.error('SILVA requires --taxmap and --taxslv')

    edit_database_fasta(fasta_file = args.input, db_type = args.db_type, taxmap_file = args.taxmap, taxslv_file = args.taxslv, output_file = args.output)

if __name__ == '__main__':
    main()

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import argparse
import pandas as pd

def read_taxonomy_file_sintax(file):
    df = pd.read_csv(filepath_or_buffer = file, sep = '\t', header = None, usecols = [0, 3], names = ['id', 'lineage'])
    df = df.where(pd.notnull(df), '')
    # print(df)

    elements = {}
    for _, row in df.iterrows():
        id = row['id']
        lineage = row['lineage'].strip()

        if id not in elements:
            elements.update({id: lineage})

    return elements

def read_taxonomy_file_blast(file):
    df = pd.read_csv(filepath_or_buffer = file, sep = '\t', header = None, usecols = [0, 1, 2], names = ['qseqid', 'sseqid', 'stitle'])
    df = df.where(pd.notnull(df), '')
    # print(df)

    elements = {}
    for _, row in df.iterrows():
        query_id = row['qseqid']
        id = query_id.split(';')[0].strip()
        lineage = row['sseqid']

        if id not in elements:
            elements.update({id: lineage})

    return elements

def get_annotation_file(approach, file_hits, file_count, format_type, output_file):
    dict_items = {}
    if approach == 'asv':
        dict_items = read_taxonomy_file_sintax(file_hits)
    elif approach == 'otu':
        dict_items = read_taxonomy_file_blast(file_hits)

    df = pd.read_csv(filepath_or_buffer = file_count, sep = '\t', header = 0)
    df = df.where(pd.notnull(df), '')
    # print(df)

    arr_lineage = []
    arr_domain = []
    arr_kingdom = []
    arr_phylum = []
    arr_class = []
    arr_order = []
    arr_family = []
    arr_genus = []
    arr_species = []
    arr_level = []
    for idx, row in df.iterrows():
        item_id = row['#OTU ID']

        if item_id in dict_items:
            taxonomy = {'d': '',
                        'k': '',
                        'p': '',
                        'c': '',
                        'o': '',
                        'f': '',
                        'g': '',
                        's': ''}
            lineage = dict_items[item_id]

            lineage_comp = []
            if approach == 'asv':
                lineage_comp = lineage.split(',')
            elif approach == 'otu':
                lineage_comp = lineage.split('tax=')[1].strip()
                lineage_comp = lineage_comp.split(',')

            lineage_arr = [item.split(':') for item in lineage_comp]

            for tupla in lineage_arr:
                id = tupla[0]
                if id:
                    name = tupla[1].replace('_', ' ').replace("\"", '')
                    if id in taxonomy:
                        if id == 'd':
                            if format_type == 'unite':
                                taxonomy['d'] = 'Eukaryota'
                                taxonomy['k'] = name
                            elif format_type == 'silva':
                                taxonomy[id] = name
                        else:
                            taxonomy[id] = name

            lineage_split = [taxonomy['d'],
                             taxonomy['k'],
                             taxonomy['p'],
                             taxonomy['c'],
                             taxonomy['o'],
                             taxonomy['f'],
                             taxonomy['g'],
                             taxonomy['s']]

            arr_levels = ['Domain', 'Kingdom', 'Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species']

            i = len(arr_levels) - 1
            level = 'Unknown'
            while i >= 0:
                if lineage_split[i]:
                    level = arr_levels[i]
                    break
                i -= 1

            arr_level.append(level)
        else:
            lineage = ''
            lineage_split = [''] * 8
            arr_level.append('Unknown')

        arr_lineage.append(lineage)
        arr_domain.append(lineage_split[0])
        arr_kingdom.append(lineage_split[1])
        arr_phylum.append(lineage_split[2])
        arr_class.append(lineage_split[3])
        arr_order.append(lineage_split[4])
        arr_family.append(lineage_split[5])
        arr_genus.append(lineage_split[6])
        arr_species.append(lineage_split[7])

    df.insert(loc = 1, column = 'Lineage', value = arr_lineage)
    df.insert(loc = 2, column = 'Domain', value = arr_domain)
    df.insert(loc = 3, column = 'Kingdom', value = arr_kingdom)
    df.insert(loc = 4, column = 'Phylum', value = arr_phylum)
    df.insert(loc = 5, column = 'Class', value = arr_class)
    df.insert(loc = 6, column = 'Order', value = arr_order)
    df.insert(loc = 7, column = 'Family', value = arr_family)
    df.insert(loc = 8, column = 'Genus', value = arr_genus)
    df.insert(loc = 9, column = 'Species', value = arr_species)
    df.insert(loc = 10, column = 'Level', value = arr_level)

    if approach == 'asv':
        df.rename(columns = {'#OTU ID': '#ASV ID'}, inplace = True)
    # print(df)

    df.to_csv(output_file, sep = '\t', encoding = 'utf-8', index = False)

def existing_file(path: str):
    if not os.path.isfile(path):
        raise argparse.ArgumentTypeError(f'File not found: {path}')
    return path

def main():
    parser = argparse.ArgumentParser(description = 'Annotate ASV/OTU abundance table')
    parser.add_argument('-a', '--approach', required = True, choices = ['asv', 'otu'], help = 'Approach')
    parser.add_argument('-f', '--format-type', required = True, choices = ['silva', 'unite'], help = 'Taxonomy format')
    parser.add_argument('-c', '--hits-file', required = True, type = existing_file, help = 'SINTAX/BLAST result file')
    parser.add_argument('-b', '--abundances-file', required = True, type = existing_file, help = 'ASV/OTU abundance table')
    parser.add_argument('-o', '--output', required = True, help = 'Output annotated table')
    args = parser.parse_args()

    get_annotation_file(args.approach, args.hits_file, args.abundances_file, args.format_type, args.output)

if __name__ == '__main__':
    main()

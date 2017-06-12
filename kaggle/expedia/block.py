import csv
import time
import argparse
import random


def parse_args(argv=None):
    pass


def add_recnum_and_block(blocking_levels, in_filename, out_filename, match_col='user_id', match_col_type=int, encoding='ascii', seed=399574089323, add_recnum=True):
    if isinstance(blocking_levels, int):
        blocking_levels = [blocking_levels]
    blocking_levels.sort()
    block_names = ['block{l}'.format(l=l) for l in blocking_levels]
    match_col_vals = set()
    with open(in_filename, 'r', newline='', encoding=encoding) as in_fp:
        reader = csv.reader(in_fp)
        header = next(reader)
        assert(match_col in header)
        assert('recnum' not in header)
        for name in block_names:
            assert (name not in header)
        match_col_index = header.index(match_col)
        for row in reader:
            m = match_col_type(row[match_col_index])
            match_col_vals.add(m)
    match_col_vals = list(match_col_vals)
    blocks = []
    random.seed(seed)
    for max_levels in blocking_levels:
        random.shuffle(match_col_vals)
        blocks.append({m:i%max_levels for i,m in enumerate(match_col_vals)})

    # save blocks
    blocks_filename = out_filename.replace('.csv', '')+'_blocks.csv'
    with open(blocks_filename, 'w', newline='', encoding=encoding) as out_fp:
        writer = csv.writer(out_fp)
        writer.writerow([match_col]+block_names)
        match_col_vals.sort()
        for m in match_col_vals:
            writer.writerow([m]+[b[m] for b in blocks])
                
    # Now process
    with open(in_filename, 'r', newline='', encoding=encoding) as in_fp:
        reader = csv.reader(in_fp)
        header = next(reader)
        new_header = []
        if add_recnum:
            new_header = ['recnum']
        new_header += header+block_names
        with open(out_filename, 'w', newline='', encoding=encoding) as out_fp:
            writer = csv.writer(out_fp)
            writer.writerow(new_header)
            for recnum, row in enumerate(reader):
                m = match_col_type(row[match_col_index])
                new_row = []
                if add_recnum:
                    new_row = [recnum]
                new_row += row+[b[m] for b in blocks]
                writer.writerow(new_row)
    
                
def main():
    #blocking_levels = [31]
    #add_recnum_and_block(blocking_levels, 'train.csv', 'blocked_train.csv')

    blocking_levels = [29]
    add_recnum_and_block(blocking_levels, 'test.csv', 'blocked_test.csv', match_col='id', add_recnum=False)
    

if __name__ == '__main__':
    main()

    

    


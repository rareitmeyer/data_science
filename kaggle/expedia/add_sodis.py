import os
import csv
import re
import sys
import pdb
import time
import math

ISID = re.compile('^((id)|(recnum))$')

dt2015 = time.mktime(time.strptime('2015-01-01 00:00:00', '%Y-%m-%d %H:%M:%S'))
def fix_dage(row, dt_idx, dage_idx):
    dt_raw = row[dt_idx]
    dt = time.mktime(time.strptime(dt_raw, '%Y-%m-%d %H:%M:%S'))
    delta = max(0,dt2015 - dt)
    dage = math.floor(delta / 60 / 60 / 24 / 30)
    row[dage_idx] = str(dage)
    print('  {r} -> {m}'.format(r=dt_raw,m=dage))
    return row

def fix(filename_base):
    """Fixes up table from an original file ('blocked_'+filename_base+'.csv')
    and a 'ab'+filename_base+'.sorted.csv' file. Makes a new file
    'ab'+filename_base+'.sodis.csv' file with the contents of the 'ab'
    filename and an extra 'sodis' column.

    Files MUST BOTH BE SORTED with something like the sort command.

    Special exception: It's OK if the first-line header is after the
    1st record, as sometimes happens with a numeric sort.
    """
    ab_filename = 'ab'+filename_base+'.sorted.csv'
    b_filename = 'blocked_'+filename_base+'.csv'
    dest_filename = 'ab'+filename_base+'.sodis.csv'
    assert os.path.exists(ab_filename)
    assert os.path.exists(b_filename)
    
    with open(dest_filename, 'w', encoding='utf-8', newline='') as destfp:
        writer = csv.writer(destfp)
        with open(ab_filename, 'r', encoding='utf-8', newline='') as abfp:
            abreader = csv.reader(abfp)
            ab0 = next(abreader)
            ab1 = next(abreader)
            ab01 = [ab0,ab1]
            if ISID.match(ab0[0]):
                print('abfile header is row 0')
                pass
            elif ISID.match(ab1[0]):
                print('abfile header is row 1')
                ab01 = [ab1,ab0]
            else:
                print('abfile lacks header')
                raise ValueError('abfile lacks header')
            with open(b_filename, 'r', encoding='utf-8', newline='') as bfp:
                breader = csv.reader(bfp)
                b0 = next(breader)
                b1 = next(breader)
                
                b01 = [b0,b1]
                if ISID.match(b0[0]):
                    print('bfile header is row 0')
                    pass
                elif ISID.match(b1[0]):
                    print('bfile header is row 1')
                    b01 = [b1,b0]
                else:
                    print('bfile lacks header')
                    raise ValueError('bfile lacks header')
    
                # check headers are the same
                assert ab01[0][0] == b01[0][0]

                # check there is a odis col
                assert 'orig_destination_distance' in b01[0]
                sodis_idx = b01[0].index('orig_destination_distance')
                assert 'aux_dt_mage' in ab01[0]
                aux_dt_mage_idx = ab01[0].index('aux_dt_mage')
                assert 'date_time' in ab01[0]
                dt_idx = ab01[0].index('date_time')
                
                # write new header
                header = ab01[0]+['sodis']
                writer.writerow(header)

                # confirm 1st data rows have same id/recnum
                if ab01[1][0] != b01[1][0]:
                    msg = 'have mis-matched IDs for first data row: {ab} != {b} (ab!=b)'.format(ab=ab01[1][0], b=b01[1][0])
                    print(msg)
                    pdb.set_trace()
                    raise ValueError(msg)

                # write 1st data row
                ab01[1] = fix_dage(ab01[1], dt_idx, aux_dt_mage_idx)
                writer.writerow(ab01[1]+[b01[1][sodis_idx]])

                for (ab,b) in zip(abreader,breader):
                    # confirm same keys
                    if ab[0] != b[0]:
                        msg = 'at line {l}, have mis-matched IDs for first data row: {ab} != {b} (ab!=b)'.format(l=abreader.line_num, ab=ab01[1][0], b=b01[1][0])
                        print(msg)
                        pdb.set_trace()
                        raise ValueError(msg)

                    # write data
                    ab = fix_dage(ab, dt_idx, aux_dt_mage_idx)
                    writer.writerow(ab+[b[sodis_idx]])
                    

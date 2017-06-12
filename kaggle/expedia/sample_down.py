# Samples a CSV file to turn it into a set of smaller files. Designed
# to work on files that are too big to load into memory, and have too
# many lines to even random.shuffle(list(range(max_rec_num))) to
# figure out which line goes where.
#
# Makes several passes over files sized per the data: one to get the
# count of lines in the data, a second to generate a shuffle file
# with the same number of rows, a third to shuffle the shuffle file,
# and a fourth pass to break up the original input.
#
# Will print out progress for the shuffle and sample steps. Can't
# estimate progress for reading the initial input.
#

import os
import sys
import csv
import random
import argparse
import time
import re
import logging


import progress


STARTTIME = time.time()
LOGFILE = os.path.join(
    os.path.dirname(__file__),"logs",
    os.path.basename(__file__)+
    time.strftime('.%Y%m%d_%H%M%S.log', time.localtime(STARTTIME))
)
if not os.path.exists(os.path.dirname(LOGFILE)):
    os.makedirs(os.path.dirname(LOGFILE))
logging.basicConfig(
    filename=LOGFILE,
    format='%(asctime)s|%(levelno)d|%(levelname)s|%(filename)s|%(lineno)d|%(message)s',
    level=logging.INFO
    )


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description='Sample a CSV file into a set a smaller files in a subdirectory')
    parser.add_argument('-i', metavar='infile', dest='infile', help='Name of the input CSV file')
    parser.add_argument('-o', metavar='outdir', dest='outdir', help='Name of the output directory for the CSV file. Must not exist.')
    parser.add_argument('-n', metavar='N', type=int, default=10, dest='n', help='The number of files to use as output.')
    parser.add_argument('--seed', metavar='N', type=int, default=44976181, dest='seed', help='Random-number seed for sampling.')
    parser.add_argument('--encoding', metavar='encoding', default='latin1', dest='encoding', help='The encoding of the input file')


    args = parser.parse_args(argv)

    # Now do some sanity checking.
    if args.infile is None:
        raise ValueError('Must specify an input file with -i')
    if args.outdir is None:
        raise ValueError('Must specify an output directory with -o')
    if args.n <= 1:
        raise ValueError('Number of files for output must be greater than one.')

    # Confirm the input exists
    if not os.path.exists(args.infile):
        raise ValueError('Input file must exist')
    # Confirm the input exists
    if os.path.exists(args.outdir):
        raise ValueError('Output directory must not exist')

    return args


def get_records(filename, encoding, progress_filename=None):
    """Get the count of the records. Incidentally, this will
    confirm we can read the file with the provided encoding.
    """
    input_size = os.stat(filename).st_size
    progress_tracker = progress.ProgressTracker(input_size, 'initial_count', progress_filename)
    msg = 'reading input file, please be patient'
    print(msg)
    logging.info(msg)
    max_rec = 0
    with open(filename, 'r', newline='', encoding=encoding) as fp:
        reader = csv.reader(fp)
        hdr = next(reader)
        for row in reader:
            max_rec +=1
            if max_rec % 100000 == 0:
                fp.flush()  # must flush before calling .tell()
                progress_tracker(fp.tell())
    return max_rec


def init_shuffle(filename, records, buckets, progress_filename=None):
    progress_tracker = progress.ProgressTracker(records, 'init_shuffle', progress_filename)

    msg = 'creating shuffle file, please be patient'
    print(msg)
    logging.info(msg)

    buckchars = len('{b}'.format(b=buckets))
    buckfmt = '{b:' + str(buckchars) + 'd}\n'
    n = 0
    size = 0
    with open(filename, 'w', encoding='ascii', newline='') as fp:
        for i in range(records):
            b = i % buckets
            size = fp.write(buckfmt.format(b=b))
            assert(size == buckchars+1)
            if i % 100000 == 0:
                progress_tracker(i)
    return size


def read_value(fp, offset, chars):
    fp.seek(offset)
    return(fp.read(chars))


def write_value(fp, offset, value):
    fp.seek(offset)
    fp.write(value)


def swap_pair(fp, bucksize, index1, index2):
    v1 = read_value(fp, bucksize*index1, bucksize)
    v2 = read_value(fp, bucksize*index2, bucksize)

    write_value(fp, bucksize*index2, v1)
    write_value(fp, bucksize*index1, v2)




def swap_pairs(filename, records, bucksize, progress_filename=None):
    progress_tracker = progress.ProgressTracker(records, 'shuffle', progress_filename)

    msg = 'shuffling the shuffle file, please be patient'
    print(msg)
    logging.info(msg)

    with open(filename, 'r+', encoding='ascii') as fp:
        for i in range(records):
            j = random.randrange(records)
            k = random.randrange(records)
            if j != k:
                swap_pair(fp, bucksize, j, k)
            if i % 10000 == 0:
                progress_tracker(i)


def make_samples(infile, outdir, shuffle_file, records, encoding='latin1', progress_filename=None):
    progress_tracker = progress.ProgressTracker(records, 'sample', progress_filename)
    msg = 'sampling the data per shuffle file, please be patient'
    print(msg)
    logging.info(msg)

    out_fps = {}
    out_writers = {}
    outfilename_pat = re.sub('\\.csv$', '{b}.csv', infile)
    try:
        header = []
        with open(shuffle_file, 'r') as shuffle_fp:
            with open(infile, 'r', encoding=encoding, newline='') as in_fp:
                reader = csv.reader(in_fp)
                header = next(reader)
                for i, row in enumerate(reader):
                    bucket = int(shuffle_fp.readline())
                    if bucket not in out_fps:
                        outpath = os.path.join(outdir, outfilename_pat.format(b=bucket))
                        out_fps[bucket] = open(outpath, 'w', encoding=encoding, newline='')
                        out_writers[bucket] = csv.writer(out_fps[bucket])
                        out_writers[bucket].writerow(header)
                    out_writers[bucket].writerow(row)

                    if i % 10000 == 0:
                        progress_tracker(i)

    finally:
        for f in out_fps:
            out_fps[f].close()



def main(argv=None):
    args = parse_args(argv)

    os.makedirs(args.outdir)
    with open(os.path.join(args.outdir, '.seed'), 'w', encoding='ascii') as fp:
        fp.write('{s}\n'.format(s=args.seed))
    with open(os.path.join(args.outdir, '.buckets'), 'w', encoding='ascii') as fp:
        fp.write('{n}\n'.format(n=args.n))
    random.seed(args.seed)

    # save progress to a file.
    progress_filename = os.path.join(args.outdir, '.progress')
    num_rec = get_records(args.infile, args.encoding, progress_filename=progress_filename)


    # make a shuffle file
    shuffle_filename = os.path.join(args.outdir, '.shuffle')

    shuffle_size = init_shuffle(shuffle_filename, num_rec, args.n, progress_filename=progress_filename)
    swap_pairs(shuffle_filename, num_rec, shuffle_size, progress_filename=progress_filename)

    # use the shuffle file to make the samples
    make_samples(args.infile, args.outdir, shuffle_filename, num_rec, encoding=args.encoding, progress_filename=progress_filename)








if __name__ == '__main__':
    try:
        main()
        endtime = time.time()
        logging.info("processing finished successfully after {s} seconds".format(s=endtime-STARTTIME))
    except Exception as e:
        logging.exception(e)
        raise


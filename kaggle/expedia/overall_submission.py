import sys
import random
import time
import csv

def main():
    data = None
    with open('overall_clusters.csv', 'r', encoding='ascii', newline='') as fp:
        reader = csv.reader(fp)
        header = next(reader)
        data = [(int(x),i) for i,x in enumerate(next(reader))]
        data.sort(reverse=True)
    top_5 = [i[1] for i in data[:5]]

    with open('sample_submission.csv', 'r', encoding='ascii', newline='') as in_fp:
        reader = csv.reader(in_fp)
        header = next(reader)
        with open(time.strftime('overall_submission_%Y%m%d_%H%M%S.csv'), 'w', encoding='ascii', newline='') as out_fp:
            writer = csv.writer(out_fp)
            writer.writerow(header)
            for row in reader:
                writer.writerow([row[0], ' '.join([str(x) for x in top_5])])


if __name__ == '__main__':
    main()   

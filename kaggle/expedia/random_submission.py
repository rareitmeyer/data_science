import random
import time
import csv

def main():
    with open('sample_submission.csv', 'r', encoding='ascii', newline='') as in_fp:
        reader = csv.reader(in_fp)
        header = next(reader)
        with open(time.strftime('random_submission_%Y%m%d_%H%M%S.csv'), 'w', encoding='ascii', newline='') as out_fp:
            writer = csv.writer(out_fp)
            writer.writerow(header)
            for row in reader:
                writer.writerow([row[0], ' '.join([str(x) for x in random.sample(range(100),5)])])


if __name__ == '__main__':
    main()   

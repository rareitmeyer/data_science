import os
import time
import csv
import logging


# Some routines to track progress


class ProgressTracker(object):
    def __init__(self, finish_record, phase='', save_filename=None, remove_existing_progress_file=False, print_progress=True, log_progress=True):
        self.finish_record = finish_record
        self.phase = phase
        self.save_filename=save_filename
        self.print_progress = print_progress
        self.log_progress = log_progress

        self.first_cp = None
        self.latest_cp = None
        
        if (self.save_filename is not None and 
            os.path.exists(self.save_filename) and 
            remove_existing_progress_file):
            os.unlink(self.save_filename)


    def checkpoint(self, record_num):
        now = time.time()
        cp = {'record': record_num, 'time': now, 'time_human': time.strftime('%Y-%m-%dT%H:%M:%S', time.localtime(now)), 'phase': self.phase}
        if self.first_cp is None:
            self.first_cp = cp
        self.latest_cp = cp
        return cp
    
    
    def estimate_completion(self):
        if ((self.latest_cp['record'] <= self.first_cp['record']) or 
            self.finish_record is None):
            return {
                'pct_done': None,
                'pct_done_human': '?',
                'finish_time': None,
                'finish_time_human': '?',
                'finish_record': self.finish_record,
                'records_per_minute': None,
                'rpm': '?',
                }
        # alias self.first_cp and self.latest_cp to make this shorter
        cp1 = self.first_cp
        cp2 = self.latest_cp

        pct_done = 100.0*cp2['record']/self.finish_record
        total_time = (self.finish_record - cp1['record']) * (cp2['time'] - cp1['time']) / (cp2['record'] - cp1['record'])
        finish_time = cp1['time'] + total_time
        finish_time_human = time.strftime('%Y-%m-%dT%H:%M:%S', time.localtime(finish_time))
        records_per_minute = (cp2['record'] - cp1['record']) / (cp2['time'] - cp1['time']) * 60
        return {
            'pct_done': pct_done,
            'pct_done_human': '{p:5.2f}%'.format(p=pct_done),
            'total_time': total_time,
            'finish_time': finish_time, 
            'finish_time_human': finish_time_human,
            'finish_record': self.finish_record,
            'records_per_minute': records_per_minute,
            'rpm': '{x:8.4f}'.format(x=records_per_minute),
            }
    
    
    def save(self):
        assert (self.save_filename is not None)

        progress_header = ['time', 'time_human', 'phase', 'record', 'pct_done', 'records_per_minute', 'total_time', 'finish_record', 'finish_time', 'finish_time_human']
        if not os.path.exists(self.save_filename):
            with open(self.save_filename, 'w', encoding='utf-8', newline='') as fp:
                prog_writer = csv.writer(fp)
                prog_writer.writerow(progress_header)
        with open(self.save_filename, 'a', encoding='utf-8', newline='') as fp:
            prog_writer = csv.writer(fp)
            prog_writer.writerow([self.latest_cp.get(k, '') for k in progress_header])


    def __call__(self, i):
        cp = self.checkpoint(i)
        cp.update(self.estimate_completion())

        msg = "{th}:  {phase} {pct} done, so {rpm} rec/min -> done ~ {fth}".format(th=cp.get('time_human', ''), phase=self.phase, pct=cp.get('pct_done_human', ''), rpm=cp.get('rpm', ''), fth=cp.get('finish_time_human', ''))
        if self.print_progress:
            print(msg)
        if self.log_progress:
            logging.info(msg)
        if self.save_filename is not None:
            self.save()

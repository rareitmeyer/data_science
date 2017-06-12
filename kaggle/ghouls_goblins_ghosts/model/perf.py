# Performance decorator, including memory-use watcher, to track behavior
# of any functions you care to mark.  Useful for figuring out which code
# is consuming too much time or memory.
#
# Example of tracking foo:
#
#     import perf
#
#     @perf.perf_deco
#     def foo(n):
#         # your code here; just allocating memory for example
#         import numpy as np
#         return np.eye(x)
#
#
# Invoke functions normally, and at the end of the function call you'll see a
# printed message with elapsed time and current memory usage.
#     >>> e10k = foo(10000)
#     foo returning successfully after   0.0241s elapsed; now using  985.2 MB
# If there's an exception, you'll see a similar message, but the exception will
# propigate back up the stack to be caught (or not) with the normal backtrace
# for debugging.
#
# Perf deco is copyright 2016 R. A. Reitmeyer, and released under MIT license.
# Hope it helps!


import ctypes
import logging
import os
import sys
import time


class ProcWatcher(object):
    """Class to check a Linux process's statistics from /proc. Useful
    for watching things like process-level memory usage.
    """
    def __init__(self):
        if sys.platform != 'linux':
            return
        try:
            libc = ctypes.cdll.LoadLibrary('libc.so.6')
            # Have to read /usr/include/x86_64-linux-gnu/bits/confname.h to know the
            # args, unfortunately...
            self.PAGESIZE = libc.getpagesize()
            self.CLOCKTICK = libc.sysconf(2)

            self.cols = 'pid comm state ppid pgrp session tty_nr tpgid flags minflt cminflt majflt cmajflt utime stime cutime cstime priority nice num_threads itrealvalue starttime vsize rss rsslim'.split(' ')
        except Exception as e:
            logging.error('Exception trying to get stats from /proc: {e}'.format(e=repr(e)))


    def stats(self, pid=None):
        """Return a dictionary of statistics on the process.

        If pid is none, data is for this process.

        Typical return dictionary has data for the vsize_MB and rss_MB,
        as well u/s/cu/cs time in minutes.

        If there is no process with the given pid, returns an empty
        dictionary.
        """
        if sys.platform != 'linux':
            return {}
        if pid is None:
            pid = os.getpid()

        try:
            with open('/proc/{pid}/stat'.format(pid=pid), 'r', encoding='ascii') as fp:
                raw = fp.readline().strip().split(' ')
                cooked = dict(zip(self.cols,raw))
                retval = {k+'_min':float(cooked[k])/self.CLOCKTICK/60.0 for k in 'utime stime cutime cstime'.split(' ')}
                retval['vsize_MB'] = float(cooked['vsize'])/1024.0/1024.0
                retval['rss_MB'] = float(cooked['rss'])*self.PAGESIZE/1024.0/1024.0

                return retval
        except Exception as e:
            logging.error('Exception trying to get stats from /proc/{pid}/stat: {e}'.format(pid=pid, e=repr(e)))
            return {}



PROC_WATCHER = ProcWatcher()

def perf_deco(fn):
    """Decorate a function with a wrapper that prints how long the
    function took after every evaluation, and (on linux) shows memory
    use.
    """
    def wrapper(*args, **kwds):
        start = time.time()
        retval = None
        try:
            retval = fn(*args, **kwds)
        except Exception as e:
            stats = PROC_WATCHER.stats()
            print('{name} failed with exception {e} after {elapsed:8.4f}s elapsed, now using {vsize_MB:6.1f} MB'.format(name=fn.__name__, e=e, elapsed=time.time()-start, vsize_MB=stats.get('vsize_MB',0)))
            raise
        stats = PROC_WATCHER.stats()
        print('{name} returning successfully after {elapsed:8.4f}s elapsed; now using {vsize_MB:6.1f} MB'.format(name=fn.__name__, elapsed=time.time()-start, vsize_MB=stats.get('vsize_MB',0)))
        return retval

    return wrapper

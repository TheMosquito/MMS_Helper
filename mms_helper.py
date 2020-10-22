#
# MMS Helper
#
# Written by Glen Darling, October 2020.
#

import json
import os
import subprocess
import threading
import time
import base64

# Configuration from the process environment
def get_from_env(v, d):
  if v in os.environ and '' != os.environ[v]:
    return os.environ[v]
  else:
    return d
HZN_ESS_AUTH = get_from_env('HZN_ESS_AUTH', '/ess-auth/auth.json')
HZN_ESS_CERT = get_from_env('HZN_ESS_CERT', '/ess-auth/cert.pem')
HZN_ESS_API_ADDRESS = get_from_env('HZN_ESS_API_ADDRESS', '/var/run/horizon/essapi.sock')
MMS_HELPER_VOLUME_MOUNT = get_from_env('MMS_HELPER_VOLUME_MOUNT', '/shared_dir')
MMS_HELPER_OBJECT_TYPE = get_from_env('MMS_HELPER_OBJECT_TYPE', 'unknown')

# Load the ESS credentials (user/token)
with open(HZN_ESS_AUTH) as creds_file:
  creds = json.load(creds_file)
HZN_ESS_USER = creds['id']
HZN_ESS_TOKEN = creds['token']

# Cheap debug
DEBUG = False
def debug(s):
  if DEBUG:
    print(s)

# Cheap logging
INFO = False
WARNING = True
ERROR = True
def log(t, s):
  if (INFO and t == 'info') or (WARNING and t == 'WARNING') or (ERROR and t == 'ERROR'):
    print("%s: %s" % (t, s))

def main():
  LOOP_DELAY_SEC = 3
  debug('\nMonitoring ESS...')
  debug('  user=%s' % HZN_ESS_USER)
  debug('  token=%s' % HZN_ESS_TOKEN)
  debug('  cacert=%s' % HZN_ESS_CERT)
  debug('  socket=%s' % HZN_ESS_API_ADDRESS)
  debug('  object_type=%s' % MMS_HELPER_OBJECT_TYPE)
  debug('  shared_dir=%s' % MMS_HELPER_VOLUME_MOUNT)

  ESS_OBJECT_LIST_BASE = 'curl -sSL -u %s:%s --cacert %s --unix-socket %s https://localhost/api/v1/objects/%s'
  ESS_REDIRECT_BASE = 'curl -sSL -u %s:%s --cacert %s --unix-socket %s https://localhost/api/v1/objects/%s/%s/data -o %s/%s'
  ESS_MARK_RECEIVED_BASE = 'curl -sSL -X PUT -u %s:%s --cacert %s --unix-socket %s https://localhost/api/v1/objects/%s/%s/received'
  while True:
    get_objects = ESS_OBJECT_LIST_BASE % (HZN_ESS_USER, HZN_ESS_TOKEN, HZN_ESS_CERT, HZN_ESS_API_ADDRESS, MMS_HELPER_OBJECT_TYPE)
    try:
      raw = subprocess.check_output(get_objects, shell=True)
      output = raw.decode("utf-8") 
      debug('\n\nReceived from ESS:\n')
      debug(output)
      j = json.loads(output)
      id = j[-1]['objectID']
      deleted = j[-1]['deleted']
      if not deleted:
        tempfile = '.' + id
        redirect_command = ESS_REDIRECT_BASE % (HZN_ESS_USER, HZN_ESS_TOKEN, HZN_ESS_CERT, HZN_ESS_API_ADDRESS, MMS_HELPER_OBJECT_TYPE, id, MMS_HELPER_VOLUME_MOUNT, tempfile)
        try:
          subprocess.run(redirect_command, shell=True, check=True)
          debug('ESS object file copy was successful.')
          try:
            rename_command = '/bin/mv %s/%s %s/%s' % (MMS_HELPER_VOLUME_MOUNT, tempfile, MMS_HELPER_VOLUME_MOUNT, id)
            subprocess.run(rename_command, shell=True, check=True)
            debug('File rename was successful.')
            mark_received_command = ESS_MARK_RECEIVED_BASE % (HZN_ESS_USER, HZN_ESS_TOKEN, HZN_ESS_CERT, HZN_ESS_API_ADDRESS, MMS_HELPER_OBJECT_TYPE, id)
            try:
              log("info", mark_received_command)
              subprocess.run(mark_received_command, shell=True, check=True)
              debug('ESS object received command was successful.')
            except:
              log("ERROR", mark_received_command)
          except:
            log("ERROR", rename_command)
        except:
          log("ERROR", redirect_command)
    except:
      log("info", get_objects)
    debug('Sleeping for ' + str(LOOP_DELAY_SEC) + ' seconds...')
    time.sleep(LOOP_DELAY_SEC)

if __name__ == '__main__':
  main()

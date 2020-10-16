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

# Configuration constants
FLASK_BIND_ADDRESS = '0.0.0.0'
FLASK_PORT = 2222
ESS_COMMAND = '...'

# ESS credentials (must be provided via "/config" REST POST)
ESS_CREDS = None

# Globals for the cached JSON data (latest from the ESS)
last_ess = None

# Cheap debug
def debug(s):
  # Comment out the line below to control debug output
  print(s)
  pass

if __name__ == '__main__':

  from io import BytesIO
  from flask import Flask
  from flask import send_file
  rest_api = Flask('MMS Helper')                             
  rest_api.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0

  # Loop forever collecting info from the ESS
  class EssThread(threading.Thread):
    def run(self):
      global last_cam
      debug('\nESS monitor thread started!')
      ESS_COMMAND = '...'
      T = 5
      while True:
        if ESS_CREDS:
          last_ess = subprocess.check_output(ESS_COMMAND, shell=True)
          #if <auth error>:
          #  # Creds failed, so delete them
          #  ESS_CREDS = None
          debug('\n\nMessage received from ESS...\n')
          debug(last_ess)
        debug('\nSleeping for ' + str(T) + ' seconds...\n')
        time.sleep(T)

  @rest_api.route('/config')
  def get_yolo_image():
    debug('\nREST request: "/config"...')
    # ...
    # ESS_CREDS = ...
    # ...
    return ''

  # Prevent caching everywhere
  @rest_api.after_request
  def add_header(r):
    r.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    r.headers['Pragma'] = 'no-cache'
    r.headers['Expires'] = '0'
    r.headers['Cache-Control'] = 'public, max-age=0'
    return r

  # Main program (instantiates and starts watcher threads and then web server)
  ess_listener = EssThread()
  ess_listener.start()
  rest_api.run(host=FLASK_BIND_ADDRESS, port=FLASK_PORT)



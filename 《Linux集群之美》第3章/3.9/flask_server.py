#!/usr/bin/env python

from gevent import monkey
monkey.patch_all()

from flask import Flask, request, abort, render_template
from werkzeug.exceptions import BadRequest
import gevent
import server
import paramiko
import logging
import os

logger = paramiko.util.logging.getLogger()
logger.setLevel(logging.INFO)

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/wssh/<hostname>/<username>')
def connect(hostname, username):
    #username = os.getenv('sshuser') if 'run' in request.args else username
    app.logger.debug('{remote} -> {username}@{hostname}: {container_id}'.format(
            remote=request.remote_addr,
            username=username,
            hostname=hostname,
            container_id=request.args['run'] if 'run' in request.args else
                '[interactive shell]'
        ))

    # Abort if this is not a websocket request
    if not request.environ.get('wsgi.websocket'):
        app.logger.error('Abort: Request is not WebSocket upgradable')
        raise BadRequest()

    bridge = server.WSSHBridge(request.environ['wsgi.websocket'])

    if 'run' in request.args:
        try:
             print os.getenv('sshuser')
             bridge.open(
                 hostname=hostname,
                 username=username,
                 # password=request.args.get('password'),
                 # Password default configuration option is None
                 password=None,
                 port=int(request.args.get('port')),
                 #private_key=request.args.get('private_key'),
                 private_key = '/home/{0}/.ssh/id_rsa'.format(username),
                 key_passphrase=request.args.get('key_passphrase'),
                 allow_agent=app.config.get('WSSH_ALLOW_SSH_AGENT', False))
        except Exception as e:
             app.logger.exception('Error while connecting to {0}: {1}'.format(
                 hostname, e.message))
             request.environ['wsgi.websocket'].close()
             return str()
        #container_id = request.args.get('run')
        container_id = request.args.get('run')
        #print container_id
        docker_command = "docker exec -ti {0} bash".format(container_id)
        #print docker_command
        bridge.execute(docker_command)
    else:
        # bridge = server.WSSHBridge(request.environ['wsgi.websocket'])
        try:
            bridge.open(
                hostname=hostname,
                username=username,
                password=request.args.get('password'),
                port=int(request.args.get('port')),
                #private_key=request.args.get('private_key'),
                # if private_key is None:
                private_key='/home/{0}/.ssh/id_rsa'.format(username),
                key_passphrase=request.args.get('key_passphrase'),
                allow_agent=app.config.get('WSSH_ALLOW_SSH_AGENT', False))
        except Exception as e:
            app.logger.exception('Error while connecting to {0}: {1}'.format(
                hostname, e.message))
            request.environ['wsgi.websocket'].close()
            return str()
        bridge.shell()

    # We have to manually close the websocket and return an empty response,
    # otherwise flask will complain about not returning a response and will
    # throw a 500 at our websocket client
    request.environ['wsgi.websocket'].close()
    return str()


if __name__ == '__main__':
    import argparse
    from gevent.pywsgi import WSGIServer
    from geventwebsocket.handler import WebSocketHandler
    from jinja2 import FileSystemLoader
    import os

    root_path = os.path.dirname(__file__)
    app.jinja_loader = FileSystemLoader(os.path.join(root_path, 'templates'))
    app.static_folder = os.path.join(root_path, 'static')

    parser = argparse.ArgumentParser(
        description='wsshd - SSH Over WebSockets Daemon')

    parser.add_argument('--port', '-p',
        type=int,
        default=5000,
        help='Port to bind (default: 5000)')

    parser.add_argument('--host', '-H',
        default='0.0.0.0',
        help='Host to listen to (default: 0.0.0.0)')

    parser.add_argument('--allow-agent', '-A',
        action='store_true',
        default=False,
        help='Allow the use of the local (where wsshd is running) ' \
            'ssh-agent to authenticate. Dangerous.')

    args = parser.parse_args()

    app.config['WSSH_ALLOW_SSH_AGENT'] = args.allow_agent

    #agent = 'wsshd/{0}'.format(wssh.__version__)
    agent = 'WSSH Terminal'

    print '{0} running on {1}:{2}'.format(agent, args.host, args.port)

    app.debug = True
    http_server = WSGIServer((args.host, args.port), app,
        log=None,
        handler_class=WebSocketHandler)
    try:
        http_server.serve_forever()
    except KeyboardInterrupt:
        pass

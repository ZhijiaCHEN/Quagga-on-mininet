import cgi
import http.server as SimpleHTTPServer
import SocketServer
from sys import stdout

PORT = 4537


class ServerHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):

    def createResponse(self, command):
        """ Send command string back as confirmation """
        self.send_response(200)
        self.send_header('Content-Type', 'application/text')
        self.end_headers()
        self.wfile.write(command)
        self.wfile.close()

    def do_POST(self):
        """ Process command from POST and output to STDOUT """
        form = cgi.FieldStorage(
            fp=self.rfile,
            headers=self.headers,
            environ={'REQUEST_METHOD': 'POST'})
        command = form.getvalue('command')
        stdout.write('%s\n' % command)
        stdout.flush()
        self.createResponse('Success: %s' % command)


handler = ServerHandler
httpd = SocketServer.TCPServer(('', PORT), handler)
stdout.write('serving at port %s\n' % PORT)
stdout.flush()
httpd.serve_forever()

import json
import threading
import unittest
from http.server import BaseHTTPRequestHandler, HTTPServer
from unittest import mock

import integration_hub_events as events
from integration_hub_events import client


class _Server:
    def __init__(self, statuses):
        self.statuses = list(statuses)
        self.requests = []
        outer = self

        class Handler(BaseHTTPRequestHandler):
            def do_POST(self):
                length = int(self.headers.get("Content-Length", 0))
                outer.requests.append((self.path, json.loads(self.rfile.read(length))))
                self.send_response(outer.statuses.pop(0))
                self.end_headers()

            def log_message(self, *args):
                pass

        self.httpd = HTTPServer(("127.0.0.1", 0), Handler)
        self.url = f"http://127.0.0.1:{self.httpd.server_port}"
        threading.Thread(target=self.httpd.serve_forever, daemon=True).start()

    def close(self):
        self.httpd.shutdown()
        self.httpd.server_close()


class SendTests(unittest.TestCase):
    def setUp(self):
        patcher = mock.patch.object(client.time, "sleep")
        patcher.start()
        self.addCleanup(patcher.stop)

    def serve(self, *statuses):
        server = _Server(statuses)
        self.addCleanup(server.close)
        env = mock.patch.dict("os.environ", {client.ENDPOINT_ENV_VAR: server.url})
        env.start()
        self.addCleanup(env.stop)
        return server

    def test_sends_empty_object_when_no_payload(self):
        server = self.serve(200)
        self.assertTrue(events.send("order.created"))
        self.assertEqual(server.requests, [("/events/order.created", {})])

    def test_sends_payload(self):
        server = self.serve(200)
        self.assertTrue(events.send("order.created", {"id": 1}))
        self.assertEqual(server.requests[0][1], {"id": 1})

    def test_retries_server_errors_then_succeeds(self):
        server = self.serve(503, 503, 200)
        self.assertTrue(events.send("e"))
        self.assertEqual(len(server.requests), 3)

    def test_does_not_retry_client_errors(self):
        server = self.serve(400)
        self.assertFalse(events.send("e"))
        self.assertEqual(len(server.requests), 1)

    def test_returns_false_after_retries_exhausted(self):
        server = self.serve(500, 500, 500)
        self.assertFalse(events.send("e"))
        self.assertEqual(len(server.requests), 3)

    def test_raise_on_failure(self):
        self.serve(400)
        with self.assertRaises(Exception):
            events.send("e", raise_on_failure=True)

    def test_missing_endpoint_fails_gracefully(self):
        with mock.patch.dict("os.environ", {}, clear=True):
            self.assertFalse(events.send("e"))


if __name__ == "__main__":
    unittest.main()

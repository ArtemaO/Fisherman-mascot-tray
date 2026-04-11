import http from 'node:http';

export function parseBridgeBody(body) {
  return JSON.parse(body);
}

export function startEventBridge(onEvent) {
  const server = http.createServer((request, response) => {
    if (request.method !== 'POST' || request.url !== '/events') {
      response.statusCode = 404;
      response.end();
      return;
    }

    const chunks = [];
    request.on('data', chunk => chunks.push(chunk));
    request.on('end', () => {
      try {
        const event = parseBridgeBody(Buffer.concat(chunks).toString('utf8'));
        onEvent(event);
        response.statusCode = 202;
        response.end('accepted');
      } catch (error) {
        response.statusCode = 400;
        response.end('bad request');
      }
    });
  });

  server.listen(43123, '127.0.0.1');
  return server;
}

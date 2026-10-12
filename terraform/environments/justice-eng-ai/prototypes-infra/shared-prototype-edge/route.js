import cf from 'cloudfront';

var prototypeRegistry = cf.kvs();

async function handler(event) {
    var request = event.request;
    var host = request.headers.host ? request.headers.host.value.toLowerCase() : '';
    var rejected = {statusCode: 404, statusDescription: 'Not Found'};
    if (!host || request.uri.charAt(0) !== '/') {
        return rejected;
    }

    var decoded;
    try {
        decoded = decodeURIComponent(request.uri);
    } catch (error) {
        return rejected;
    }
    if (/[\\%\x00-\x1f\x7f]/.test(decoded) || /(^|\/)\.{1,2}(\/|$)/.test(decoded)) {
        return rejected;
    }

    var prefix;
    try {
        prefix = await prototypeRegistry.get(host);
    } catch (error) {
        return rejected;
    }
    if (typeof prefix !== 'string' || !/^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$/.test(prefix)) {
        return rejected;
    }

    request.uri = '/' + prefix + request.uri;
    if (request.uri.charAt(request.uri.length - 1) === '/') {
        request.uri += 'index.html';
    }
    return request;
}

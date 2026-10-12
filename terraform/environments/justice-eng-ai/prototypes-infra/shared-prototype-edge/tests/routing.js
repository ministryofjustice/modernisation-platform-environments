function run(root) {
    var path = require('node:path');
    root = root || path.resolve(__dirname, '..');
    var source = require('node:fs').readFileSync(path.join(root, 'route.js'), 'utf8');
    source = source.replace("import cf from 'cloudfront';", '');
    var hosts = {
        '336344bc.ai-prototype.modernisation-platform.service.justice.gov.uk': '336344bc',
        'beta.ai-prototype.modernisation-platform.service.justice.gov.uk': 'beta'
    };
    for (var index = 0; index < 500; index++) {
        var prototypeId = 'build-' + index;
        hosts[prototypeId + '.ai-prototype.modernisation-platform.service.justice.gov.uk'] = prototypeId;
    }
    var mockCf = {
        kvs: function() {
            return {
                get: function(key) {
                    return Object.prototype.hasOwnProperty.call(hosts, key)
                        ? Promise.resolve(hosts[key])
                        : Promise.reject(new Error('Unknown hostname'));
                }
            };
        }
    };
    var handler = new Function('cf', source + '\nreturn handler;')(mockCf);
    var cases = [
        ['336344bc.ai-prototype.modernisation-platform.service.justice.gov.uk', '/', '/336344bc/index.html'],
        ['beta.ai-prototype.modernisation-platform.service.justice.gov.uk', '/', '/beta/index.html'],
        ['build-499.ai-prototype.modernisation-platform.service.justice.gov.uk', '/', '/build-499/index.html'],
        ['336344BC.AI-PROTOTYPE.MODERNISATION-PLATFORM.SERVICE.JUSTICE.GOV.UK', '/assets/main.css', '/336344bc/assets/main.css'],
        ['336344bc.ai-prototype.modernisation-platform.service.justice.gov.uk', '/folder/', '/336344bc/folder/index.html'],
        ['unknown.ai-prototype.modernisation-platform.service.justice.gov.uk', '/', 404],
        ['336344bc.ai-prototype.modernisation-platform.service.justice.gov.uk.evil.example', '/', 404],
        ['336344bc.ai-prototype.modernisation-platform.service.justice.gov.uk', '/../beta/index.html', 404],
        ['336344bc.ai-prototype.modernisation-platform.service.justice.gov.uk', '/%2e%2e/beta/index.html', 404],
        ['336344bc.ai-prototype.modernisation-platform.service.justice.gov.uk', '/%252e%252e/beta/index.html', 404],
        ['336344bc.ai-prototype.modernisation-platform.service.justice.gov.uk', '/%zz', 404],
        ['336344bc.ai-prototype.modernisation-platform.service.justice.gov.uk', '/%5c../beta/index.html', 404],
        ['336344bc.ai-prototype.modernisation-platform.service.justice.gov.uk', '/%00', 404],
        ['constructor', '/', 404],
        ['336344bc.ai-prototype.modernisation-platform.service.justice.gov.uk:443', '/', 404]
    ];
    return Promise.all(cases.map(async function(test) {
        var result = await handler({request: {
            uri: test[1],
            headers: {host: {value: test[0]}},
            querystring: {search: {value: 'one'}}
        }});
        var actual = result.statusCode || result.uri;
        if (actual !== test[2]) {
            throw new Error(JSON.stringify(test) + ': got ' + actual);
        }
        if (!result.statusCode && result.querystring.search.value !== 'one') {
            throw new Error('Query string changed');
        }
    })).then(async function() {
        var missingHost = await handler({request: {uri: '/', headers: {}}});
        if (missingHost.statusCode !== 404) {
            throw new Error('Missing host accepted');
        }
        return (cases.length + 1) + ' routing checks passed across 502 registered prototype hostnames';
    });
}

run(process.argv[2]).then(console.log).catch(function(error) {
    console.error(error);
    process.exitCode = 1;
});

exports.handler = (event, context, callback) => {
    const request = event.request;
    const host = request.headers.host ? request.headers.host.value : '';
    const uri = request.uri || '/';

    var redirectMap = {
        'dev.ahmlr.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/apply-land-registration-tribunal/overview',
            pathRedirects: [],
            aliases: []
        },
    };

    // Find matching config, checking aliases
    var redirectConfig = null;
    for (var domain in redirectMap) {
        if (host === domain || (redirectMap[domain].aliases && redirectMap[domain].aliases.includes(host))) {
            redirectConfig = redirectMap[domain];
            break;
        }
    }

    if (!redirectConfig) {
        return request; // Pass through for unsupported domains
    }

    for (const pathConfig of redirectConfig.pathRedirects) {
        for (const path of pathConfig.paths) {
            const isMatch = pathConfig.exactMatch
                ? uri.toLowerCase() === path.toLowerCase()
                : (path.startsWith('.*\\.') ? new RegExp(path, 'i').test(uri) : uri.toLowerCase().startsWith(path.toLowerCase()));
            if (isMatch) {
                const redirectUrl = pathConfig.exactMatch
                    ? pathConfig.target
                    : pathConfig.target.includes('$request_uri')
                        ? pathConfig.target.replace('$request_uri', uri)
                        : pathConfig.target + uri;
                return {
                    statusCode: 301,
                    statusDescription: 'Moved Permanently',
                    headers: {
                        'location': { value: redirectUrl }
                    }
                };
            }
        }
    }

    const defaultRedirectUrl = redirectConfig.defaultRedirect.endsWith('$request_uri')
        ? redirectConfig.defaultRedirect.replace('$request_uri', uri)
        : redirectConfig.defaultRedirect;
    return {
        statusCode: 301,
        statusDescription: 'Moved Permanently',
        headers: {
            'location': { value: defaultRedirectUrl }
        }
    };
}

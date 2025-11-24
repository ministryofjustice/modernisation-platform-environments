exports.handler = (event, context, callback) => {
    try {
        console.log('=== NONPROD FUNCTION START ===');
        console.log('Event type:', typeof event);
        console.log('Event keys:', Object.keys(event));

        const request = event.Records[0].cf.request;
        const host = request.headers.host[0].value || '';
        const uri = request.uri || '/';

        console.log('Host:', host);
        console.log('URI:', uri);

        var redirectMap = {
            'development.ahmlr.gov.uk': {
                defaultRedirect: 'https://www.gov.uk/apply-land-registration-tribunal/overview',
                pathRedirects: [
                    {
                        paths: ['/public', '/Admin', '/Judgments'],
                        target: 'https://landregistrationdivision.decisions.tribunals.gov.uk',
                        exactMatch: false
                    }
                ],
                aliases: []
            },
            'development.asylum-support-tribunal.gov.uk': {
                defaultRedirect: 'https://www.gov.uk/courts-tribunals/first-tier-tribunal-asylum-support',
                pathRedirects: [
                    {
                        paths: ['/Public', '/admin', '/Judgments', '/decisions.htm'],
                        target: 'https://asylumsupport.decisions.tribunals.gov.uk',
                        exactMatch: false
                    },
                    {
                        paths: ['.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                        target: 'https://administrativeappeals.decisions.tribunals.gov.uk',
                        exactMatch: false
                    }
                ],
                aliases: []
            },
            'preproduction.ahmlr.gov.uk': {
                defaultRedirect: 'https://www.gov.uk/apply-land-registration-tribunal/overview',
                pathRedirects: [
                    {
                        paths: ['/public', '/Admin', '/Judgments'],
                        target: 'https://landregistrationdivision.decisions.tribunals.gov.uk',
                        exactMatch: false
                    }
                ],
                aliases: []
            },
            'preproduction.asylum-support-tribunal.gov.uk': {
                defaultRedirect: 'https://www.gov.uk/courts-tribunals/first-tier-tribunal-asylum-support',
                pathRedirects: [
                    {
                        paths: ['/Public', '/admin', '/Judgments', '/decisions.htm'],
                        target: 'https://asylumsupport.decisions.tribunals.gov.uk',
                        exactMatch: false
                    },
                    {
                        paths: ['.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                        target: 'https://administrativeappeals.decisions.tribunals.gov.uk',
                        exactMatch: false
                    }
                ],
                aliases: []
            },

        };

        // Find matching config, checking aliases
        var redirectConfig = null;
        for (var domain in redirectMap) {
            console.log('Checking domain:', domain);
            if (host === domain || (redirectMap[domain].aliases && redirectMap[domain].aliases.includes(host))) {
                redirectConfig = redirectMap[domain];
                console.log('Matched domain:', domain);
                break;
            }
        }

        if (!redirectConfig) {
            console.log('No redirect config found for host:', host);
            callback(null, request);
            return;
        }

        for (const pathConfig of redirectConfig.pathRedirects) {
            for (const path of pathConfig.paths) {
                console.log('Checking path:', path);
                const isMatch = pathConfig.exactMatch
                    ? uri.toLowerCase() === path.toLowerCase()
                    : (path.startsWith('.*\\.') ? new RegExp(path, 'i').test(uri) : uri.toLowerCase().startsWith(path.toLowerCase()));
                if (isMatch) {
                    console.log('Path match found');
                    const redirectUrl = pathConfig.exactMatch
                        ? pathConfig.target
                        : pathConfig.target.includes('$request_uri')
                            ? pathConfig.target.replace('$request_uri', uri)
                            : pathConfig.target + uri;
                    callback(null, {
                        status: '301',
                        statusDescription: 'Moved Permanently',
                        headers: {
                            location: [{ key: 'Location', value: redirectUrl }]
                        }
                    });
                    return;
                }
            }
        }

        const defaultRedirectUrl = redirectConfig.defaultRedirect.endsWith('$request_uri')
            ? redirectConfig.defaultRedirect.replace('$request_uri', uri)
            : redirectConfig.defaultRedirect;
        console.log('Using default redirect:', defaultRedirectUrl);
        callback(null, {
            status: '301',
            statusDescription: 'Moved Permanently',
            headers: {
                location: [{ key: 'Location', value: defaultRedirectUrl }]
            }
        });
    } catch (error) {
        console.error('Error:', error);
        callback(null, {
            status: '500',
            statusDescription: 'Internal Server Error'
        });
    }
};
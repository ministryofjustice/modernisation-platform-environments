exports.handler = (event, context, callback) => {
    const request = event.request;
    const host = request.headers.host ? request.headers.host.value : '';
    const uri = request.uri || '/';

    var redirectMap = {
        'siac.tribunals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/appeal-to-the-special-immigration-appeals-commission',
            pathRedirects: [
                {
                    paths: ['/outcomes2007onwards.htm'],
                    target: 'https://siac.decisions.tribunals.gov.uk',
                    exactMatch: true
                }
            ],
            aliases: []
        },
        'fhsaa.tribunals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/appeal-to-the-primary-health-lists-tribunal',
            pathRedirects: [
                {
                    paths: ['/decisions.htm'],
                    target: 'https://phl.decisions.tribunals.gov.uk',
                    exactMatch: true
                }
            ],
            aliases: []
        },
        'estateagentappeals.tribunals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/estate-agents-appeal-against-a-ban-or-warning-order',
            pathRedirects: [
                {
                    paths: ['/decisions.htm'],
                    target: 'https://estateagentappeals.decisions.tribunals.gov.uk',
                    exactMatch: true
                }
            ],
            aliases: []
        },
        'consumercreditappeals.tribunals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/courts-tribunals/upper-tribunal-tax-and-chancery-chamber',
            pathRedirects: [
                {
                    paths: ['/decisions.htm'],
                    target: 'https://consumercreditappeals.decisions.tribunals.gov.uk',
                    exactMatch: true
                }
            ],
            aliases: []
        },
        'charity.tribunals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/appeal-against-a-charity-commission-decision-about-your-charity',
            pathRedirects: [
                {
                    paths: ['/decisions.htm'],
                    target: 'https://charity.decisions.tribunals.gov.uk',
                    exactMatch: true
                }
            ],
            aliases: []
        },
        'adjudicationpanel.tribunals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/organisations/hm-courts-and-tribunals-service',
            pathRedirects: [
                {
                    paths: ['/Public', '/Admin', '/Decisions', '/Judgments'],
                    target: 'https://localgovernmentstandards.decisions.tribunals.gov.uk',
                    exactMatch: false
                }
            ],
            aliases: []
        },
        'asylum-support-tribunal.gov.uk': {
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
        'ahmlr.gov.uk': {
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
        'dev.ahmlr.gov.uk': {
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
        'appeals-service.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/social-security-child-support-tribunal',
            pathRedirects: [],
            aliases: []
        },
        'carestandardstribunal.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/appeal-to-the-care-standards-tribunal',
            pathRedirects: [
                {
                    paths: ['/Public', '/images', '/Judgements', '/Admin'],
                    target: 'https://carestandards.decisions.tribunals.gov.uk',
                    exactMatch: false
                },
                {
                    paths: ['.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://cicap.decisions.tribunals.gov.uk',
                    exactMatch: false
                }
            ],
            aliases: []
        },
        'cicap.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/criminal-injuries-compensation-tribunal',
            pathRedirects: [
                {
                    paths: ['/Public', '/images', '/DBFiles', '/Admin', '.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://cicap.decisions.tribunals.gov.uk',
                    exactMatch: false
                }
            ],
            aliases: []
        },
        'civilappeals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/courts-tribunals/court-of-appeal-civil-division',
            pathRedirects: [],
            aliases: []
        },
        'cjit.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/organisations/ministry-of-justice$request_uri',
            pathRedirects: [],
            aliases: []
        },
        'cjs.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/organisations/ministry-of-justice$request_uri',
            pathRedirects: [],
            aliases: []
        },
        'cjsonline.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/organisations/ministry-of-justice$request_uri',
            pathRedirects: [],
            aliases: []
        },
        'complaints.judicialconduct.gov.uk': {
            defaultRedirect: 'https://www.complaints.judicialconduct.gov.uk$request_uri',
            pathRedirects: [],
            aliases: []
        },
        'courtfines.justice.gov.uk': {
            defaultRedirect: 'https://courtfines.direct.gov.uk$request_uri',
            pathRedirects: [],
            aliases: []
        },
        'courtfunds.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/contact-court-funds-office',
            pathRedirects: [],
            aliases: []
        },
        'criminal-justice-system.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/organisations/ministry-of-justice$request_uri',
            pathRedirects: [],
            aliases: []
        },
        'dugganinquest.independent.gov.uk': {
            defaultRedirect: 'https://webarchive.nationalarchives.gov.uk/20151002140003/http://dugganinquest.independent.gov.uk$request_uri',
            pathRedirects: [],
            aliases: []
        },
        'employmentappeals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/courts-tribunals/employment-appeal-tribunal',
            pathRedirects: [
                {
                    paths: ['/Public', '/images', '/Secure'],
                    target: 'https://employmentappeals.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                },
                {
                    paths: ['/Judgments/tips.htm'],
                    target: 'https://employmentappeals.decisions.tribunals.gov.uk/Judgments/tips.htm',
                    exactMatch: true
                },
                {
                    paths: ['/login.aspx'],
                    target: 'https://employmentappeals.decisions.tribunals.gov.uk/secure',
                    exactMatch: true
                },
                {
                    paths: ['.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://cicap.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                }
            ],
            aliases: []
        },
        'financeandtaxtribunals.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/collections/upper-tribunal-tax-and-chancery-chamber',
            pathRedirects: [
                {
                    paths: ['/aspx', '/Decisions', '/Admin', '/JudgmentFiles', '.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://financeandtax.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                }
            ],
            aliases: []
        },
        'hillsboroughinquests.independent.gov.uk': {
            defaultRedirect: 'https://webarchive.nationalarchives.gov.uk/20170404105742/https://hillsboroughinquests.independent.gov.uk$request_uri',
            pathRedirects: [],
            aliases: []
        },
        'immigrationservicestribunal.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/appeal-a-decision-on-your-registration-as-an-immigration-adviser',
            pathRedirects: [
                {
                    paths: ['/Aspx', '/Decisions', '/Admin', '/JudgmentFiles'],
                    target: 'https://immigrationservices.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                }
            ],
            aliases: []
        },
        'informationtribunal.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/information-rights-appeal-against-the-commissioners-decision',
            pathRedirects: [
                {
                    paths: ['/Public', '/images', '/DBFiles', '/Admin', '.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://informationrights.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                }
            ],
            aliases: []
        },
        'judicialombudsman.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/organisations/judicial-appointments-and-conduct-ombudsman$request_uri',
            pathRedirects: [],
            aliases: []
        },
        'landstribunal.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/appeal-upper-tribunal-lands',
            pathRedirects: [
                {
                    paths: ['/NEWstyles.css'],
                    target: 'https://landschamber.decisions.tribunals.gov.uk/NEWstyles.css',
                    exactMatch: true
                },
                {
                    paths: ['/Aspx', '/images', '/Decisions', '/Admin', '/JudgmentFiles', '.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://landschamber.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                }
            ],
            aliases: []
        },
        'obr.co.uk': {
            defaultRedirect: 'https://obr.uk$request_uri',
            pathRedirects: [],
            aliases: []
        },
        'osscsc.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/courts-tribunals/upper-tribunal-administrative-appeals-chamber',
            pathRedirects: [
                {
                    paths: ['/aspx', '/Decisions', '/Admin', '/JudgmentFiles', '.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://administrativeappeals.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                }
            ],
            aliases: []
        },
        'paroleboard.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/organisations/parole-board',
            pathRedirects: [],
            aliases: []
        },
        'sendmoneytoaprisoner.justice.gov.uk': {
            defaultRedirect: 'https://sendmoneytoaprisoner.service.justice.gov.uk$request_uri',
            pathRedirects: [],
            aliases: []
        },
        'transporttribunal.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/guidance/approved-driving-instructors-appeal-a-decision-by-the-registrar',
            pathRedirects: [
                {
                    paths: ['/Aspx', '/images', '/DBFiles', '/Admin', '.*\\.(css|js|png|ico|gif|jpg|jpeg)$'],
                    target: 'https://transportappeals.decisions.tribunals.gov.uk$request_uri',
                    exactMatch: false
                }
            ],
            aliases: []
        },
        'victiminformationservice.org.uk': {
            defaultRedirect: 'https://victimsinformationservice.org.uk$request_uri',
            pathRedirects: [],
            aliases: []
        },
        'yjbpublications.justice.gov.uk': {
            defaultRedirect: 'https://www.gov.uk/government/publications?departments[]=youth-justice-board-for-england-and-wales',
            pathRedirects: [],
            aliases: []
        }
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

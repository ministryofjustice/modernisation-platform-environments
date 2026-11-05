#!/usr/bin/env python3
"""Read-only development operations checks. Requires AWS CLI and SSO sessions.

No messages, alarms or objects are created. No credentials are printed.
"""
import argparse
import json
import subprocess
from pathlib import Path

API_ACCOUNT = '732169940576'
MFT_ACCOUNT = '346568122691'
PREFIX = 'integration-hub-api-file-transfer-api'
REGION = 'eu-west-2'


def aws(profile, *arguments):
    result = subprocess.run(['aws', *arguments, '--profile', profile, '--region', REGION,
                             '--output', 'json'], capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError('AWS read failed; check profile/account and read permissions')
    return json.loads(result.stdout)


def cleanup_rule_enabled(rules):
    # Prefix-specific rules are insufficient evidence for all API uploads.
    for rule in rules:
        filters = rule.get('Filter', {})
        global_filter = (not filters or filters == {'Prefix': ''}) and not rule.get('Prefix')
        days = rule.get('AbortIncompleteMultipartUpload', {}).get('DaysAfterInitiation')
        if rule.get('Status') == 'Enabled' and global_filter and type(days) is int and 0 < days <= 1:
            return True
    return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--api-profile', default='integration-hub-api-development')
    parser.add_argument('--mft-profile', help='SSO profile for current file-transfer development account, not the retired integration-hub account')
    parser.add_argument('--report', default='operations-results.json')
    args = parser.parse_args()
    results = []

    def record(case, result):
        row = {'case': case, 'result': result}
        results.append(row)
        print(json.dumps(row))
        Path(args.report).write_text(json.dumps({'development_only': True, 'results': results}, indent=2)+'\n')

    def check(case, condition):
        record(case, 'pass' if condition else 'fail')

    try:
        identity = aws(args.api_profile, 'sts', 'get-caller-identity')
        if identity['Account'] != API_ACCOUNT:
            raise RuntimeError('Wrong API account')
        record('api-profile-account', 'pass')
        alarms = aws(args.api_profile, 'cloudwatch', 'describe-alarms', '--alarm-name-prefix', PREFIX)['MetricAlarms']
        expected = {f'{PREFIX}-api-gateway-{name}' for name in ('5xx', '4xx', 'latency')}
        expected.update(f'{PREFIX}-{function}-{metric}' for function in ('upload-ticket', 'docs')
                        for metric in ('errors', 'throttles', 'duration'))
        by_name = {alarm['AlarmName']: alarm for alarm in alarms}
        check('expected-alarms-present', expected <= set(by_name))
        topics = set()
        for name in sorted(expected):
            alarm = by_name.get(name)
            actions = alarm.get('AlarmActions', []) if alarm else []
            check(name + '/actions-enabled', bool(actions) and alarm.get('ActionsEnabled', False))
            topics.update(a for a in actions if a.startswith('arn:aws:sns:'))
        for topic in sorted(topics):
            if not topic.startswith(f'arn:aws:sns:{REGION}:{API_ACCOUNT}:'):
                record('notification-topic-account', 'fail')
                continue
            attributes = aws(args.api_profile, 'sns', 'get-topic-attributes', '--topic-arn', topic)['Attributes']
            check('notification-topic-confirmed-subscriber', int(attributes.get('SubscriptionsConfirmed', '0')) > 0)
            check('notification-topic-encrypted', bool(attributes.get('KmsMasterKeyId')))
        ttl = aws(args.api_profile, 'dynamodb', 'describe-time-to-live', '--table-name', PREFIX+'-multipart-uploads')['TimeToLiveDescription']
        check('session-ttl', ttl.get('TimeToLiveStatus') == 'ENABLED' and ttl.get('AttributeName') == 'expires_at_epoch')
        routes = aws(args.api_profile, 'apigatewayv2', 'get-routes', '--api-id', '5yc80qz674')['Items']
        upload = [route for route in routes if '/transfer-tickets' in route['RouteKey']]
        check('jwt-on-all-four-upload-routes', len(upload) == 4 and all(r.get('AuthorizationType') == 'JWT' for r in upload))
        stage = aws(args.api_profile, 'apigatewayv2', 'get-stage', '--api-id', '5yc80qz674', '--stage-name', '$default')
        limits = stage.get('DefaultRouteSettings', {})
        check('gateway-nonzero-rate-and-burst', limits.get('ThrottlingRateLimit', 0) > 0 and limits.get('ThrottlingBurstLimit', 0) > 0)
    except (RuntimeError, KeyError, ValueError):
        record('api-operations-read', 'unverified')
    if args.mft_profile:
        try:
            identity = aws(args.mft_profile, 'sts', 'get-caller-identity')
            if identity['Account'] != MFT_ACCOUNT:
                raise RuntimeError('Wrong current MFT account')
            rules = aws(args.mft_profile, 's3api', 'get-bucket-lifecycle-configuration',
                        '--bucket', 'integration-hub-file-transfer-development-incoming')['Rules']
            check('incoming-abandoned-multipart-cleanup', cleanup_rule_enabled(rules))
        except (RuntimeError, KeyError, ValueError):
            record('incoming-cleanup-read', 'unverified')
    else:
        record('incoming-cleanup-read', 'unverified')
    record('notification-delivery-and-recovery', 'unverified')
    record('observed-expired-session-cleanup', 'unverified')
    return 1 if any(r['result'] == 'fail' for r in results) else 2


if __name__ == '__main__':
    raise SystemExit(main())

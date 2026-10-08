# Shared prototype edge

The `justice-eng-ai/web-ui` component owns one CloudFront distribution and one
CloudFront-scope WAF web ACL per workspace as the default edge for static AI
prototype builds. Static prototypes use separate subdomains and object prefixes
in one private S3 bucket. Creating a prototype does not create another distribution,
ACL, certificate or DNS record.

## Configuration and Ownership

The `web-ui` root looks up the public `ai-prototype.modernisation-platform.service.justice.gov.uk`
hosted zone and the most recent issued ACM certificate for that domain in
`us-east-1`. The certificate must cover
`*.ai-prototype.modernisation-platform.service.justice.gov.uk`; the hosted zone
must be visible and writable to the `web-ui` member-account provider. If either
resource is in another account or the certificate is absent, planning fails at the
lookup instead of requiring copied IDs in component configuration.

The edge WAF reuses `var.allowed_ingress_cidrs` from the same `web-ui` root. There
is no second CIDR list or cross-state output dependency. This means the prototypes
share the Builder and Forge UI's existing MoJ GlobalProtect / Prisma Access access
policy. Prototype IDs may begin with digits, as in `336344bc`.

The bucket prefix is `justice-eng-ai-prototypes`; the bucket module appends the
AWS account and region to make the final name unique. Builder and Forge keep their
existing exact DNS records; the wildcard record serves registered prototype
subdomains, and exact DNS records take precedence. Static prototypes use separate
subdomains and object prefixes in the private shared bucket.

Run a reviewed plan and apply through the environments repository workflow in the
matching `justice-eng-ai` `web-ui` workspace. The existing component backend
provides remote state and locking. The `shared_prototype_edge` output provides the shared bucket,
distribution ID, WAF ARN, KeyValueStore ARN, and URL/prefix templates. Prototype
IDs are not a Terraform list: the publishing workflow registers each build in the
KeyValueStore using the full hostname as the key and its S3 prefix as the value.
This allows hundreds of prototypes without growing or redeploying the routing
function. Publishing those identifiers to SSM and granting scoped Application
Builder permissions to update the KeyValueStore and its own S3 prefix remain
follow-up integration work.

The bucket uses the Modernisation Platform S3 module with account-regional naming,
BucketOwnerEnforced ownership, versioning and SSE-S3 (AES256), matching the existing
static-origin encryption. Its policy allows object reads only from this
CloudFront distribution's OAC and enforces TLS. Noncurrent object versions expire
after 30 days; current prototype files are not expired automatically. Destroying
the module does not delete bucket contents.

## Routing and isolation

- Wildcard Route53 DNS points to the shared distribution. The bare parent domain
  is not published.
- A viewer-request CloudFront function accepts only registered hostnames and
  rewrites `/assets/main.css` on
  `336344bc.ai-prototype.modernisation-platform.service.justice.gov.uk` to
  `/336344bc/assets/main.css` before cache lookup. Prototype prefixes therefore
  separate cache entries, even though viewer Host is not in the cache key.
- `/` and directory URLs map to `index.html` within that prototype's prefix.
  There is no global SPA fallback; missing objects retain their error status.
- Unknown hosts and malformed or traversal paths return 404 without reaching S3.
- S3 has public access blocked and grants read access only to this distribution
  through signed origin access control. Deployment roles still need scoped writes.
- Only IPv4 access is published. WAF blocks clients outside the allowed CIDRs
  before applying common-threat and known-bad-input managed rules. Allowed IPs do
  not bypass those security rules. A shared per-IP limit is 2,000 requests per
  five-minute window; assess this against traffic from shared corporate NATs.
- WAF logs have 30-day retention and redact cookies, Authorization, and query
  strings. Request sampling is disabled because log redaction does not protect
  samples. CloudFront access logging is not configured by this module.

Subdomains provide browser-origin separation, not complete tenant isolation or user
authentication. Keep prototype cookies host-only; never set a shared parent-domain
cookie. Do not host sensitive data or untrusted multi-tenant workloads here without
the appropriate authentication, authorisation, retention and content policies.

The hostname registry lives in CloudFront KeyValueStore, separate from function
code. Register a prototype by writing
`336344bc.ai-prototype.modernisation-platform.service.justice.gov.uk` as the key
and `336344bc` as the value. Retire it by deleting that key. KVS updates propagate
to CloudFront edge locations, so the publisher must handle propagation before
reporting a new preview as ready. Adding or removing hostnames does not redeploy
the function or distribution. Never manage this distribution from multiple
Terraform states.

## Publish and retire

1. The publishing workflow registers the approved hostname in the shared
   KeyValueStore through its authenticated AWS API. Do not derive S3 prefixes from
   untrusted viewer headers or let builds change other infrastructure.
2. Upload the static bundle, with an `index.html` at its root, to the registered
   output prefix:

   ```bash
   aws s3 sync ./build/application/ s3://YOUR-SHARED-BUCKET/336344bc/
   aws cloudfront create-invalidation \
     --distribution-id YOUR-SHARED-DISTRIBUTION-ID \
    --paths '/336344bc/*'
   ```

   Restrict the publisher's S3 permissions to its assigned prefix. Serve assets
   from the prototype hostname, not the bucket URL. Cookies and query strings are
   not forwarded to S3; this is static hosting, not a backend or authenticated API.

3. Verify the subdomain, assets, denied networks, direct S3 denial and separation
   between two prototype hostnames before sharing the URL.
4. Retire a prototype by removing its hostname from the registry first. The
   viewer-request rejection also runs before serving cached objects. Then delete
   its objects and versions according to retention policy. This module retains
   bucket contents and does not force-delete them on destroy.

For migration, publish and verify content on the shared edge before moving users.
An exact existing DNS record takes precedence over the wildcard; remove or update
it deliberately. An alias already attached to an old CloudFront distribution must
be transferred using AWS's supported alternate-domain migration process before
cutover. Retain old endpoints for rollback until the new route is verified, then
remove per-prototype edge resources from their owning Terraform states.

## Generation and Forge integration gates

This change provides shared **static hosting**, not an automatic migration of the
inherited deployment pipeline. The legacy infrastructure generation prompt and
example still request per-prototype CloudFront and WAF. All AI prototype builds
must use the shared edge; the legacy per-prototype edge flow is not a supported
fallback. The build handoff must publish bundles to the assigned S3 prefix and
register approved hostnames in KVS, while policy validation rejects generated edge
resources. That integration remains outstanding; this infrastructure alone does
not redirect existing builds. Keep generated application state separate from the
shared edge state.

Forge is not connected to this distribution. Its current private runtime requires
a server-side service token and has process-local build/session state. Do not put
that token into CloudFront code, public headers, browser URLs, or this Terraform
configuration. Connecting it requires an authenticated server-side preview gateway,
an explicit hostname-to-build registry, private runtime access, durable build/session
storage, and a separate uncached dynamic behaviour or platform router. Review the
runtime deployment gates in the Application Builder repository's Forge README
before exposing it. Static output
from any generator can use this S3 hosting once packaged as a static bundle.

Sharing WAF reduces duplicated ACL and rule charges. Standard usage-based
CloudFront distributions do not each have a fixed monthly charge; traffic,
CloudFront function invocations, logging, storage and invalidations still cost money.

## Local checks

No AWS resources are created by these checks. Mock-provider tests require Terraform
1.7 or later. Routing tests require Node.js and no additional packages.

```bash
cd terraform/environments/justice-eng-ai/web-ui/shared-prototype-edge
terraform init -backend=false
terraform test
node tests/routing.js
```

On macOS without Node.js, run the same routing checks with the system JavaScript
engine:

```bash
docker run --rm -v "$PWD:/work:ro" -w /work node:22-alpine node tests/routing.js /work
```

Validate the actual component caller from `terraform/environments/justice-eng-ai/web-ui`
with `terraform init -backend=false` and `terraform validate`. Standalone module
validation needs a caller to configure the aliased provider; the Terraform tests
above supply mock providers and create no AWS resources.

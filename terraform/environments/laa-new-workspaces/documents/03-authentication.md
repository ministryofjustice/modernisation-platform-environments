# 3. Authentication

Two sequences: a WorkSpaces login with RADIUS-backed MFA, and the self-service
portal a user visits once to enroll their MFA token.

## WorkSpaces login + MFA challenge

```mermaid
sequenceDiagram
    participant U as User
    participant WS as WorkSpaces Directory
    participant AD as Microsoft AD
    participant NLB as Internal NLB (UDP 1812)
    participant RAD as FreeRADIUS (ECS)
    participant LOTP as LinOTP (ECS :5000)
    participant DB as RDS MySQL

    U->>WS: connect via VPN (IP allow-list)
    U->>WS: AD username + password
    WS->>AD: bind / validate credentials
    AD-->>WS: credentials OK
    AD->>NLB: RADIUS Access-Request (PAP, shared secret)
    NLB->>RAD: forward UDP:1812
    RAD->>LOTP: HTTP /validate/simplecheck (OTP)
    LOTP->>AD: LDAP lookup (ad-resolver, realm laa-workspaces)
    LOTP->>DB: check OTP against token seed
    DB-->>LOTP: token record
    LOTP-->>RAD: accept / reject
    RAD-->>NLB: RADIUS Access-Accept/Reject
    NLB-->>AD: result
    AD-->>WS: MFA result
    WS-->>U: session granted / denied
```

## Self-service MFA enrollment

```mermaid
sequenceDiagram
    participant U as User (browser)
    participant ALB as ALB radmfa (HTTPS:443)
    participant LOTP as LinOTP portal (:5000)
    participant AD as Microsoft AD
    participant DB as RDS MySQL

    U->>ALB: HTTPS request, Global Protect VPN CIDR only
    ALB->>LOTP: forward :5000
    U->>LOTP: log in with AD credentials
    LOTP->>AD: LDAP bind (ad-resolver)
    AD-->>LOTP: authenticated
    U->>LOTP: enroll MFA token
    LOTP->>DB: store token seed (encrypted)
    DB-->>LOTP: stored
    LOTP-->>U: enrollment complete
```

## Key facts

| | |
|---|---|
| **Primary auth** | AD username/password, validated by the WorkSpaces Directory against `laa-workspaces.local` |
| **MFA transport** | RADIUS PAP over UDP 1812, shared secret held in Secrets Manager, 3 retries / 5s timeout |
| **Portal access control** | ALB only accepts 443/80 from the Global Protect Alpha VPN CIDR range — not open to the internet |
| **NLB health check quirk** | NLB can't health-check UDP directly, so it polls LinOTP's HTTP port 5000 instead |

[← Data Flow](02-data-flow.md) · [Back to index](README.md)

apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-${env}
spec:
  acme:
    # The ACME server URL
    server: ${acme_server}
    # Email address used for ACME registration
    email: platforms@digital.justice.gov.uk
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-${env}
    # Enable the DNS-01 challenge provider
    solvers:
    - selector: {}
      dns01:
        cnameStrategy: "Follow"
        # Here we define a list of DNS-01 providers that can solve DNS challenges
        route53: {} 
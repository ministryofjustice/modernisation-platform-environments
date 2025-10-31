locals {

  external_cidrs = {

    syscon = [
      "213.86.134.219/32", # victoria street
      "206.191.12.18/32"   # failover
    ]

    capita_jumpbox = "10.0.1.18"

    # See DSO-420
    sodeco = [
      "51.148.9.201/32",
      "51.155.85.249/32",
      "51.148.47.137/32",
      "51.155.55.241/32"
    ]
    interserve = [
      "46.227.51.224/29",
      "46.227.51.232/29",
      "46.227.51.240/28",
      "51.179.196.131/32"
    ]
    meganexus = [
      "51.179.210.36/32",
      "83.151.209.178/32",
      "83.151.209.179/32",
      "213.105.186.130/31",
      "49.248.250.6/32"
    ]
    serco = [
      "217.22.14.0/24",
      "18.135.54.44/32",
      "18.175.105.241/32",
      "35.177.142.157/32",
      "128.77.110.45/32",
    ]
    rrp = [
      "62.253.83.37/32"
    ]
    eos = [
      "5.153.255.210/32"
    ]
    oasys_sscl = [
      "62.6.61.30/32",
      "195.206.180.12/32" # elearning
    ]
    dtv = [
      "51.179.197.1/32" # replace arc
    ]
    # https://mojdt.slack.com/archives/C6D94J81E/p1577103443039500
    nps_wales = [
      "51.179.199.82/32"
    ]
    #https://mojdt.slack.com/archives/C6D94J81E/p1633014344325000
    #https://dsdmoj.atlassian.net/browse/DSO-1395
    dxw = [
      "54.76.254.148/32" #dxw VPN Endpoint - eu-west-1 on an ec2 isntance using strongswan
    ]
    bsi_pentesting = [
      "54.37.241.156/30",
      "167.71.136.237/32"
    ]

    # Public IPs of the Cloud Platform NAT Gateways in AWS. There's a NAT
    # Gateway in each of the three availability zones.
    #
    # Source:
    # https://user-guide.cloud-platform.service.justice.gov.uk/documentation/networking/ip-filtering.html#outbound-ip-filtering
    cloud_platform = [
      "35.178.209.113/32",
      "3.8.51.207/32",
      "35.177.252.54/32",
    ]
  }
}

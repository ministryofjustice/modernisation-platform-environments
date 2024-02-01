#### This file can be used to store locals specific to the member account ####
locals {

  developer_cidr_ipv6s = [
    # Pen tester
    "2001:8b0:13dc::/48",
    "2a05:d01c:e83:b500::/64",
    "2a05:d01c:e83:b500:f25:37ec:29e9:4b6e",
    "2603:1020:700:2::e2"
  ]

  developer_cidr_ipv4s = [
    # Pen tester
    "90.155.48.192/26",
    "81.2.127.144/28",
    "81.187.169.170",
    "88.97.60.11",
    "13.42.192.167",
    "51.104.217.191",
    # fy nhy
    "46.69.144.146/32",
    # Petty France
    "81.134.202.29/32"
  ]

  developer_ssh_keys = [
    # Pen tester
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDE9c0YBOGrtSqz0JX2Z4bBP2I1nPCt8XMgE80p7iPQ7wBd5bHTTp5uMhwXkInNjffWq6d6BcDU71Ri+MRYYg4WsLi4oRSvY4FQdu6ejMcNA59GYFkFI/tIERPJ5eiYNPAY9GcrVQJTrxClma9cDpEaRPsOdJ16sZfjEVcic6Fak/Vv7Quj7smfVB6jAXBGhRM9O8iEZIW2uJnECNBbuzxJV+MSZDRpGNBP7T/QYalodnpUSpYxMGrLjqMzXb1AjYqAnO1Aj9HfDq0cAMujWs+Il4zFVfr5qn/hYRL1ozZ17n53XzKwkYD7jelQX0tfDepEbWdzQ/7qj70w1WGDR9N7v9ya7T8v27JazTO43V96QMlYORvLLMieO/d0O6wiWhDi3wf2Ig4ZWBao4GtdSotPNnmUZZW/4Ozg1QaS6IHkbLwmGOTgc/HmvggIlZdb6hJLjQGDYhflg+cH9aiudFOiu6DY/J9DprtzAFeFaOTuU1J8uqqP0OZNZq0SPt5bUHs=",
    # Matt Price
    "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBA3BsCFaNiGxbmJffRi9q/W3aLmZWgqE6QkeFJD5O6F4nDdjsV1R0ZMUvTSoi3tKqoAE+1RYYj2Ra/F1buHov9e+sFPrlMl0wql6uMsBA1ndiIiKuq+NLY1NOxEvqm2J9Q==",
    # Matt Heery
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClyRRkvW162H2NQm5IlavjE4zBhnzGJ/V+raqe7ynPumIgKhmNto8GD6iKlWkzLGxfwXQhONM/9J8+u9tqncw5FzEWEYdX/FEJF5VwLYma/OtMUio3vtwsc9zbae4EyTvROvbJSMgL07ZicUjQ9pS4+pst2KVjDtgCXD8l7A66wOkmht2Cb2Ebfk+wk965uN5wE5vHDQBx6QQ4z9UiGEp34n/g2O9gUGUJcFdYCEHVl1MY+dicCJwsRzEC1a0s/LzCtiCo66yWW8VEpMpDJNCAJccxadwWBI1d+8R94LTUakxkYhAVCpzs+A/qjaAUKsT/1KQm0+3gJIfLqmWYUumB4VgP2+cYiFbdxWQt2lLAUYZmsTwR5EktCftA5OGcwKO11sKnouj+IYiN9wfRl8kQEs+KZDDSjXKAdsWvRwhRMbBZdLqIzO2InyLCQaujZqMupMh5KkmrhL9eYFn0qtWSG274vnmUacvaIl1e8EmIb9j5ksyVXysPlIVxbNks51E= matt.heery@MJ004484"
  ]

}
# Kingsly

<p align="center">
  <a href="https://travis-ci.org/gojekfarm/kingsly"><img src="https://travis-ci.org/gojekfarm/kingsly.svg?branch=master" alt="Build Status"></img></a>
</p>


An attempt to automate SSL certs management. This Cert manager helps generate SSL certs, renews them automatically (WIP: #1) and tracks if the client has the updated certs (WIP: #2)

#### Assumptions

- The FQDN points to a public IP address
- An FQDN points to only one IP address

## Dev Setup

- Install all dependencies: `bundle install`
- Copy config: `cp config/application.yml.sample config/application.yml`
- Edit file `config/application.yml` with relevant config
- Run migrations: `rake db:create db:migrate`
- Start server: `rails server`

## Example APIs

- Creating SSL certs for a domain:
  - Request:
```
curl -X POST http://kingsly.host/v1/cert_bundles \
  -u admin:password \
  -H 'Content-Type: application/json' \
  -d '{
        "top_level_domain":"your-domain.com",
        "sub_domain": "your-sub-domain"
    }'
```
  - Response:

```
'{
  "private_key":"-----BEGIN RSA PRIVATE KEY-----\nMI...\n-----END RSA PRIVATE KEY-----\n",
  "full_chain":"-----BEGIN CERTIFICATE-----\nMIIG...\n-----END RSA PRIVATE KEY-----\n"
}'
```

## TODO

- check for ACME account creation without email id (maybe initialize account only once?)

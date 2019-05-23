## k8s deployment

We currently have an example of exposing the kingsly server [service](https://kubernetes.io/docs/concepts/services-networking/service/)
using [GLB as ingress](https://cloud.google.com/kubernetes-engine/docs/tutorials/http-balancer), the only requirements for it being 
- a postgresql instance which it can connect to, so that it can store the certs over there.
- your letsencrypt credentials.
- AWS account credentials, for creation of route53 entries to complete DNS challenge for letsencrypt.

### Values which need to be changed/added in the sample manifests

- Add the value for your tls.crt and tls.key which has the placeholder value of `mytlscrt==` and `mytlskey==` respectively in the example deployment docs. 
- Change the value of the `host` key from `kingsly.example.com` to the one where you have hosted kingsly. 

### Setup

- Provision a [GKE cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster)

```
$ git clone git@github.com:gojekfarm/kingsly
$ cd kingsly/docs/deploy
$ kubectl apply -f k8s/
```

### What is happening when you do a `kubectl apply -f k8s/`

- A plain [ingress object](https://kubernetes.io/docs/concepts/services-networking/ingress/) is being created for your service
  - GCP sets up GLB using the GKE ingress controller.
  - If no ingress controller is defined in the annotations, GLB acts as the ingress controller. In this case:
    - GLB will act as an API gateway for all incoming traffic
    - GLB will do SSL termination, and do host-name or path based routing.
    - IAP is only supported in this configuration. (more on it later in this doc)
- You should be able to see a GLB of type HTTP(S) here: https://console.cloud.google.com/net-services/loadbalancing/loadBalancers/list
- The service running the application should be running with `type: NodePort`
- **NOTE:** GLB must detect the application endpoint as healthy. By default, the health-check path used by GLB is `/`. To override this, specify a `readinessProbe` in deployment spec of your application.
- We are storing the SSL certs as secrets present in the manifest `kingsly-tls-secret.yaml`
- Point your app's domain to Public IP of GLB.

### Variables in `kingsly-server-configmap.yaml` to be changed

- `ACME_CLIENT_CONTACT`: Used by letsencrypt to notify when the cert created by letsencrypt is about to expire. 
- `ACME_CLIENT_DIR`: Can be either `https://acme-v02.api.letsencrypt.org/directory` or `https://acme-staging-v02.api.letsencrypt.org/directory` depending on whether you want certs for testing or for production usage. 
- `ACME_KID`: ACME account ID
- `AWS_ACCESS_KEY_ID`: AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key
- `CERT_BUNDLE_EXPIRY_BUFFER_IN_DAYS`: Time in days left for the cert bundle to expire when it will be considered for recreation by kingsly
- `CERT_BUNDLE_RENEWAL_PERIOD_IN_SECONDS`: Time in seconds which would be considered by the kingsly-worker deployments to check for certs to be renewed(recreated)
- `DB_HOST`: A resolvable hostname/DNS entry/IP for the postgres instance.
- `DB_NAME`: postgres DB name which has been created. 
- `DB_USERNAME`: postgres DB username.
- `DB_PASSWORD`: postgres DB password for the user `DB_USERNAME`
- `PASSWORD`: basic auth password
- `USERNAME`: basic auth username
- `RAILS_MASTER_KEY`: Read https://guides.rubyonrails.org/security.html#custom-credentials

## Enabling Access only from whitelisted IPs

We made a conscious choice to separate authentication and authorisation to be handled by kingsly itself and let someone else handle it. 

A very simple way to whitelist would be to put a simple HAproxy in front of kingsly server which would have an updated list of whitelisted IP's from where it would forward the requests to the kingsly server. 

Or you can use IAP too if your services are being hosted in GCP. 

#### Enabling IAP for kingsly

- (You need to be owner of GCP for this step) Enable IAP for `default/my-service` backend here: https://console.cloud.google.com/security/iap
  - When prompted, enter the URL `my-service.example.com` as authorized URLs
- Add yourself as a member with role `IAP-secured Web App User` from side panel of IAP
- Visit `https://my-service.example.com` to access your app
- To access any app using a service account, authorize it for the IAP resource, then hit a curl following the steps here: [https://github.com/b4b4r07/iap_curl](https://github.com/b4b4r07/iap_curl). GCP official doc [here](https://cloud.google.com/iap/docs/authentication-howto#iap_make_request-python)

### Extra layer of security

- In your application behind Gcloud IAP, it is advisable to check the headers added by Gcloud IAP. Details [here](https://cloud.google.com/iap/docs/identity-howto)

## Resources

- https://stackoverflow.com/questions/21440709/how-do-i-get-aws-access-key-id-for-amazon
- https://cloud.google.com/iap/

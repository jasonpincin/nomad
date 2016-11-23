Something like:

```bash
eval $(triton env)
# Provision a Nomad cluster
./provision-nomad-server
./provision-nomad-client
./provision-nomad-client
./provision-nomad-client

# Update environment
MY_IP=$(curl http://ipinfo.io/ip) \
INSTANCE_ID=$(triton instance get nomad-server-1 | json id) \
triton fwrule create \
    "FROM ip ${MY_IP} TO vm ${INSTANCE_ID} ALLOW tcp (PORT 4646 AND PORT 4647 AND PORT 8500)"
export NOMAD_ADDR="http://$(triton ip nomad-server-1):4646"

# Run some jobs
nomad run images/test-service/job.hcl
nomad run images/app-router/job.hcl

# Monitor their status:
nomad status test-service
nomad status app-router
```

Eventually, `nomad status app-router` will show an entry under `Allocations`
with a status of `running`. There will be a `Node ID`, which you can
cross-reference via the command `nomad node-status` to get the name of the
Triton instance. If, for example, it's `nomad-client-1`, then you can use the
following command to test the app router:

```bash
curl $(triton ip nomad-client-1)/test-service/
```

To verify all upstreams have been configured:

```bash
ssh ubuntu@$(triton ip nomad-client-1) "cat /etc/nginx/nginx.conf"
```

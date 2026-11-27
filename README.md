# tsidp

[tsidp](https://github.com/tailscale/tsidp) template for Runway. OIDC
identity provider backed by Tailscale: log in to your apps with the
Tailscale accounts your team already has.

Single instance with state on a volume. tsidp v0.0.21.

**tsidp is its own Tailscale node.** It is not served by Runway's router,
but at `https://<hostname>.<tailnet-name>.ts.net` on your tailnet.

> [!WARNING]
> tsidp is experimental software by Tailscale. APIs and behaviour may change.

> [!TIP]
> Found a problem, or have an idea for this template?
> [Open an issue](https://github.com/runway-templates/schema/issues/new/choose) in the schema repository.
> Issues for all templates are tracked there. Pull requests are welcome right here.

## Before you deploy

These steps are in Tailscale, so the template cannot do them for you:

1. Turn on [MagicDNS](https://tailscale.com/docs/features/magicdns/) and
   [HTTPS](https://tailscale.com/docs/how-to/enabling-https) for your tailnet.
2. Create the tag `tag:tsidp` in the
   [access controls](https://login.tailscale.com/admin/acls), owned by
   `autogroup:admin`.
3. Create an [auth key](https://login.tailscale.com/admin/settings/keys)
   with `tag:tsidp`.
4. Allow your users to open the admin UI. Add this grant to your tailnet
   policy:

   ```json
   "grants": [
     {
       "src": ["autogroup:member"],
       "dst": ["tag:tsidp"],
       "app": {
         "tailscale.com/cap/tsidp": [{"allow_admin_ui": true}]
       }
     }
   ]
   ```

## Deploy

Deploy tsidp with one click [from your browser](https://ui.runway.horse/deploy/templates),
or with the Runway CLI:

```sh
runway app create --app=my-tsidp --plan=free-launch
runway app deploy template --app=my-tsidp --template=tsidp ts_authkey=tskey-auth-...
```

To change another [input](#inputs), add it as `key=value` at the end of the second command.

## Inputs

| Input | Default | Notes |
| --- | --- | --- |
| `ts_authkey` | none, required | Auth key with `tag:tsidp`. Only used on the first start |
| `hostname` | `idp` | Name on your tailnet. Part of the issuer URL, so pick it once |
| `funnel` | `false` | Serve tsidp on the public internet, see [Funnel](#funnel) |
| `image_tag` | `v0.0.21` | tsidp version |

## Outputs

None. The URL depends on your tailnet name, which Runway does not know.

## Connecting

This one is **not** routed. tsidp is served on your tailnet:

```
https://<hostname>.<tailnet-name>.ts.net
```

The first start can take a few minutes, until Tailscale has issued the TLS
certificate.

Open the URL in a browser on your tailnet and register an OIDC client for
your app. Then set up your app with:

- Issuer: `https://<hostname>.<tailnet-name>.ts.net`
- the `client_id` and `client_secret` of the new client

Without Funnel, your app must be on the tailnet too, to reach tsidp. See
the [Tailscale guide](https://www.runway.horse/docs/guides/tailscale/tsidp/)
for examples with a Go app and Grafana.

## Funnel

With Funnel, apps and SaaS products outside your tailnet can reach tsidp.
Users still need Tailscale running to log in.

Give `tag:tsidp` the `funnel` attribute in your tailnet policy first:

```json
"nodeAttrs": [
  {
    "target": ["tag:tsidp"],
    "attr": ["funnel"]
  }
]
```

Then deploy with `funnel=true`. On a running app, deploy the template
again with the same inputs and `funnel=true`.

## Notes

- **The auth key is only used once.** After the first start, the node
  state is on the volume. A one-time key is fine. Tagged nodes do not
  expire.
- **Keep the volume.** It holds the node state and all registered OIDC
  clients. Without it, tsidp joins your tailnet as a new node and every
  client is gone.
- **Do not change `RUNWAY_TS_MANAGED`.** It turns off Runway's own
  Tailscale sidecar, so tsidp gets the `TS_*` variables itself.
- **OAuth client secrets** (`tskey-client-...`) work as `ts_authkey` too,
  but tsidp then needs `TS_ADVERTISE_TAGS=tag:tsidp`. Set it with
  `runway app config set` before you deploy.
- **Token exchange (STS)** is on. Who may use it is set by the capability
  grant in your tailnet policy; see the
  [tsidp README](https://github.com/tailscale/tsidp#setting-an-application-capability-grant).
- **No healthcheck.** tsidp has no port in the pod to probe. Check
  `runway app logs --app <app>` if the URL does not come up.
- **Runs with lockdown.** tsidp only writes to `/data`.
- Uses about 15 MB RAM when idle, so it fits the free plan.

## License

tsidp is BSD-3-Clause. This template is maintained by Runway.

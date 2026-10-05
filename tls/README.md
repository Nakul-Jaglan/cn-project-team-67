# TLS setup — private CA and server certificate

The edge presents a certificate issued by a team-owned local CA. Clients trust the CA once, after which `curl` and browsers verify the edge without `-k`.

## What exists

| Object | Subject | Key | Validity (GMT) | In repo |
|---|---|---|---|---|
| CA certificate | `CN=Team67 Phase1 Local CA` (self-signed, `CA:TRUE`) | RSA 4096 | 5 Oct 2026 – 7 Jan 2029 | [`certs/phase1-ca.crt`](certs/phase1-ca.crt) |
| Server certificate | `CN=app.team67.test`, issued by the CA | RSA 2048 | 5 Oct 2026 – 5 Oct 2027 | [`certs/app.team67.test.crt`](certs/app.team67.test.crt) |
| Private keys, CSR, serial file | — | — | — | **No.** Kept on Mac 2 only |

Server certificate extensions (from [`server-san.cnf`](server-san.cnf)):

- `subjectAltName = DNS:app.team67.test, DNS:api.team67.test`
- `basicConstraints = critical, CA:FALSE`
- `keyUsage = critical, digitalSignature, keyEncipherment`
- `extendedKeyUsage = serverAuth`

SHA-256 fingerprints:

```
CA      B1:27:1D:9D:BD:62:63:91:8E:5B:5D:5E:B6:1A:1E:84:B3:10:78:B6:2F:5C:1E:0B:E4:18:65:25:21:60:F0:B8
Server  8E:A8:00:69:9E:DD:67:38:25:87:1D:02:D7:7F:7C:6F:C8:C4:CB:E3:E1:EA:C7:96:4F:1B:0D:C2:A6:70:C8:02
```

## How it was generated (Mac 2)

Reconstructed from the artifacts (key sizes, validity periods, `server-san.cnf`, `.csr`, `.srl`); the edge owner should confirm the exact flags.

```bash
# 1. CA key and self-signed CA certificate
openssl genrsa -out phase1-ca.key 4096
openssl req -x509 -new -key phase1-ca.key -sha256 -days 825 \
  -subj "/CN=Team67 Phase1 Local CA" -out phase1-ca.crt

# 2. Server key and CSR
openssl genrsa -out app.team67.test.key 2048
openssl req -new -key app.team67.test.key -config server-san.cnf -out app.team67.test.csr

# 3. CA signs the CSR, adding the SAN and serverAuth extensions
openssl x509 -req -in app.team67.test.csr -CA phase1-ca.crt -CAkey phase1-ca.key \
  -CAcreateserial -out app.team67.test.crt -days 365 -sha256 \
  -extfile server-san.cnf -extensions server_ext
```

## Trusting the CA on a client

Compare the fingerprint with the value above (received over a separate channel) before trusting.

```bash
openssl x509 -in phase1-ca.crt -noout -fingerprint -sha256
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain phase1-ca.crt
```

Rollback: `sudo security delete-certificate -c "Team67 Phase1 Local CA" /Library/Keychains/System.keychain`

## Verification

```bash
openssl verify -CAfile tls/certs/phase1-ca.crt tls/certs/app.team67.test.crt
openssl s_client -connect app.team67.test:8443 -servername app.team67.test </dev/null
curl -v https://app.team67.test:8443/api/status          # no -k
```

Saved result ([`evidence/04_nginx_tls/curl-v-tls-transcript.txt`](../evidence/04_nginx_tls/curl-v-tls-transcript.txt)):

```
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519 / RSASSA-PSS
*  subject: CN=app.team67.test
*  subjectAltName: host "app.team67.test" matched cert's "app.team67.test"
*  issuer: CN=Team67 Phase1 Local CA
*  SSL certificate verify ok.
```

## Why this matters

- **Name validation.** The client checks that the name it asked for appears in the certificate's SAN list. A valid chain for the wrong name still fails.
- **Chain validation.** The server certificate is signed by the CA; the client trusts the CA, so it trusts the server certificate.
- **Why `-k` is not evidence.** `-k` skips both checks, so a successful `curl -k` proves only that *something* answered on the port, not that it is the team's edge.
- **Why keys stay out of git.** Anyone holding `phase1-ca.key` can mint certificates that every team Mac will accept.

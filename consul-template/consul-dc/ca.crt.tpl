{{ with secret "pki_int/issue/consul-us-central1" "common_name=server.us-central1.consul" "ttl=24h"}}
{{ .Data.issuing_ca }}
{{ end }}

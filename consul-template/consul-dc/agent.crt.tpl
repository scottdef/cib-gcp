{{ with secret "pki_int/issue/consul-us-central1" "common_name=server.us-central1.consul" "ttl=24h" "alt_names=localhost" "ip_sans=127.0.0.1"}}
{{ .Data.certificate }}
{{ end }}

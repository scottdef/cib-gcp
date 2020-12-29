# This denotes the start of the configuration section for Vault. All values
# contained in this section pertain to Vault.
vault {
  # This is the address of the Vault leader. The protocol (http(s)) portion
  # of the address is required.
  address      = "http://localhost:8200"

  # This value can also be specified via the environment variable VAULT_TOKEN.
  token        = "root"

  unwrap_token = false

  renew_token  = false
}

template {
  source      = "ca.crt.tpl"
  destination = "/opt/consul/tls/ca.crt"
  command     = "sh -c 'date && consul reload'"
}

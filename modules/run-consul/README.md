# Consul Run Script

This folder contains a script for configuring and running Consul on a [GCP](https://cloud.google.com/) Compute Instance.
This script has been tested on the following operating systems:

- Ubuntu 18.04

There is a good chance it will work on other flavors of Debian as well.

## Quick start

This script assumes you installed it, plus all of its dependencies (including Consul itself), using the [install-consul
module](https://github.com/hashicorp/terraform-google-consul/tree/master/modules/install-consul). The default install path is `/opt/consul/bin`, so to start Consul in server mode,
you run:

```
/opt/consul/bin/run-consul --server
```

To start Consul in client mode, you run:

```
/opt/consul/bin/run-consul --client
```

This will:

1. Generate a Consul configuration file called `default.json` in the Consul config dir (default: `/opt/consul/config`).
   See [Consul configuration](#consul-configuration) for details on what this configuration file will contain and how
   to override it with your own configuration.

1. Generate a [systemd](https://www.freedesktop.org/wiki/Software/systemd/) configuration file called `consul.service` in the systemd
   config dir (default: `/etc/systemd/system`) with a command that will run Consul:
   `consul agent -config-dir=/opt/consul/config -data-dir=/opt/consul/data`.

1. Tell systemd to load the new configuration file, thereby starting Consul.

We recommend using the `run-consul` command as part of the [Startup Script](https://cloud.google.com/compute/docs/startupscript),
so that it executes when the Compute Instance is first booting. After runing `run-consul` on that initial boot, the `systemd`
configuration will automatically restart Consul if it crashes or the Compute instance reboots.

Note that `systemd` logs to its own journal by default. To view the Consul logs, run `journalctl -u consul.service`. To change
the log output location, you can specify the `StandardOutput` and `StandardError` options by using the `--systemd-stdout` and `--systemd-stderr`
options. See the [`systemd.exec` man pages](https://www.freedesktop.org/software/systemd/man/systemd.exec.html#StandardOutput=) for available
options, but note that the `file:path` option requires [systemd version >= 236](https://stackoverflow.com/a/48052152).

See the [consul-cluster example](https://github.com/hashicorp/terraform-google-consul/tree/master/examples/root-example) for fully-working sample code.

## Command line Arguments

The `run-consul` script accepts the following arguments:

- `server` (optional): If set, run in server mode. Exactly one of `--server` or `--client` must be set.
- `client` (optional): If set, run in client mode. Exactly one of `--server` or `--client` must be set.

* `cluster-tag-name` Automatically form a cluster with Instances that have the same value for this Compute Instance tag
  name.

- `datacenter` (optional): The name of the datacenter the cluster reports. Default is the GCP region name.
- `config-dir` (optional): The path to the Consul config folder. Default is to take the absolute path of `../config`,
  relative to the `run-consul` script itself.
- `data-dir` (optional): The path to the Consul config folder. Default is to take the absolute path of `../data`,
  relative to the `run-consul` script itself.
- `systemd-stdout` (optional): The StandardOutput option of the systemd unit. If not specified, it will use systemd's default (journal).
- `systemd-stderr` (optional): The StandardError option of the systemd unit. If not specified, it will use systemd's default (inherit).
- `user` (optional): The user to run Consul as. Default is to use the owner of `config-dir`.
- `enable-gossip-encryption` (optional): Enable encryption of gossip traffic between nodes. If set, you must also specify `gossip-encryption-key`.
- `gossip-encryption-key` (optional): The key to use for encrypting gossip traffic. Must be specified with `enable-gossip-encryption`.
- `enable-rpc-encryption` (optional): Enable encryption of RPC traffic between nodes. Must also specify `ca-file-path`, `cert-file-path` and `key-file-path`.
- `ca-file-path` (optional): Path to the CA file used to verify outgoing connections. Must be specified with `enable-rpc-encryption`, `cert-file-path` and `key-file-path`.
- `cert-file-path` (optional): Path to the certificate file used to verify incoming connections. Must be specified with `enable-rpc-encryption`, `ca-file-path`, and `key-file-path`.
- `key-file-path` (optional): Path to the certificate key used to verify incoming connections. Must be specified with `enable-rpc-encryption`, `ca-file-path` and `cert-file-path`.
- `skip-consul-config` (optional): If this flag is set, don't generate a Consul configuration file. This is useful if
  you have a custom configuration file and don't want to use any of of the default settings from `run-consul`.

Options for Consul Autopilot:

- `--autopilot-cleanup-dead-servers` (optional): Set to true or false to control the automatic removal of dead server nodes periodically and whenever a new server is added to the cluster. Defaults to true.
- `--autopilot-last-contact-threshold` (optional): Controls the maximum amount of time a server can go without contact from the leader before being considered unhealthy. Must be a duration value such as 10s. Defaults to 200ms.
- `--autopilot-max-trailing-logs` (optional): Controls the maximum number of log entries that a server can trail the leader by before being considered unhealthy. Defaults to 250.
- `--autopilot-server-stabilization-time` (optional): Controls the minimum amount of time a server must be stable in the 'healthy' state before being added to the cluster. Only takes effect if all servers are running Raft protocol version 3 or higher. Must be a duration value such as 30s. Defaults to 10s.
- `--autopilot-redundancy-zone-tag` (optional)(enterprise-only): This controls the -node-meta key to use when Autopilot is separating servers into zones for redundancy. Only one server in each zone can be a voting member at one time. If left blank, this feature will be disabled. Defaults to az.
- `--autopilot-disable-upgrade-migration` (optional)(enterprise-only): If this flag is set, this will disable Autopilot's upgrade migration strategy in Consul Enterprise of waiting until enough newer-versioned servers have been added to the cluster before promoting any of them to voters. Defaults to false.
- `--autopilot-upgrade-version-tag` (optional)(enterprise-only): That tag to be used to override the version information used during a migration.

Example:

```
/opt/consul/bin/run-consul --server --cluster-tag-key consul-cluster --cluster-tag-value prod-cluster
```

## Consul configuration

`run-consul` generates a configuration file for Consul called `default.json` that tries to figure out reasonable
defaults for a Consul cluster in GCP. Check out the [Consul Configuration Files
documentation](https://www.consul.io/docs/agent/options.html#configuration-files) for what configuration settings are
available.

### Default configuration

`run-consul` sets the following configuration values by default:

- [advertise_addr](https://www.consul.io/docs/agent/options.html#advertise_addr): Set to the Compute Instance's private IP
  address.

- [bind_addr](https://www.consul.io/docs/agent/options.html#bind_addr): Set to the Compute Instance's private IP address.

- [bootstrap_expect](https://www.consul.io/docs/agent/options.html#bootstrap_expect): If `--server` is set,
  set this config based on the [Instance Metadata](https://cloud.google.com/compute/docs/storing-retrieving-metadata) tags:

  - Set this config to the value of the `cluster-size` tag.

- [client_addr](https://www.consul.io/docs/agent/options.html#client_addr): Set to 0.0.0.0 so you can access the client
  and UI endpoint on each Compute Instance from the outside.

- [datacenter](https://www.consul.io/docs/agent/options.html#datacenter): Set to the current Instance Region (e.g.
  `us-west1`), as fetched from [Instance Metadata](https://cloud.google.com/compute/docs/storing-retrieving-metadata).

- [node_name](https://www.consul.io/docs/agent/options.html#node_name): Set to the instance name, as fetched from
  [Instance Metadata](https://cloud.google.com/compute/docs/storing-retrieving-metadata).

- [retry_join](https://www.consul.io/docs/agent/options.html#retry-join): Set the following keys for this setting:

  - [provider](https://www.consul.io/docs/agent/options.html#provider-2): Set to `gce` for Google Compute Engine.
  - [project_name](https://www.consul.io/docs/agent/options.html#project_name): Set to the name of the GCP Project where
    the Consul Servers are located.
  - [tag_value](https://www.consul.io/docs/agent/options.html#tag_value-2): Set to the value of the tag shared by all
    Consul Server nodes.

- [server](https://www.consul.io/docs/agent/options.html#server): Set to true if `--server` is set.

- [ui](https://www.consul.io/docs/agent/options.html#ui): Set to true to make the UI available.

### Overriding the configuration

To override the default configuration, simply put your own configuration file in the Consul config folder (default:
`/opt/consul/config`), but with a name that comes later in the alphabet than `default.json` (e.g.
`my-custom-config.json`). Consul will load all the `.json` configuration files in the config dir and
[merge them together in alphabetical order](https://www.consul.io/docs/agent/options.html#_config_dir), so that
settings in files that come later in the alphabet will override the earlier ones.

For example, to override the default `retry_join` settings, you could create a file called `tags.json` with the
contents:

```json
{
  "retry_join": {
    "provider": "gce",
    "project_name": "my-project",
    "tag_value": "custom-value"
  }
}
```

If you want to override _all_ the default settings, you can tell `run-consul` not to generate a default config file
at all using the `--skip-consul-config` flag:

```
/opt/consul/bin/run-consul --server --skip-consul-config
```

### Required permissions

The `run-consul` script assumes only that the Compute Instance can query its own metadata, a permission enabled by
default on all Compute Instances.

## How do you handle encryption?

Consul can encrypt all of its network traffic (see the [encryption docs for
details](https://www.consul.io/docs/agent/encryption.html)), but by default, encryption is not enabled in this
Module. To enable encryption, you need to do the following:

1. [Gossip encryption: provide an encryption key](#gossip-encryption-provide-an-encryption-key)
1. [RPC encryption: provide TLS certificates](#rpc-encryption-provide-tls-certificates)

### Gossip encryption: provide an encryption key

To enable Gossip encryption, you need to provide a 16-byte, Base64-encoded encryption key, which you can generate using
the [consul keygen command](https://www.consul.io/docs/commands/keygen.html) offline. You can pass the
`--enable-gossip-encryption` and `--gossip-encryption-key` parameters to `run-consul` to have this script automatically
generate the gossip encryption settings in `default.json` in the Consul config dir.

Alternatively, you can put the key in a Consul configuration file (e.g. `encryption.json`) in the Consul
config dir (default location: `/opt/consul/config`):

```json
{
  "encrypt": "cg8StVXbQJ0gPvMd9o7yrg=="
}
```

### RPC encryption: provide TLS certificates

To enable RPC encryption, you need to provide the paths to the CA and signing keys. Since you're already using Terraform,
it's probably easiest to use the [TLS Provider](https://www.terraform.io/docs/providers/tls/index.html) to generate your
own certificates. You can find a good working example in the [private-tls-cert module](https://github.com/hashicorp/terraform-google-vault/tree/master/modules/private-tls-cert)
within the [terraform-google-vault repo](https://github.com/hashicorp/terraform-google-vault). You can pass the `--enable-rpc-encryption`,
`--ca-file-path`, `--cert-file-path`, and `--key-file-path` parameters to `run-consul` to have this script automatically
generate the RPC encryption settings in `default.json` in the Consul config dir. Please note that this **does not** set
`"verify_server_hostname": true`. Check the documentation of the [verify_server_hostname field](https://www.consul.io/docs/agent/options.html#verify_server_hostname)
to understand the implications of this.

Alternatively, you can specify these paths in a Consul configuration file (e.g. `encryption.json`) in the Consul config
dir (default location: `/opt/consul/config`):

```json
{
  "ca_file": "/opt/consul/tls/certs/ca-bundle.crt",
  "cert_file": "/opt/consul/tls/certs/my.crt",
  "key_file": "/opt/consul/tls/private/my.key"
}
```

You will also want to set the [verify_incoming](https://www.consul.io/docs/agent/options.html#verify_incoming) and
[verify_outgoing](https://www.consul.io/docs/agent/options.html#verify_outgoing) settings to verify TLS certs on
incoming and outgoing connections, respectively:

```json
{
  "ca_file": "/opt/consul/tls/certs/ca-bundle.crt",
  "cert_file": "/opt/consul/tls/certs/my.crt",
  "key_file": "/opt/consul/tls/private/my.key",
  "verify_incoming": true,
  "verify_outgoing": true
}
```

### Autopilot

[Autopilot](https://www.consul.io/docs/guides/autopilot.html) is a set of features for the
automatic management of consul servers. These features are enabled by default and already
set with reasonable defaults. It includes automatic cleaning up of dead servers as soon as
a replacement Consul server comes online. The internal health check runs on the leader to
track other servers. A server is considered healthy when:

- Its status is `Alive`
- The time since its last contact with the current leader is below `autopilot-last-contact-threshold`
- Its latest [Raft consensus algorithm](https://raft.github.io/) term matches the leader's term
- The number of Raft log entries it trails the leader by does not exceed `autopilot-max-trailing-logs`

There are Autopilot settings called [upgrade migrations](https://www.consul.io/docs/guides/autopilot.html#upgrade-migrations)
that are useful when adding new members to the cluster either with newer configurations or using
newer versions of Consul. These configurations manage how Consul will promote new servers and demote
old ones. These settings, however, are only available at the Consul Enterprise version.

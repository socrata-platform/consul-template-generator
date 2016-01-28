[![Build Status](https://travis-ci.org/socrata-platform/consul-template-generator.svg)](https://travis-ci.org/socrata-platform/consul-template-generator)
[![Gem Version](https://badge.fury.io/rb/consul-template-generator.svg)](https://badge.fury.io/rb/consul-template-generator)

# Consul Template Generator

[Consul-Template](https://github.com/hashicorp/consul-template) is an immensely valuable tool
for translating services registered with [Consul](https://github.com/hashicorp/consul) into
system configurations. One potential pitfall with it, though, is the potential for large,
distributed systems to [DDoS](https://github.com/hashicorp/consul-template/issues/205) their Consul
cluster.  This work can be mitigated to some degree with carefully crafted templates, but can
also be avoided by the use of `consul-template-generator`

The function of `consul-template-generator` is to delegate template generation to a single process
in a fault-tolerant fashion.  The `consul-template-generator` "master" takes a consul lock on a
specified session K/V store key to allow redundant deployments of any given configuration to be
active simultaneously.  A given `consul-template-generator` configuration can include arbitrary
number `ctmpl` files which will be evaluated using `conssul-template`.  When updates to a `ctmpl`
are found `consul-template-generator` will update specified keys in Consul's K/V store with the
`consul-template` rendered templates.  This allows downstream instances of `consul-template` to
watch a single key in Consul K/V instead of multiple Consul registered services, reducing the load
on the underlying Consul cluster by (potentially) orders of magnitude.


## Usage

`consul-template-generator <command> [options]`

### Commands

| Command | Description |
|---------|-------------|
| once | Run once and exit.  On success, the rendered template will be inserted into the KV store whether or not it has changed. |
| run | Run continually, uploading the rendered template when a change is detected. |

### Options
| required | short flag         | long flag                       | Description |
|----------|--------------------|---------------------------------|-------------|
| No       | `-c HOSTNAME`      | `--consul HOSTNAME`             | Hostname/port used to connect to consul [default: 127.0.0.1:8500] |
| Yes      | `-t TEMPLATES`     | `--templates TEMPLATES`         | (required) Comma separated list of consul-template `ctmpl` file and keys to monitor, `tmple.ctmpl:tmple-key,tmple2.ctmpl:templ-key2`. If `--graphite-host` is supplied, target graphite path must also be supplied, e.g. `tmple.ctmpl:tmple-key:consul.template.<HOSTNAME>.<template name>`. |
| No       | `-s SESSION_KEY`   | `--session-key SESSION_KEY`     | Key used to lock template generation session [default: consul-template-generator] |
| No       |                    | `--session-ttl SESSION_TTL`     | Set a TTL for consul sessions (sets an implicit ttl on locks created by consul-template-generator [default: 30s] |
| No       |                    | `--unset-proxy`                 | Use if 'http_proxy' is set in your environment, but you don't want to use it... |
| No       |                    | `--diff-changes`                | Log diff'ed template prior to upload |
| No       | `-l`               | `--log-level LOG_LEVEL`         | Log level, options are 'debug', 'info', 'error' [default: info] |
| No       |                    | `--cycle-sleep CYCLE_SLEEP`     | Sleep interval in seconds between each template rendering [default: 0.5] |
| No       |                    | `--lock-sleep LOCK_SLEEP`       | Sleep interval in seconds between each attempt to obtain a session lock [default: 1.0] |
| No       | `-g GRAPHITE_HOST` | `--graphite-host GRAPHITE_HOST` | Graphite host to post template update events to (optional) |

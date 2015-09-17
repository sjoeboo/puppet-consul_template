# == Class consul_template::config
#
# This class is called from consul_template for service config.
#
class consul_template::config (
  $consul_host,
  $consul_port,
  $consul_token,
  $consul_retry,
  $purge = true,
) {

  concat::fragment { 'header':
    target  => 'consul-template/config.json',
    content => inline_template("consul = \"<%= @consul_host %>:<%= @consul_port %>\"\ntoken = \"<%= @consul_token %>\"\nretry = \"<%= @consul_retry %>\"\n\n"),
    order   => '00',
  }

  # Set the log level
  concat::fragment { 'log_level':
    target  => 'consul-template/config.json',
    content => inline_template("log_level = \"${::consul_template::log_level}\"\n"),
    order   => '01'
  }

  # Set wait param if specified
  if $::consul_template::consul_wait {
    concat::fragment { 'consul_wait':
      target  => 'consul-template/config.json',
      content => inline_template("wait = \"${::consul_template::consul_wait}\"\n\n"),
      order   => '02',
    }
  }

  if $::consul_template::vault_enabled {
    concat::fragment { 'vault-base':
      target  => 'consul-template/config.json',
      content => inline_template("vault {\n  address = \"${::consul_template::vault_address}\"\n  token = \"${::consul_template::vault_token}\"\n"),
      order   => '03',
    }
    if $::consul_template::vault_ssl {
      concat::fragment { 'vault-ssl1':
        target  => 'consul-template/config.json',
        content => inline_template("  ssl {\n    enabled = true\n    verify = ${::consul_template::vault_ssl_verify}\n"),
        order   => '04',
      }
      concat::fragment { 'vault-ssl2':
        target  => 'consul-template/config.json',
        content => inline_template("    cert = \"${::consul_template::vault_ssl_cert}\"\n    ca_cert = \"${::consul_template::vault_ssl_ca_cert}\"\n  }\n"),
        order   => '05',
      }
    }
    concat::fragment { 'vault-baseclose':
      target  => 'consul-template/config.json',
      content => "}\n\n",
      order   => '06',
    }
  }

  file { $consul_template::config_dir:
    ensure  => 'directory',
    purge   => $purge,
    recurse => $purge,
  } ->
  concat { 'consul-template/config.json':
    path   => "${consul_template::config_dir}/config.json",
    notify => Service['consul-template'],
  }

}

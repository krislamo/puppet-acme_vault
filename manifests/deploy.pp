# Configuration for deploying certs in vault to the filesystem
#

class acme_vault::deploy(
    $user                  = $::acme_vault::common::user,
    $group                 = $::acme_vault::common::group,
    $home_dir              = $::acme_vault::common::home_dir,
    $domains               = $::acme_vault::common::domains,

    $cert_destination_path = $::acme_vault::params::cert_destination_path,
    $deploy_scripts        = $::acme_vault::params::deploy_scripts,
    $restart_method        = $::acme_vault::params::restart_method,

) inherits acme_vault::params {
  include acme_vault::common

  # copy down cert check script
  file {"${home_dir}/check_cert.sh":
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0750',
    source => 'puppet:///modules/acme_vault/check_cert.sh',
  }

  # ensure destination paths exist
  file {[$cert_destination_path, $deploy_scripts]:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0750',
  }

  # go through each domain, setup cron, and ensure the destination dir exists
  $domains.each |$domain, $d_list| {
    cron { "${domain}_deploy":
      command => ". \$HOME/.bashrc && ${home_dir}/check_cert.sh ${domain} ${cert_destination_path} && ${restart_method}",
      user    => $user,
      weekday => 2,
      hour    => 11,
      minute  => 17,
    }

    file {"${cert_destination_path}/${domain}":
      ensure => directory,
      owner  => $user,
      group  => $group,
      mode   => '0750',
    }
  }

}



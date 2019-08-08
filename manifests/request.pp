# Configuration for requesting a cert from letsencrypt, and storing it in vault.
#

class acme_vault::request (
    $user               = $::acme_vault::common::user,
    $group              = $::acme_vault::common::group,
    $home_dir           = $::acme_vault::common::home_dir,
    $contact_email      = $::acme_vault::common::contact_email,
    $domains            = $::acme_vault::common::domains,
    $overrides          = $::acme_vault::common::overrides,

    $staging            = $::acme_vault::params::staging,
    $staging_url        = $::acme_vault::params::staging_url,
    $prod_url           = $::acme_vault::params::prod_url,

    $acme_revision      = $::acme_vault::params::acme_revision,
    $acme_repo_path     = $::acme_vault::params::acme_repo_path,
    $acme_script        = $::acme_vault::params::acme_script,

    $lexicon_provider   = $::acme_vault::params::lexicon_provider,
    $lexicon_username   = $::acme_vault::params::lexicon_username,
    $lexicon_token      = $::acme_vault::params::lexicon_token,


) inherits acme_vault::params {

    include acme_vault::common

    $request_bashrc_template = @(END)
export TLDEXTRACT_CACHE=$HOME/.tld_set
export PROVIDER=<%= @lexicon_provider %>
export LEXICON_<%= @lexicon_provider.upcase %>_AUTH_USERNAME=<%= @lexicon_username %>
export LEXICON_<%= @lexicon_provider.upcase %>_AUTH_TOKEN=<%= @lexicon_token %>
END

    # install lexicon
    ensure_packages(['dns-lexicon', 'PyNamecheap'], {
      ensure   => present,
      provider => 'pip',
    })

    # variables in bashrc
    concat::fragment { 'request_bashrc':
      target  => "${home_dir}/.bashrc",
      content => inline_template($request_bashrc_template),
      order   => '02',
    }


    # checkout acme repo
    vcsrepo { $acme_repo_path:
      ensure   => present,
      provider => git,
      source   => 'https://github.com/Neilpang/acme.sh.git',
      revision => $acme_revision,
    }

    file { "${home_dir}/.acme.sh":
      ensure => directory,
      owner  => $user,
      group  => $group,
      mode   => '0700',
    } ->
    file { "${home_dir}/.acme.sh/account.conf":
      ensure => present,
      owner  => $user,
      group  => $group,
      mode   => '0600',
    } ->
    file_line { ' add email to acme conf':
      path  => "${home_dir}/.acme.sh/account.conf",
      line  => "ACCOUNT_EMAIL='${contact_email}'",
      match => '^ACCOUNT_EMAIL=.*$',
    }

    # create issue scripts
    $domains.each |$domain, $d_list| {
      file {"/${home_dir}/${domain}.sh":
        ensure  => present,
        mode    => '0700',
        owner   => $user,
        group   => $group,

        content => epp('acme_vault/domain.epp', {
          acme_script => $acme_script,
          domain      => $domain,
          domains     => $d_list,
          staging     => $staging,
          staging_url => $staging_url,
          prod_url    => $prod_url,
          overrides   => $overrides,
          }
        )
      }
      cron { "${domain}_issue":
        command => "${home_dir}/${domain}.sh",
        user    => $user,
        weekday => 1,
        hour    => 11,
        minute  => 28,
      }
    }

}

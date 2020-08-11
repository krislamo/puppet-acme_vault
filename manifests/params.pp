# params for both common, request, and deploy
class acme_vault::params {
    # settings for acme user
    $user       = 'acme'
    $group      = 'apache'
    $home_dir   = '/home/acme_vault'
    $contact_email = ''
    $domains     = undef
    # overrides is a list of challenge-alias overrides.  It defaults to the domain itself.
    # see https://github.com/Neilpang/acme.sh/wiki/DNS-alias-mode
    $overrides   = {}

    # authentication
    $vault_token = undef
    $vault_addr  = undef
    $vault_bin   = "${home_dir}/vault"

    $vault_prefix   = '/secret/letsencrypt/'

    # whether to use the letsencrypt staging url, set those urls
    $staging     = false
    $staging_url = 'https://acme-staging-v02.api.letsencrypt.org/directory'
    $prod_url    = 'https://acme-v02.api.letsencrypt.org/directory'

    $acme_revision = 'HEAD'
    $acme_repo_path = "${home_dir}/acme.sh"
    $acme_script    = "${acme_repo_path}/acme.sh"

    # lexicon
    $lexicon_provider   = undef
    $lexicon_username   = undef
    $lexicon_token      = undef

    # settings for deploy
    $cert_destination_path = '/etc/acme'
    $deploy_scripts        = "${cert_destination_path}/deploy.d"
    $restart_method        = "for f in ${deploy_scripts}/*.sh; do \"\$f\"; done"
}

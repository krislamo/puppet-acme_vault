
# acme_vault

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with acme_vault](#setup)
    * [What acme_vault affects](#what-acme_vault-affects)
    * [Beginning with acme_vault](#beginning-with-acme_vault)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

This module uses [acme.sh](https://github.com/Neilpang/acme.sh) to request
letsencrypt certificates using the DNS-01 challenge.  Once valid certificates
are recieved, they are stored in [Hashicorp
vault](https://www.vaultproject.io/) where they can be retrieved by any
appropriate machine.

This module consists of a common class, a request class, and a deploy class.
The request class is intended to be enabled on a single machine that will
handle all the certificate request and validation.  The deploy class is then
enabled on any machine that requires the requested certificates.

## Setup

### What acme_vault affects

This module will create a new system user that is used to request and deploy
certificates.  It uses [lexicon](https://github.com/AnalogJ/lexicon) to make
api requests for dns changes.  We use namecheap, so the required namecheap
python library is also included.  Both are installed via pip.

This module also assumes a working installation of vault.

### Beginning with acme_vault

Just include the appropriate modules for the appropriate machines, and make
sure the required values are provided via hiera or class.  Note: the common
module must be included before either.

Typically this would involve a profile like:

```puppet
class profiles::acme_request {

  include ::acme_vault::common
  include ::acme_vault::request

}

```

## Usage

This section is where you describe how to customize, configure, and do the fancy stuff with your module here. It's especially helpful if you include usage examples and code samples for doing things with your module.

## Reference

**Classes:**

* [acme_vault::common](#acme_vaultcommon)
* [acme_vault::request](#acme_vaultrequest)
* [acme_vault::deploy](#acme_vaultdeploy)

### Classes

#### acme_vault::common

This class needs to be included before acme_vault::request or
acme_vault::deploy and contains configurations common to both.  The user,
vault, vault vars, and cron mailto are needed for both request and deploy

##### `user`

user to be created to request/deploy certs

Default value: `acme_vault`

##### `group`

group that the user belongs to.  For deploy, this should probably be the webserver group

Default value: `acme_vault`

##### `home_dir`

home dir of the above user, where scripts and config will be stored.

Default value: `/home/$user`

##### `contact_email`

contact email used for cert registration, also used as MAILTO variable for cron jobs

Default value: `''`

##### `domains`

mapping of domains to be included in the cert.  The key is the "main" domain,
and the value is the list of extra names to be requested.  Both the main domain
and the list of domains are included.

REQUIRED

#### `vault_token`

Vault token for authenticating to vault.  This should have appropriate
permissions applied in vault.  A demo script is provided
[here](vault_policy.sh)

REQUIRED

#### `vault_addr`

Address of vault server

REQUIRED

#### `vault_bin`

Path to the vault binary.

Default value: `${home_dir}/vault"`

#### `vault_prefix`

The path within vault where the certificates will be stored and retrieved.

Default value: `/secret/letsencrypt/`

#### acme_vault::request

This class uses acme.sh, and pulls down the git repo for it.  It uses the
lexicon provider in acme.sh to do the dns updating for the dns-01 challenge.
It configures a cron job to periodically check if a cert needs renewal.

Note: it does not automatically trigger requesting certs, but relies on cron
coordination to eventually reach the desired end state.  Since certificate
renewal has a large time window, this is acceptable.  Any urgent issue/renewals
can be triggered by running the cron job manually as needed.

#### Parameters inherited from common, but can be overriden:

##### `user`

user to be created to request/deploy certs

Default value: `acme_vault`

##### `group`

group that the user belongs to.  For deploy, this should probably be the webserver group

Default value: `acme_vault`

##### `home_dir`

home dir of the above user, where scripts and config will be stored.

Default value: `/home/$user`

##### `contact_email`

contact email used for cert registration, also used as MAILTO variable for cron jobs

Default value: `''`

##### `domains`

mapping of domains to be included in the cert.  The key is the "main" domain,
and the value is the list of extra names to be requested.  Both the main domain
and the list of domains are included.

REQUIRED


#### Parameters only for request:

#### `staging`

whether to use the acme staging endpoint

Valid values: `true`, `false`

Default value: `false`

#### `staging_url`

url to acme staging endpoint

Default value: `https://acme-staging-v02.api.letsencrypt.org/directory`

#### `prod_url`

url to the acme prod endpoint

Default value: `https://acme-v02.api.letsencrypt.org/directory`

#### `acme_revision`

git revision/tag to be used to checkout acme.sh repository.

Default value: `HEAD`

#### `acme_repo_path`

where the repo should be checked out.

Default value: `$home_dir/acme.sh`

#### `acme_script`

path the the acme.sh script itself

Default value: `$acme_repo_path/acme.sh`

#### `lexicon_provider`

provider for lexicon to use for dns-01 challanges.

REQUIRED

#### `lexicon_username`

username for lexicon dns.

REQUIRED

#### `lexicon_token`

token for lexicon user.

REQUIRED

### acme_vault::deploy

This class handles taking a cert/key out of vault, and placing it in a
configured path on the filesystem.  It will also accept a restart command to
restart any appropriate services to take advantage of the new cert.

It employs a script, check_cert.sh, to validate the cert in vault exists, and
is appropriate to replace the existing one

#### Parameters inherited from common, but can be overriden:

##### `user`

user to be created to request/deploy certs

Default value: `acme_vault`

##### `group`

group that the user belongs to.  For deploy, this should probably be the webserver group

Default value: `acme_vault`

##### `home_dir`

home dir of the above user, where scripts and config will be stored.

Default value: `/home/$user`

##### `domains`

mapping of domains to be included in the cert.  The key is the "main" domain,
and the value is the list of extra names to be requested.  Both the main domain
and the list of domains are included.

REQUIRED

#### Parameters only for deploy:

##### `cert_destination_path`

where the cert should be deployed to.  cert will end up in $cert_destination_path/$domain/.

Default value: `/etc/acme`

##### `deploy_scripts`

location for arbitrary scripts to reload certificates for applications. scripts will end up in $cert_destination_path/deploy.d/

Default value: `/etc/acme/deploy.d`

##### `restart_method`

shell that is run after successful deployment. runs scripts in $deploy_scripts

Default value: `for f in /etc/acme/deploy.d/*.sh; do "$f"; done`


## Limitations

Has only been tested on Centos 7

## Development

Contributions are welcome!


# The "bareos" class is included by bareos::client, and keeps a shared
# secret for generating passwords.
class bareos  (
  $secret = $bareos::params::secret,
) inherits bareos::params {

  if $secret == 'Default secret from bareos::params' {
    notify { 'Please set the bareos::secret parameter, using the default default does not provide security.': }
  }

}

# Define: bareos::client_definition
#
# This define installs a configuration file on the backup server.
#
define bareos::client_definition(
  $password,
  $address,
  $job_retention,
  $file_retention,
  $concurrency,
  $client_name='',
  $security_zone='',
)
{
  if $client_name == '' {
    $_client_name = $title
  } else {
    $_client_name = $client_name
  }
  ensure_resource('file',
    "${bareos::server::client_file_prefix}${_client_name}.conf", {
      content => template('bareos/server/client.erb')
  })
}

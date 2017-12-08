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
  $port = 9102,
  $client_name = '',
  $security_zone = '',
  $passive = false,
  $client_initiated_connection = false,
)
{
  # use de-uniqueified title going forward, but keep client_name
  # compatibility for a while
  if $client_name == '' {
    $_client_name = regsubst($title, '.*?\/', '')
  } else {
    $_client_name = $client_name
  }
  ensure_resource('file',
    "${bareos::server::client_file_prefix}${_client_name}.conf", {
      content => template('bareos/server/client.erb'),
      owner   => 'root',
      group   => 'bareos',
      mode    => '0440',
  })
}

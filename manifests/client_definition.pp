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
)
{
  file { "${bareos::server::client_file_prefix}${title}.conf":
    content => template('bareos/server/client.erb');
  }
}

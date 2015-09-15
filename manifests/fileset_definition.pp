# Define: bareos::fileset_definition
#
# This define installs a configuration file on the backup server.
#
define bareos::fileset_definition(
  $include_paths,
  $exclude_paths,
  $ignore_changes,
)
{
  $filename = "${bareos::server::fileset_file_prefix}${title}.conf"

  file { $filename:
    content => template('bareos/server/fileset.erb');
  }
}

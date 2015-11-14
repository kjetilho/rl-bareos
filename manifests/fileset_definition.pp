# Define: bareos::fileset_definition
#
# This define installs a configuration file on the backup server.
# Only very simple filesets are supported so far.
#
define bareos::fileset_definition(
  $include_paths,
  $exclude_paths,
  $exclude_dir_containing,
  $ignore_changes,
  $acl_support
)
{
  validate_bool($ignore_changes)
  validate_bool($acl_support)

  $filename = "${bareos::server::fileset_file_prefix}${title}.conf"
  file { $filename:
    content => template('bareos/server/fileset.erb');
  }
}

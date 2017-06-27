# Define: bareos::fileset_definition
#
# This define installs a configuration file on the backup server.
# Only very simple filesets are supported so far.
#
define bareos::fileset_definition(
  $include_paths,
  $exclude_paths,
  $include_patterns = {},
  $exclude_patterns = {},
  $exclude_dir_containing,
  $plugins = [],
  $ignore_changes,
  $acl_support,
  $onefs = false,
  $sparse = true,
  $compression = 'GZIP',
  $fstype = ['ext2','ext3','ext4','jfs','reiserfs','rootfs','xfs'],
)
{
  validate_bool($ignore_changes)
  validate_bool($acl_support)
  validate_bool($onefs)
  validate_array($fstype)

  $fset_name = regsubst($title, '.*?\/', '')
  $_fset_name = regsubst($fset_name, '[^A-Za-z0-9.:_-]+', '_', 'G')
  $filename = "${bareos::server::fileset_file_prefix}${_fset_name}.conf"

  ensure_resource('file', $filename, {
    content => template('bareos/server/fileset.erb'),
    owner   => 'root',
    group   => 'bareos',
    mode    => '0444',
  })
}

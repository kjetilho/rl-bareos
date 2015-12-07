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
  $acl_support,
  $onefs = false,
  $fstype = ['ext2','ext3','ext4','jfs','reiserfs','rootfs','xfs'],
)
{
  validate_bool($ignore_changes)
  validate_bool($acl_support)
  validate_bool($onefs)
  validate_array($fstype)

  $fset_name = regsubst($title, '.*?\/', '')
  $filename = "${bareos::server::fileset_file_prefix}${fset_name}.conf"

  ensure_resource('file', $filename, {
    content => template('bareos/server/fileset.erb'),
    owner   => 'root',
    group   => 'bareos',
    mode    => '0444',
  })
}

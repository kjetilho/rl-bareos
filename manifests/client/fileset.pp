# Define bareos::client::fileset
#
# This declares and exports a fileset for the backup server.
#
# +fileset_name+: If specified, use this as name for Fileset.  Must be
#     globally unique.  If not set, a globally unique name is created
#     by appending this define's title to the client name.
# +include_paths+: Array of directories to include
# +exclude_paths+: Array of directories to exclude
#
# For detailed documentation, see README.md
#
define bareos::client::fileset(
  $fileset_name = '',
  $include_paths,
  $exclude_paths = [],
  $exclude_dir_containing = '.nobackup',
  $ignore_changes = true,
  $acl_support = true,
  $onefs = false,
  $fstype = $bareos::client::fstype,
)
{
  validate_array($include_paths)
  validate_array($exclude_paths)
  validate_bool($ignore_changes)
  validate_bool($acl_support)
  validate_bool($onefs)
  validate_array($fstype)

  if $fileset_name == '' {
    if $bareos::client::client_name == $::fqdn {
      $_fileset_name = "${bareos::client::client_name}-${title}"
    } else {
      $_fileset_name = "${::fqdn}/${bareos::client::client_name}-${title}"
    }
  } else {
    $_fileset_name = $fileset_name
  }
  @@bareos::fileset_definition {
    $_fileset_name:
      include_paths          => $include_paths,
      exclude_paths          => $exclude_paths,
      exclude_dir_containing => $exclude_dir_containing,
      acl_support            => $acl_support,
      ignore_changes         => $ignore_changes,
      onefs                  => $onefs,
      fstype                 => $fstype,
      tag                    => "bareos::server::${bareos::director}"
  }
}

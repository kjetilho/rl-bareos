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
  $client_name = $bareos::client::client_name,
  $include_paths,
  $exclude_paths = $bareos::client::exclude_paths,
  $include_patterns = {},
  $exclude_patterns = $bareos::client::exclude_patterns,
  $exclude_dir_containing = '.nobackup',
  $plugins = [],
  $ignore_changes = true,
  $acl_support = true,
  $onefs = false,
  $sparse = true,
  $compression = $bareos::client::compression,
  $fstype = $bareos::client::fstype,
)
{
  validate_array($include_paths)
  validate_array($exclude_paths)
  validate_hash($include_patterns)
  validate_hash($exclude_patterns)
  validate_bool($ignore_changes)
  validate_bool($acl_support)
  validate_bool($onefs)
  validate_array($fstype)

  if $fileset_name == '' {
    validate_re($title, '^[A-Za-z0-9:._ -]+$')
    if $client_name == $::fqdn {
      $_fileset_name = "${client_name}-${title}"
    } else {
      $_fileset_name = "${::fqdn}/${client_name}-${title}"
    }
  } else {
    validate_re($fileset_name, '^[A-Za-z0-9:._ -]+$')
    $_fileset_name = $fileset_name
  }
  if 'defaults' in $exclude_paths {
    $_exclude_paths = flatten([ $bareos::client::exclude_paths,
                                delete($exclude_paths, 'defaults') ])
  } else {
    $_exclude_paths = $exclude_paths
  }
  @@bareos::fileset_definition {
    $_fileset_name:
      include_paths          => $include_paths,
      exclude_paths          => $_exclude_paths,
      include_patterns       => $include_patterns,
      exclude_patterns       => $exclude_patterns,
      exclude_dir_containing => $exclude_dir_containing,
      plugins                => $plugins,
      ignore_changes         => $ignore_changes,
      acl_support            => $acl_support,
      onefs                  => $onefs,
      sparse                 => $sparse,
      compression            => $compression,
      fstype                 => $fstype,
      tag                    => "bareos::server::${bareos::director}"
  }
}

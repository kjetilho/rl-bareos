# Define: bareos::job::preset::s3::config
#
# Do not call directly.
#
# `host_base`:      the DNS suffix for the bucket storage.
# `user_name`:      the user to connect as
# `bucket`:         the bucket to backup
# `prefix`:         optionally restrict backup to this prefix
# `pattern`:        optionally restrict backup to folders matching this regexp
# `object_pattern`: optionally restrict backup to objects matching this regexp
#
define bareos::job::preset::s3::config(
  $client_name,
  $user_name,
  $bucket,
  $host_base = hiera('bareos::job::preset::s3::host_base', ''),
  $prefix = '',
  $pattern = '',
  $object_pattern = '',
  $base = '',
)
{
  $cmd = "bareos-make-s3-access ${user_name}"
  $_cmd = $host_base ? {
    ''      => $cmd,
    default => "${cmd} --host-base ${host_base}",
  }

  ensure_resource('exec', "bareos-make-s3-access ${user_name}", {
    command => $_cmd,
    path    => '/usr/local/sbin:/usr/sbin:/sbin:/usr/bin:/bin',
    creates => "/etc/bareos/s3/access-${user_name}.cfg",
    require => File['/usr/local/sbin/bareos-make-s3-access'],
  })

  $plugin = join(['python',
                  "module_path=${bareos::client::plugin_dir}",
                  'module_name=bareos-fd-s3',
                  "config=/etc/bareos/s3/access-${user_name}.cfg",
                  "bucket=${bucket}",
                  "prefix=${prefix}",
                  "pattern=${pattern}",
                  "object_pattern=${object_pattern}",
                  ], ':')

  ensure_resource('bareos::client::fileset', $title, {
    'client_name'   => $client_name,
    'fileset_name'  => "S3 ${title}",
    'onefs'         => true,
    'include_paths' => [ '/situla' ],
    'plugins'       => [ $plugin ],
  })
}

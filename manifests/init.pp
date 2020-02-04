# The "bareos" class is included by bareos::client, and keeps a shared
# secret for generating passwords.  This secret needs to be the same
# on the agent and on the backup server and it is recommended to store
# it in common.eyaml or similar.
class bareos(
  $director = 'dump-dir',
  $default_jobdef = 'DefaultJob',
  $default_base_jobdef = 'BaseJob',
  $default_secret = false,
  $default_schedules = {},
  $security_zone = '',
)
{
  # Passing values as class parameters will cause them to be stored in
  # plain text in PuppetDB, and this should be avoided.  The first
  # value for security reasons, the second for efficiency (the
  # schedule set can be big).
  $secret = hiera('bareos::secret', $default_secret)
  $schedules = hiera_hash('bareos::schedules', $default_schedules)
}

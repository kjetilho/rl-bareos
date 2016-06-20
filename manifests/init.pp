# The "bareos" class is included by bareos::client, and keeps a shared
# secret for generating passwords.  This secret needs to be the same
# on the agent and on the backup server and it is recommended to store
# it in common.eyaml or similar.
class bareos  (
  $director = 'dump-dir',
  $default_jobdef = 'DefaultJob',
  $security_zone = ''
)
{
  # Avoid storing these in PuppetDB.  The first for security reasons,
  # the second for efficiency.
  $secret = hiera('bareos::secret')
  $schedules = hiera_hash('bareos::schedules')
}

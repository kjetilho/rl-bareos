# The "bareos" class is included by bareos::client, and keeps a shared
# secret for generating passwords.  This secret needs to be the same
# on the agent and on the backup server and it is recommended to store
# it in common.eyaml or similar.
class bareos  (
  $director = 'dump-dir',
  $schedules,
  $secret
)
{

}

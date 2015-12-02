# Class: bareos::server
#
# This class collects backup configuration on a server
#
# It will install the basic software, but *not* configure the
# database, etc. etc.
#
class bareos::server(
  $client_file_prefix = '/etc/bareos/clients.d/',
  $job_file_prefix = '/etc/bareos/jobs.d/',
  $fileset_file_prefix = '/etc/bareos/filesets.d/',
  $secrets = {},
)
{
  validate_hash($secrets)

  include bareos
  require bareos::server::install

  file {
    [ $client_file_prefix, $job_file_prefix, $fileset_file_prefix ]:
      ensure  => directory,
      owner   => 'root',
      group   => 'bareos',
      mode    => '0755',
      purge   => true,
      recurse => true
  }

  Bareos::Client_definition <<| tag == "bareos::server::${bareos::director}" |>>
  Bareos::Job_definition <<| tag == "bareos::server::${bareos::director}" |>>
  Bareos::Fileset_definition <<| tag == "bareos::server::${bareos::director}" |>>

}

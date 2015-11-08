Bareos
======

1. [Server](#server)
2. [Client](#client)
  1. [Client parameters](#client_parameters)
  2. [Jobs](#jobs)
  3. [Job presets](#job_presets)
  4. [Filesets](#filesets)

# Server

The bareos::server installs the software and collects exported
resources associated with it.

In order to get a working setup, a few common Hiera keys must be set:

bareos::secret
bareos::director
bareos::client::schedules  *REFACTOR to bareos::schedules*

# Client

The bareos::client class will install the file daemon and configure it
with passwords.  It will also export resources (Client, Job, and
Fileset) which the director collects.

## Client parameters

__`bareos::client::password`__:
Set this parameter to get the same password on several clients.  This
is not the actual password used in the configuration files, for that
we hash it with `${bareos::secret}`.  We do that extra step to avoid
putting the actual password in PuppetDB.

__`bareos::client::concurrency`__:
How many jobs can run at the same time on this client.  Default: 10

__`bareos::client::implementation`__:
Either `bacula` or `bareos`.  Default: "bacula"

__`bareos::client::client_name`__:
The name of the client, without the "-fd" suffix.  Default: FQDN

__`bareos::client::name_suffix`__:
The suffix to use.  Default: "-fd"

__`bareos::client::address`__:
The address or hostname the director should connect to.  Default: FQDN.

__`bareos::client::job_retention`__:
How long to keep jobs from this client in the database.  Default: "180d"

__`bareos::client::file_retention`__:
How long to keep detailed information about backup job contents in the
database.  Default: "60d"

__`bareos::client::monitors`__:
Additional list of monitors to add to bacula-fd.conf.  Typical use:

    bareos::client::monitors:
      tray-mon:
        password: password-in-plain-text

Use eyaml to protect "password-in-plain-text".  All keys in the hash
are added as parameters to the Director directive.

##

  $monitors       = {},
  $jobs           = {},
  $filesets       = {},

## Jobs

Jobs are defined in the `bareos::client::jobs` hash.

The name of the resource is added to the client name and used as the
name of the job.  This will export a job_definition which the director
will pick up.

__`job_name`__: Specify the job name explicitly.

__`jobdef`__: The name of the job defaults.  Default: DefaultJob

__`fileset`__: The (full) name of the fileset.  Overrides the fileset
defined in the jobdef.

__`schedule_set`__: The name of the list of schedules to pick randomly
from.  Default: normal.

__`sched`__: Explicit name of schedule to override random selection.
(strange parameter name is due to `schedule` being a reserved word in
Puppet.)

__`runscript`__: Array of script specifications to run before or after
job.  Each script specification is a hash containing values for the
keys `command` and optionally `runswhen`.  `command` can in turn be an
array of strings to run.  `runswhen` is either `before` or `after`, by
default it is `before`.

__`preset`__: Use specified class to export the job.  See next
section.

__`preset_params`__: Parameters to pass to preset class.


## Job presets


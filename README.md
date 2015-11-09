Bareos
======

1. [Server](#server)
2. [Client](#client)
   1. [Client parameters](#client-parameters)
   2. [Jobs](#jobs)
   3. [Job presets](#job-presets)
      1. [mysqldumpbackup](#mysqldumpbackup)
      2. [pgdumpbackup](#pgdumpbackup)
      3. [Writing your own](#writing-your-own)
   4. [Filesets](#filesets)

# Server

The bareos::server installs the software and collects exported
resources associated with it.

In order to get a working setup, a few common Hiera keys must be set:

* bareos::secret
* bareos::director
* bareos::schedules

# Client

The bareos::client class will install the file daemon and configure it
with passwords.  It will also export resources (Client, Job, and
Fileset) which the director collects.

## Client parameters

__`bareos::client::password`__:
Set this parameter to get the same password on several clients.  This
is not the actual password used in the configuration files, this is
just a seed which is hashed with `${bareos::secret}`.  We do that
extra step to avoid putting the actual password in PuppetDB.  Default: FQDN

__`bareos::client::concurrency`__:
How many jobs can run at the same time on this client.  Default: 10

__`bareos::client::implementation`__:
Either `bacula` or `bareos`.  Default: "bacula"

__`bareos::client::client_name`__:
The name of the client, without the "-fd" suffix.  Default: FQDN

__`bareos::client::name_suffix`__:
The suffix to use.  Default: "-fd"

__`bareos::client::address`__:
The address or hostname the director should connect to.  Default: FQDN

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

## Jobs

Jobs are defined in the `bareos::client::jobs` hash.

Each key in the hash becomes the name of the resource.  This is added
to the client name and used as the name of the job.  A
`bareos::job_definition` with that name will be exported for the
director to pick up.

__`job_name`__: Specify the full job name explicitly.

__`jobdef`__: The name of the job defaults.  Default: DefaultJob

__`fileset`__: The (full) name of the fileset.  Overrides the fileset
defined in the jobdef.

__`schedule_set`__: The name of the list of schedules to pick randomly
from.  Default: normal

__`sched`__: Explicit name of schedule, overrides random selection.
(`schedule` is a reserved word in Puppet, hence the strange parameter name.)

__`runscript`__: Array of script specifications to run before or after
job.  Each element is a hash containing values for `command` and
optional other parameters.  `command` can be a single command or an
array of strings.  `runswhen` is either `before` or `after`, by
default it is `before`.  Other parameters are written verbatim as `Key
= value` to bareos configuration.

__`preset`__: Use specified class to export the job.  See next
section.

__`preset_params`__: Parameters to pass to preset class.


## Job presets

A job normally declares a job_define for `bareos::server` to pick up.
If `preset` is used, that declaration is the responsibility of the
preset define.  Such a preset define can additionally install scripts
or other software.

### mysqldumpbackup

This preset installs the script mysqldumpbackup and installs a
configuration file for it.  See
[code](manifests/job/preset/mysqldumpbackup.pp) for full list of
parameters.

Example usage:

    bareos::client::jobs:
      job1:
         preset:        bareos::job::preset::mysqldumpbackup
         preset_params:
           keep_backup: 5
           backupdir:   /srv/mysql/backup

### pgdumpbackup

This preset installs the script pgdumpbackup and installs a
configuration file for it.  See [code](manifests/job/preset/pgdumpbackup.pp) for details.


### Writing your own preset

The signature for a preset should be this:

    define widget::backup::preset::widgetdump(
        $jobdef,
        $fileset,
        $sched,
        $params,
    )

`title` for the define will be the full job name.

`jobdef` will be the empty string if the user didn't specify a jobdef
explicitly.  You should respect the user's wishes, but replace the
value of '' with a value which works for your preset.  (New job
defaults can not be defined in Puppet code, contact MS0 to add it to
main Git repo.)

`fileset` will normally be empty, and should just be passed on.

`sched` is the chosen schedule for this job.

`params` is the hash passed by the user as `preset_params`.  The
preset is free to specify its format and content.

The exported job should be declared like this:

    $_jobdef = $jobdef ? { '' => 'WidgetJob', default => $jobdef }
    @@bareos::job_definition {
        $title:
            client_name => $bareos::client::client_name,
            name_suffix => $bareos::client::name_suffix,
            jobdef      => $_jobdef,
            fileset     => $fileset,
            sched       => $sched,
            runscript   => [ { 'command' => '/usr/local/bin/widgetdump' } ],
            tag         => "bareos::server::${bareos::director}"
    }

Almost all of the above code must be copied more or less verbatim.  If
you don't need a runscript, you must pass an empty array.

You should try to write your define so it can be used more than once
per client, i.e., consider using `ensure_resource('file', { ... })`
instead of just `file` to avoid duplicate declarations.


## Filesets

The support for filesets is not complete, it is kept simple to focus
on filesets with static include and exclude rules.

The name of the resource is added to the client name and used as the
name of the fileset.  This will export a fileset_definition which the
director will pick up.

__`fileset_name`__: Specify the fileset name explicitly.

__`include_paths`__: Array of paths to include in backup.  Mandatory,
no default.

__`exclude_paths`__: Array of paths to exclude.

__`exclude_dir_containing`__: Directories containing a file with this
name will be skipped.  Set to "" to disable functionality.  Default:
".nobackup".

__`ignore_changes`__: If fileset changes, rerun Full backup if this is
set to `false`.  Default: true

__`acl_support`__: Include information about ACLs in backup.  Causes
an extra system call per file.  Default: true


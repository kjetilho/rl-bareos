require 'spec_helper'

describe 'bareos::client' do
  on_supported_os.each do |os, facts|

    case facts[:kernel]

    when 'windows'
      context "on #{os}" do
        let(:facts) { facts }
        it { should compile.with_all_deps }
        it do
          should contain_file('//localhost/c$/ProgramData/Bareos/bareos-fd.conf')
                  .with_content(/Name = "backup.example.com-dir"/)
        end
        it do
          should contain_service('Bareos-fd')
                  .with_enable(true)
                  .with_ensure('running')
        end
        it { should_not contain_file('/var/log/bacula') }
        it do
          expect(exported_resources).to have_bareos__job_definition_resource_count(1)
        end
        it do
          expect(exported_resources).to contain_bareos__client_definition("#{facts[:fqdn]}-fd")
        end
        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-system-job")
                                         .with_sched('NormalSchedule')
                                         .with_order('N50')
        end
      end

      # All the Unix tests
    else
      context "on #{os}" do
        let(:facts) { facts }
        it { should compile.with_all_deps }
        it do
          # These test against data from hiera, see
          # spec/fixtures/hiera/common.yaml
          should contain_file('/etc/bacula/bacula-fd.conf')
                  .with_content(/Name = "systray-mon"/)
                  .with_content(/Name = "backup.example.com-dir"/)
        end
        it do
          should contain_service('bacula-fd')
                  .with_enable(true)
                  .with_ensure('running')
        end
        it { should contain_file('/var/log/bacula')
                     .with_ensure('directory')
                     .with_owner('bacula')
                     .with_group('bacula')
        }
        it do
          expect(exported_resources).to have_bareos__job_definition_resource_count(1)
        end
        it do
          expect(exported_resources).to contain_bareos__client_definition("#{facts[:fqdn]}-fd")
        end
        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-system-job")
                                         .with_sched('NormalSchedule')
                                         .with_order('N50')
        end
      end

      context "on #{os} with bareos" do
        # Can't just use params, since other defaults build on Hiera
        # value, not passed value (chicken and egg)
        let(:facts) { facts.merge( { :specialcase => 'implementation' } ) }
        it { should compile.with_all_deps }
        it do
          # These test against data from hiera, see
          # spec/fixtures/hiera/common.yaml
          should contain_file('/etc/bareos/bareos-fd.conf')
                  .with_content(/Name = "systray-mon"/)
                  .with_content(/Name = "backup.example.com-dir"/)
        end
        case facts[:os]['family']
        when 'RedHat'
          it { should contain_file('/etc/bareos/bareos-fd.conf')
                       .with_content(%r{Plugin Directory\s+=\s+"/usr/lib64/bareos/plugins"})
          }
        when 'Debian'
          it { should contain_file('/etc/bareos/bareos-fd.conf')
                       .with_content(%r{Plugin Directory\s+=\s+"/usr/lib/bareos/plugins"})
          }
        end
        it do
          should contain_service('bareos-fd')
                  .with_enable(true)
                  .with_ensure('running')
        end
        it { should contain_file('/var/log/bareos')
                     .with_ensure('directory')
                     .with_owner('bareos')
                     .with_group('bareos')
        }
        it do
          expect(exported_resources).to have_bareos__job_definition_resource_count(1)
        end
        it do
          expect(exported_resources).to contain_bareos__client_definition("#{facts[:fqdn]}-fd")
        end
        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-system-job")
                                         .with_sched('NormalSchedule')
                                         .with_order('N50')
        end
      end

      context "on #{os} with jobs" do
        let(:facts) { facts }
        let(:params) do
          { :jobs => {
              'job1' => {},
              'job2' => {'schedule_set' => 'multiple'},
              'job3' => {'sched' => 'SpecialSchedule',
                         'order' => 'Z00'}
            }
          }
        end

        it { should compile.with_all_deps }
        it do
          expect(exported_resources).to have_bareos__job_definition_resource_count(3)
        end
        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-job1-job")
                                         .with_sched('NormalSchedule')
        end
        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-job2-job")
                                         .with_sched('Monday')
        end
        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-job3-job")
                                         .with_sched('SpecialSchedule')
                                         .with_order('Z00')
        end
      end

      context "on #{os} with fileset" do
        let(:facts) { facts }
        let(:params) do
          { :filesets => {
              'just_srv' => {'include_paths' => ['/srv'], 'acl_support' => false}
            },
            :jobs => {
              'srv' => {'fileset' => 'just_srv'}
            }
          }
        end

        it { should compile.with_all_deps }
        it do
          expect(exported_resources).to contain_bareos__fileset_definition("#{facts[:fqdn]}-just_srv")
                                         .with_include_paths(['/srv'])
                                         .with_acl_support(false)
        end
        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-srv-job")
                                         .with_fileset("#{facts[:fqdn]}-just_srv")
        end
      end

      context "on #{os} with client name and fileset" do
        let(:facts) { facts }
        let(:params) do
          { :filesets => {
              'just_srv' => {'include_paths' => ['/srv'], 'acl_support' => false}
            },
            :jobs => {
              'srv' => {'fileset' => 'just_srv'}
            },
            :client_name => 'client.example.com',
          }
        end

        it { should compile.with_all_deps }
        it do
          expect(exported_resources).to contain_bareos__fileset_definition("#{facts[:fqdn]}/client.example.com-just_srv")
                                         .with_include_paths(['/srv'])
                                         .with_acl_support(false)
        end
        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}/client.example.com-srv-job")
                                         .with_fileset("client.example.com-just_srv")
        end
      end

      context "on #{os} with system and service jobs" do
        let(:facts) { facts }
        let(:params) do
          { :filesets => {
              'root' => { 'include_paths' => ['/'] },
              'just_srv' => { 'client_name' => 'srv-fileset', 'include_paths' => ['/srv'] },
            },
            :jobs => {
              'sys' => {'fileset' => 'root'},
              'srv' => {'client_name' => 'srv.example.com', 'fileset' => 'just_srv'}
            },
          }
        end

        it { should compile.with_all_deps }
        it do
          expect(exported_resources).to contain_bareos__fileset_definition("#{facts[:fqdn]}/srv-fileset-just_srv")
                                         .with_include_paths(['/srv'])
        end
        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}/srv.example.com-srv-job")
                                         .with_fileset("srv-fileset-just_srv")
        end
        it do
          expect(exported_resources).to contain_bareos__fileset_definition("#{facts[:fqdn]}-root")
                                         .with_include_paths(['/'])
        end
        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-sys-job")
                                         .with_fileset("#{facts[:fqdn]}-root")
        end
      end

      context "on #{os} with preset mysqldumpbackup" do
        let(:facts) { facts }
        let(:params) do
          { :jobs => {
              'mysql' => {
                'preset' => 'bareos::job::preset::mysqldumpbackup',
                'preset_params' => { 'keep_backup' => 1 },
              },
              'mysql-ece' => {
                'order' => 'A01',
                'preset' => 'bareos::job::preset::mysqldumpbackup',
                'preset_params' => { 'instance' => 'ece', 'compress_program' => 'xz' },
              },
              'combo' => {
                'runscript' => [ { 'command' => '/usr/bin/combo' } ],
                'preset' => 'bareos::job::preset::mysqldumpbackup',
                'preset_params' => { 'instance' => 'combo',
                                     'backup_dir' => '/var/backups/combo' },
              }
            }
          }
        end


        it { should compile.with_all_deps }

        it { should contain_file('/var/backups')
                     .with_ensure('directory')
                     .with_mode('0755')
        }
        it { should contain_file('/var/backups/mysql')
                     .with_ensure('directory')
                     .with_mode('0750')
        }
        it { should contain_file('/usr/local/sbin/mysqldumpbackup') }
        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-mysql-job")
                                         .with_jobdef('DefaultMySQLJob')
                                         .with_order('N50')
                                         .with_runscript(
                                           { 'command' =>
                                             '/usr/local/sbin/mysqldumpbackup -c' }
                                         )
        end
        it { should contain_file('/etc/default/mysqldumpbackup')
                     .with_content(/KEEPBACKUP="1"/) }
        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-mysql-ece-job")
                                         .with_jobdef('DefaultMySQLJob')
                                         .with_order('A01')
                                         .with_runscript(
                                           { 'command' =>
                                             '/usr/local/sbin/mysqldumpbackup -c mysqldumpbackup-ece' }
                                         )
        end
        it { should contain_file('/etc/default/mysqldumpbackup-ece')
                     .with_content(/GZIP="xz"/)
        }

        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-combo-job")
                                         .with_jobdef('DefaultMySQLJob')
                                         .with_order('N50')
                                         .with_runscript(
                                           [ { 'command' =>
                                               '/usr/bin/combo' },
                                             { 'command' =>
                                               '/usr/local/sbin/mysqldumpbackup -c mysqldumpbackup-combo' }
                                           ])
        end
        it { should contain_file('/etc/default/mysqldumpbackup-combo')
                     .with_content(/KEEPBACKUP="3"/)
        }
        it { should contain_file('/var/backups/combo')
                     .with_ensure('directory')
                     .with_mode('0750')
        }
      end

      context "on #{os} with preset mysqldumpbackup ignore_not_running" do
        let(:facts) { facts }
        let(:params) do
          { :jobs => {
              'failover' => {
                'preset' => 'bareos::job::preset::mysqldumpbackup',
                'preset_params' => { 'ignore_not_running' => true },
              },
            },
            :manage_backup_dir => false
          }
        end

        it { should compile.with_all_deps }
        it { should contain_file('/usr/local/sbin/mysqldumpbackup') }
        it { should contain_file('/etc/default/mysqldumpbackup') }

        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-failover-job")
                                         .with_jobdef('DefaultMySQLJob')
                                         .with_runscript(
                                           { 'command' =>
                                             '/usr/local/sbin/mysqldumpbackup -c -r' }
                                         )
        end
        it { should_not contain_file('/var/backups') }
        it { should contain_file('/var/backups/mysql')
                     .with_owner('root')
                     .with_group('root')
                     .with_mode('0750')
        }
      end

      context "on #{os} with preset percona" do
        let(:facts) { facts.merge( { :specialcase => 'implementation' } ) }
        let(:params) do
          { :jobs => {
              'db' => {
                'preset' => 'bareos::job::preset::percona',
                'preset_params' => {
                  'mycnf' => '/etc/my.cnf'
                },
              },
            }
          }
        end

        it { should compile.with_all_deps }
        it { should contain_package('bareos-filedaemon-python-plugin') }
        it { should contain_package('percona-xtrabackup') }
        case facts[:os]['family']
        when 'RedHat'
          libdir = '/usr/lib64/bareos/plugins'
        when 'Debian'
          libdir = '/usr/lib/bareos/plugins'
        end

        it {
          should contain_file('/etc/bareos/bareos-fd.conf')
                   .with_content(%r{Plugin Directory\s+=\s+"#{libdir}"})
          should contain_file("#{libdir}/bareos-fd-percona.py")
          should contain_file("/etc/bareos/mysql-logbin-location")
          expect(exported_resources).to contain_bareos__fileset_definition("#{facts[:fqdn]}-percona")
                                          .with_plugins(["python:module_path=#{libdir}:module_name=bareos-fd-percona:mycnf=/etc/my.cnf"])
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-db-job")
                                         .with_jobdef('DefaultJob')
                                         .with_fileset("#{facts[:fqdn]}-percona")
        }
      end

      context "on #{os} with preset percona without logbin" do
        let(:facts) { facts.merge( { :specialcase => 'implementation' } ) }
        let(:params) do
          { :jobs => {
              'db' => {
                'preset' => 'bareos::job::preset::percona',
                'preset_params' => {
                  'skip_binlog' => true
                },
              },
            }
          }
        end

        it { should compile.with_all_deps }
        it { should contain_package('bareos-filedaemon-python-plugin') }
        it { should contain_package('percona-xtrabackup') }
        case facts[:os]['family']
        when 'RedHat'
          libdir = '/usr/lib64/bareos/plugins'
        when 'Debian'
          libdir = '/usr/lib/bareos/plugins'
        end

        it {
          should contain_file('/etc/bareos/bareos-fd.conf')
                   .with_content(%r{Plugin Directory\s+=\s+"#{libdir}"})
          should contain_file("#{libdir}/bareos-fd-percona.py")
          should_not contain_file("/etc/bareos/mysql-logbin-location")
          expect(exported_resources).to contain_bareos__fileset_definition("#{facts[:fqdn]}-percona")
                                          .with_plugins(["python:module_path=#{libdir}:module_name=bareos-fd-percona"])
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-db-job")
                                          .with_jobdef('DefaultJob')
                                          .with_include_paths([])
                                          .with_fileset("#{facts[:fqdn]}-percona")
        }
      end

      context "on #{os} with preset pgdumpbackup" do
        let(:facts) { facts }
        let(:params) do
          { :jobs => {
              'pg' => {
                'preset' => 'bareos::job::preset::pgdumpbackup',
                'preset_params' => { 'keep_backup' => 1 },
              },
            }
          }
        end

        it { should compile.with_all_deps }
        it { should contain_file('/usr/local/sbin/pgdumpbackup') }
        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-pg-job")
                                         .with_jobdef('DefaultPgSQLJob')
                                         .with_runscript(
                                           { 'command' =>
                                             '/usr/local/sbin/pgdumpbackup -c' }
                                         )
        end
        it { should contain_file('/etc/default/pgdumpbackup')
                     .with_content(/KEEPBACKUP="1"/) }
      end

      context "on #{os} with preset mylvmbackup" do
        let(:facts) { facts }
        let(:params) do
          { :jobs => {
              'mylvm' => {
                'preset' => 'bareos::job::preset::mylvmbackup',
                'preset_params' => { 'vgname' => 'rootvg',
                                     'lvname' => 'mysql',
                                   },
              },
              'wordpress' => {
                'preset' => 'bareos::job::preset::mylvmbackup',
                'preset_params' => { 'instance' => 'wp',
                                     'vgname' => 'rootvg',
                                     'lvname' => 'mysql',
                                     'relpath' => 'wpdata',
                                     'keep_backup' => 5,
                                   },
              },
            }
          }
        end

        it { should compile.with_all_deps }
        it { should contain_package('mylvmbackup') }

        # the test for runscript is way too intimate with implementation
        command = 'env HOME=/root /usr/bin/mylvmbackup'
        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-mylvm-job")
                                         .with_jobdef('DefaultMySQLJob')
                                         .with_runscript(
                                           [ { 'command' => "#{command} --action=purge" },
                                             { 'command' => "#{command}",
                                               "abortjobonerror" => true },
                                           ])
        end
        it { should contain_file('/etc/mylvmbackup.conf')
                     .with_content(/backupretention=3/)
                     .with_content(/vgname=rootvg/)
                     .with_content(/lvname=mysql/)
                     .with_content(/relpath=$/)
                     .with_content(/quiet=1/)
        }
        it { should contain_file('/var/backups/mylvmbackup')
                     .with_ensure('directory')
                     .with_mode('0750')
        }

        it do
          expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-wordpress-job")
                                         .with_jobdef('DefaultMySQLJob')
                                         .with_runscript(
                                           [ { 'command' => "#{command} -c /etc/mylvmbackup-wp.conf --action=purge" },
                                             { 'command' => "#{command} -c /etc/mylvmbackup-wp.conf",
                                               "abortjobonerror" => true },
                                           ])
        end
        it { should contain_file('/etc/mylvmbackup-wp.conf')
                     .with_content(/backupretention=5/)
                     .with_content(/vgname=rootvg/)
                     .with_content(/lvname=mysql/)
                     .with_content(/relpath=wpdata/)
        }
      end

      context "on #{os} with service address" do
        let(:facts) { facts }
        let(:params) do
          { :service_addr => {
              'test-service1.example.com' => {
                'concurrency' => 5,
              },
              'test-service2.example.com' => {
                'address' => '10.0.0.0',
              },
            }
          }
        end

        it { should compile.with_all_deps }
        it do
          expect(exported_resources).to contain_bareos__client_definition("#{facts[:fqdn]}/test-service1.example.com-fd")
                                         .with_address("test-service1.example.com")
                                         .with_concurrency(5)
        end
        it do
          expect(exported_resources).to contain_bareos__client_definition("#{facts[:fqdn]}/test-service2.example.com-fd")
                                         .with_address("10.0.0.0")
                                         .with_concurrency(10) # default in bareos::client
        end
      end

      context "on #{os} with self as service address" do
        let(:facts) { facts }
        let(:params) do
          { :service_addr => {
              'test-service1.example.com' => {
                'concurrency' => 5,
              },
              facts[:fqdn] => {
                'address' => '10.0.0.0',
              },
            }
          }
        end
        it { is_expected.to compile.and_raise_error(/own name.*service address/) }
      end

    end
  end
end

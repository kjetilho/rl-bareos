require 'spec_helper'

describe 'bareos::client' do
  on_supported_os.each do |os, facts|

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
        expect(exported_resources).to have_bareos__job_definition_resource_count(1)
      end
      it do
        expect(exported_resources).to contain_bareos__client_definition("#{facts[:fqdn]}-fd")
      end
      it do
        expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-system-job")
                                       .with_sched('NormalSchedule')
      end
    end

    context "on #{os} with jobs" do
      let(:facts) { facts }
      let(:params) do
        { :jobs => {
            'job1' => {},
            'job2' => {'schedule_set' => 'multiple'},
            'job3' => {'sched' => 'SpecialSchedule'}
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
        # This test depends on the result of fqdn_rand, so a change to
        # its parameters (including the implicit $fqdn) may cause this
        # test to fail.
        expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-job2-job")
                                       .with_sched('Wednesday')
      end
      it do
        expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-job3-job")
                                       .with_sched('SpecialSchedule')
      end
    end

    context "on #{os} with fileset" do
      let(:facts) { facts }
      let(:params) do
        { :filesets => {
            'srv' => {'include_paths' => ['/srv'], 'acl_support' => false}
          }
        }
      end

      it { should compile.with_all_deps }
      it do
        expect(exported_resources).to contain_bareos__fileset_definition("#{facts[:fqdn]}-srv")
                                       .with_include_paths(['/srv'])
                                       .with_acl_support(false)
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
              'preset' => 'bareos::job::preset::mysqldumpbackup',
              'preset_params' => { 'instance' => 'ece', 'compress_program' => 'xz' },
            },
          }
        }
      end

      it { should compile.with_all_deps }
      it { should contain_file('/usr/local/sbin/mysqldumpbackup') }
      it do
        expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-mysql-job")
                                       .with_jobdef('DefaultMySQLJob')
                                       .with_runscript(
                                         [ { 'command' =>
                                             '/usr/local/sbin/mysqldumpbackup -c' }
                                         ])
      end
      it { should contain_file('/etc/default/mysqldumpbackup')
                   .with_content(/KEEPBACKUP="1"/) }
      it do
        expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-mysql-ece-job")
                                       .with_jobdef('DefaultMySQLJob')
                                       .with_runscript(
                                         [ { 'command' =>
                                             '/usr/local/sbin/mysqldumpbackup -c mysqldumpbackup-ece' }
                                         ])
      end
      it { should contain_file('/etc/default/mysqldumpbackup-ece')
                   .with_content(/GZIP="xz"/)
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
        expect(exported_resources).to contain_bareos__client_definition("#{facts[:fqdn]}:test-service1.example.com-fd")
                                       .with_client_name("test-service1.example.com-fd")
                                       .with_address("test-service1.example.com")
                                       .with_concurrency(5)
      end
      it do
        expect(exported_resources).to contain_bareos__client_definition("#{facts[:fqdn]}:test-service2.example.com-fd")
                                       .with_client_name("test-service2.example.com-fd")
                                       .with_address("10.0.0.0")
                                       .with_concurrency(10) # default in bareos::client
      end
    end
  end
end

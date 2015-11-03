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
    end
    context "on #{os} with jobs" do
      let(:facts) { facts }
      let(:params) do
        { :jobs => {
            'job1' => {},
            'job2' => {'schedule_set' => 'multiple'},
            'job3' => {'schedule' => 'SpecialSchedule'}
          }
        }
      end

      it { should compile.with_all_deps }
      it do
        expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-job1")
                                       .with_schedule('NormalSchedule')
      end
      it do
        # This test depends on the result of fqdn_rand, so a change to
        # its parameters (including the implicit $fqdn) may cause this
        # test to fail.
        expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-job2")
                                       .with_schedule('Wednesday')
      end
      it do
        expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-job3")
                                       .with_schedule('SpecialSchedule')
      end
    end
  end
end

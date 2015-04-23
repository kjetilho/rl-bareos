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
                .with_content(/Name = "systray-dir"/)
                .with_content(/Name = "backup.example.com-dir"/)
      end
    end
  end
end

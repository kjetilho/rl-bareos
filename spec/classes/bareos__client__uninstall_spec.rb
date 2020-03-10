require 'spec_helper'

describe 'bareos::client::uninstall' do
  on_os({ :kernel => 'Linux' }).each do |os, facts|
    # need to set bareos::client::ensure absent via Hiera since we
    # inherit bareos::client which has default value present.
    let(:facts) { facts.merge({ :specialcase => 'absent' }) }
    context "on #{os}" do
      it {
        should contain_package('bareos-filedaemon')
                 .with_ensure(:absent)
      }
      it {
        should contain_service('bareos-fd')
                 .with_ensure(:stopped)
                 .with_enable(false)
      }
      it {
        should contain_file('/etc/bareos/bareos-fd.conf')
                 .with_ensure(:absent)
      }
    end
  end
end

require 'spec_helper'

describe 'bareos::server' do
  on_supported_os.each do |os, facts|
    next unless facts[:os]['name'] == 'Ubuntu'
    context "on #{os}" do
      let(:facts) { facts }
      it { should compile.with_all_deps }

      it { should contain_package('bareos-database-postgresql') }
    end
  end
end

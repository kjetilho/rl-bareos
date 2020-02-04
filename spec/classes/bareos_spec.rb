require 'spec_helper'

describe 'bareos' do
  on_supported_os.each do |os, facts|
    let(:facts) { facts }
    if Puppet.version.to_f >= 4
      context "on #{os}" do
        it { should compile.with_all_deps }
      end
    end
  end
end

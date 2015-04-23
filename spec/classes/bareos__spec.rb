require 'spec_helper'

describe 'bareos' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it { should compile.with_all_deps }
    end
  end
end

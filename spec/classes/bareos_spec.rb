require 'spec_helper'

describe 'bareos' do
  on_supported_os.each do |os, facts|
    let(:facts) { facts }
    context "on #{os} #{facts[:osfamily]}" do
      it { should compile.with_all_deps }
    end
  end
end

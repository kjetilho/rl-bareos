require 'spec_helper'

describe 'bareos::client::fileset' do
  context "basic fileset" do
    let(:title) { 'basic' }
    let(:params) { { :include_paths => ['/custom'] } }
    let(:facts) { RSpec.configuration.default_facts }
    let(:pre_condition) { <<-eot
      class bareos::client {
        $client_name = $::fqdn
        $fstype = ["rootfs", "ext3", "ext4"]
      }
      include bareos::client
      eot
    }
    it { should compile.with_all_deps }

    it do
      expect(exported_resources).to contain_bareos__fileset_definition("#{facts[:fqdn]}-basic")
                                     .with_include_paths(['/custom'])
                                     .with_acl_support(true)
                                     .with_ignore_changes(true)
                                     .with_exclude_dir_containing('.nobackup')
    end
  end

  context "fileset with custom name" do
    let(:title) { 'custom' }
    let(:params) { { :fileset_name => 'foo-name',
                     :include_paths => ['/'],
                     :fstype => ['ufs'],
                   } }

    it { should compile.with_all_deps }
    it do
      expect(exported_resources).to contain_bareos__fileset_definition('foo-name')
                                     .with_fstype(['ufs'])
    end
  end
end

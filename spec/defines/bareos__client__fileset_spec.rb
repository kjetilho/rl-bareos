require 'spec_helper'

describe 'bareos::client::fileset' do
  let(:pre_condition) { <<-eot
    class bareos::client {
      $compression = 'GZIP'
      $client_name = $::fqdn
      $fstype = ['rootfs', 'ext3', 'ext4']
      $exclude_paths = ['/mnt', '/var/cache']
      $exclude_patterns = {}
    }
    include bareos::client
    include bareos
    eot
  }
  context 'basic fileset' do
    let(:title) { 'basic' }
    let(:params) { { :include_paths => ['/custom'] } }
    let(:facts) { RSpec.configuration.default_facts }

    it { should compile.with_all_deps }
    it do
      expect(exported_resources).to contain_bareos__fileset_definition("#{facts[:fqdn]}-basic")
                                     .with_include_paths(['/custom'])
                                     .with_acl_support(true)
                                     .with_ignore_changes(true)
                                     .with_exclude_dir_containing('.nobackup')
                                     .with_exclude_paths(['/mnt', '/var/cache'])
    end
  end
  context 'fileset excluding paths' do
    let(:title) { 'basic' }
    let(:params) { { :include_paths => ['/custom'], :exclude_paths => ['/custom/tmp'] } }
    let(:facts) { RSpec.configuration.default_facts }

    it { should compile.with_all_deps }
    it do
      expect(exported_resources).to contain_bareos__fileset_definition("#{facts[:fqdn]}-basic")
                                     .with_include_paths(['/custom'])
                                     .with_acl_support(true)
                                     .with_ignore_changes(true)
                                     .with_exclude_dir_containing('.nobackup')
                                     .with_exclude_paths(['/custom/tmp'])
    end
  end

  context 'fileset excluding paths defaults' do
    let(:title) { 'basic' }
    let(:params) { { :include_paths => ['/custom'], :exclude_paths => ['defaults', '/custom/tmp'] } }
    let(:facts) { RSpec.configuration.default_facts }

    it { should compile.with_all_deps }
    it do
      expect(exported_resources).to contain_bareos__fileset_definition("#{facts[:fqdn]}-basic")
                                     .with_include_paths(['/custom'])
                                     .with_acl_support(true)
                                     .with_ignore_changes(true)
                                     .with_exclude_dir_containing('.nobackup')
                                     .with_exclude_paths(['/mnt', '/var/cache', '/custom/tmp'])
    end
  end

  context 'fileset excluding patterns' do
    let(:title) { 'no-jpeg' }
    let(:params) { { :include_paths => ['/'],
                     :exclude_patterns => { 'wild_file' => '*.jpg' } } }
    let(:facts) { RSpec.configuration.default_facts }

    it { should compile.with_all_deps }
    it do
      expect(exported_resources).to contain_bareos__fileset_definition("#{facts[:fqdn]}-no-jpeg")
                                     .with_include_paths(['/'])
                                     .with_acl_support(true)
                                     .with_ignore_changes(true)
                                     .with_exclude_dir_containing('.nobackup')
                                     .with_exclude_patterns({ 'wild_file' => '*.jpg' })
    end
  end

  context 'fileset with both excluding and including patterns' do
    let(:title) { 'both' }
    let(:params) { { :include_paths => ['/'],
                     :exclude_patterns => { 'wild_dir' => '/run/img*' },
                     :include_patterns => { 'wild_file' => '*.gif' } }
                   }
    let(:facts) { RSpec.configuration.default_facts }

    it { should compile.with_all_deps }
    it do
      expect(exported_resources).to contain_bareos__fileset_definition("#{facts[:fqdn]}-both")
                                     .with_include_paths(['/'])
                                     .with_acl_support(true)
                                     .with_ignore_changes(true)
                                     .with_exclude_dir_containing('.nobackup')
                                     .with_exclude_patterns({ 'wild_dir' => '/run/img*' })
                                     .with_include_patterns({ 'wild_file' => '*.gif' })
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

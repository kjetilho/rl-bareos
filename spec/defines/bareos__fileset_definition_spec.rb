require 'spec_helper'

describe 'bareos::fileset_definition' do

  let(:facts) { RSpec.configuration.default_facts }
  default_params = {
    :include_paths => ['/srv'],
    :exclude_paths => [],
    :exclude_dir_containing => '.nobackup',
    :ignore_changes => true,
    :acl_support => true,
  }

  prefix = '/etc/bareos/filesets.d/'
  let(:pre_condition) { <<-eot
      class bareos::server {
        $fileset_file_prefix = '#{prefix}'
      }
      include bareos::server
      eot
  }

  context "normal fileset" do
    let(:title) { "#{facts[:fqdn]}-normal" }
    let(:params) { default_params }

    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}#{title}.conf")
              .with_content(/Name\s+=\s+"#{title}"/)
              .with_content(/OneFS\s+=\s+no/)
              .with_content(/FSType\s+=\s+ext4/)
    end
  end

  context "one fs" do
    let(:title) { "#{facts[:fqdn]}-one" }
    let(:pre_condition) { <<-eot
      class bareos::server {
        $fileset_file_prefix = '#{prefix}'
      }
      include bareos::server
      eot
    }
    let(:params) { default_params.merge({ :onefs => true }) }

    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}#{title}.conf")
              .with_content(/Name\s+=\s+"#{title}"/)
              .with_content(/OneFS\s+=\s+yes/)
              .without_content(/FSType\s+=\s+ext4/i)
    end
  end

  context "duplicate declaration" do
    let(:title) { "fqdn1/service-fset" }
    let(:pre_condition) { <<-eot
      class bareos::server {
        $fileset_file_prefix = '#{prefix}'
      }
      include bareos::server
      bareos::fileset_definition { "fqdn2/service-fset":
        include_paths => ['/srv'],
        exclude_paths => [],
        exclude_dir_containing => '.nobackup',
        ignore_changes => true,
        acl_support => true,
      }
      eot
    }
    let(:params) { default_params }

    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}service-fset.conf")
              .with_content(/Name\s+=\s+"service-fset"/)
    end
  end
end

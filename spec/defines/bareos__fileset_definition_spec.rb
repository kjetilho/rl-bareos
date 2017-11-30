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
              .with_content(/Sparse\s+=\s+yes/)
              .with_content(/OneFS\s+=\s+no/)
              .with_content(/FSType\s+=\s+ext4/)
              .with_content(/Compression\s+=\s+GZIP$/)
    end
  end

  context "disabled compression" do
    let(:title) { "#{facts[:fqdn]}-normal" }
    let(:params) do
      default_params.merge(
        {
          'compression' => false
        })
    end

    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}#{title}.conf")
              .with_content(/Name\s+=\s+"#{title}"/)
              .with_content(/OneFS\s+=\s+no/)
              .with_content(/FSType\s+=\s+ext4/)
              .without_content(/Compression\s+=/)
    end
  end

  context "disabled sparse" do
    let(:title) { "#{facts[:fqdn]}-normal" }
    let(:params) do
      default_params.merge(
        {
          'sparse' => false
        })
    end

    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}#{title}.conf")
              .with_content(/Name\s+=\s+"#{title}"/)
              .with_content(/OneFS\s+=\s+no/)
              .with_content(/FSType\s+=\s+ext4/)
              .with_content(/Sparse\s+=\s+no/)
    end
  end

  context "filtered excludes" do
    let(:title) { "#{facts[:fqdn]}-normal" }
    let(:params) do
      default_params.merge(
        {
          :exclude_paths => ['/mnt', '/srv/tmp']
        })
    end

    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}#{title}.conf")
              .with_content(/Name\s+=\s+"#{title}"/)
              .with_content(/OneFS\s+=\s+no/)
              .with_content(/FSType\s+=\s+ext4/)
              .with_content(%r{File\s+=\s+"/srv"$})
              .with_content(%r{File\s+=\s+"/srv/tmp"$})
              .without_content(%r{File\s+=\s+"/mnt"$})
    end
  end

  context "unfiltered excludes" do
    let(:title) { "#{facts[:fqdn]}-normal" }
    let(:params) do
      default_params.merge(
        {
          :include_paths => ['/'],
          :exclude_paths => ['/mnt', '/srv/tmp']
        })
    end

    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}#{title}.conf")
              .with_content(/Name\s+=\s+"#{title}"/)
              .with_content(/OneFS\s+=\s+no/)
              .with_content(/FSType\s+=\s+ext4/)
              .with_content(%r{File\s+=\s+"/"$})
              .with_content(%r{File\s+=\s+"/mnt"$})
              .with_content(%r{File\s+=\s+"/srv/tmp"$})
    end
  end

  context "exclude patterns" do
    let(:title) { "#{facts[:fqdn]}-normal" }
    let(:params) do
      default_params.merge(
        {
          :include_paths    => '/',
          :exclude_patterns => {
            'wild_file' => '*.jpg',
            'regex_dir' => ['^/var/lib/postgresql/[^/]*/main',
                            '^/etc/postgresql/[^/]*/log',
                           ]
          }
        })
    end

    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}#{title}.conf")
              .with_content(/Name\s+=\s+"#{title}"/)
              .with_content(/OneFS\s+=\s+no/)
              .with_content(/FSType\s+=\s+ext4/)
              .with_content(%r{File\s+=\s+"/"$})
              .with_content(%r{Exclude\s+=\s+yes$})
              .with_content(%r{WildFile\s+=\s+"\*\.jpg"$})
              .with_content(%r{RegexDir = "\^/var/lib/postgresql/\[\^/\]\*/main"$})
              .with_content(%r{RegexDir = "\^/etc/postgresql/\[\^/\]\*/log"$})
    end
  end

  context "include patterns" do
    let(:title) { "#{facts[:fqdn]}-normal" }
    let(:params) do
      default_params.merge(
        {
          :include_patterns => {
            'wild_file' => '*.jpg',
          }
        })
    end

    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}#{title}.conf")
              .with_content(/Name\s+=\s+"#{title}"/)
              .with_content(/OneFS\s+=\s+no/)
              .with_content(/FSType\s+=\s+ext4/)
              .with_content(%r{File\s+=\s+"/srv"$})
              .with_content(%r{WildFile = "\*\.jpg"$\s+\}$\s+Options \{$\s+RegexFile = "\.\*"$\s+Exclude = yes$})
    end
  end

  context "include patterns with warning" do
    let(:title) { "#{facts[:fqdn]}-normal" }
    let(:params) do
      default_params.merge(
        {
          :include_patterns => {
            'wild_dir' => '/srv/a/ab/abc*',
          }
        })
    end

    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}#{title}.conf")
              .with_content(/Name\s+=\s+"#{title}"/)
              .with_content(/OneFS\s+=\s+no/)
              .with_content(/FSType\s+=\s+ext4/)
              .with_content(%r{File\s+=\s+"/srv"$})
              .with_content(%r{WildDir = "/srv/a/ab/abc\*"$\s+\}$\s+Options \{$\s+RegexDir = "\.\*"$\s+Exclude = yes$})
              .with_content(%r{WARNING})
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

  context "special fileset name", skip: "broken in rspec-puppet 2.5.0 and 2.6.1 .. 2.6.9" do
    let(:title) { "This isn't desired & wanted as a filename" }
    let(:params) { default_params }

    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}This_isn_t_desired_wanted_as_a_filename.conf")
              .with_content(/Name\s+=\s+"This isn't desired & wanted as a filename"/)
    end
  end
end

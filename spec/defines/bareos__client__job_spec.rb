require 'spec_helper'

describe 'bareos::client::job' do
  let(:pre_condition) { <<-eot
    class bareos::client {
      $name_suffix = '-fd'
      $job_suffix = '-job'
      $client_name = $::fqdn
      $filesets = {}
    }
    include bareos::client
    include bareos
    eot
  }
  context 'normal job' do
    let(:title) { 'normal' }
    let(:facts) { RSpec.configuration.default_facts }

    it { should compile.with_all_deps }
    it do
      expect(exported_resources).to have_bareos__job_definition_resource_count(1)
    end
    it do
      expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-normal-job")
                                      .with_jobdef('DefaultJob')
                                      .with_base('')
                                      .with_client_name(facts[:fqdn])
    end
  end
  context 'with base job' do
    let(:title) { 'normal' }
    let(:facts) { RSpec.configuration.default_facts }
    let(:params) { { :make_base_job => true } }

    it { should compile.with_all_deps }
    it do
      expect(exported_resources).to have_bareos__job_definition_resource_count(2)
    end
    it do
      expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-normal-job")
                                      .with_jobdef('DefaultJob')
                                      .with_sched('NormalSchedule')
                                      .with_base("#{facts[:fqdn]}-normal-job-base")
                                      .with_client_name(facts[:fqdn])
    end
    it do
      expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-normal-job-base")
                                      .with_jobdef('BaseJob')
                                      .with_sched('BaseSchedule')
                                      .without_base()
                                      .with_client_name(facts[:fqdn])
    end
  end

  context 'preset with base job' do
    let(:title) { 'preset:user' }
    let(:facts) { RSpec.configuration.default_facts }
    let(:params) {
      {
        :make_base_job => true,
        :preset => 's3',
      }
    }
    let(:pre_condition) { <<-eot
      class bareos::client {
        $name_suffix = '-fd'
        $job_suffix = '-job'
        $client_name = $::fqdn
        $filesets = {}
        $implementation = 'bareos'
        $python_plugin_package = []
        $plugin_dir = '/tmp'
        $service = 'bareos-fd'
        $compression = 'GZIP'
        $fstype = ['rootfs', 'ext3', 'ext4']
        $exclude_paths = ['/mnt', '/var/cache']
        $exclude_patterns = {}
        service { $service: }
      }
      include bareos::client
      include bareos
      eot
    }

    it { should compile.with_all_deps }
    it do
      expect(exported_resources).to have_bareos__job_definition_resource_count(2)
    end
    it do
      expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-preset:user-job")
                                      .with_jobdef('DefaultJob')
                                      .with_sched('NormalSchedule')
                                      .with_fileset('S3 preset:user')
                                      .with_base("#{facts[:fqdn]}-preset:user-job-base")
                                      .with_client_name(facts[:fqdn])
    end
    it do
      expect(exported_resources).to contain_bareos__job_definition("#{facts[:fqdn]}-preset:user-job-base")
                                      .with_jobdef('DefaultJob')
                                      .with_sched('BaseSchedule')
                                      .with_fileset('S3 preset:user')
                                      .with_base('')
                                      .with_client_name(facts[:fqdn])
    end
  end

end

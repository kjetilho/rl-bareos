require 'spec_helper'

describe 'bareos::client_definition' do

  let(:facts) { RSpec.configuration.default_facts }
  prefix = '/etc/bareos/clients.d/'
  let(:pre_condition) { <<-eot
      class bareos::client {
        $client_name = '#{title}'
        $client_name_suffix = '-fd'
      }
      include bareos::client
      class bareos::server {
        $client_file_prefix = '#{prefix}'
        $secret = 'foo'
      }
      include bareos::server
      eot
  }

  context "normal client" do
    let(:title) { "#{facts[:fqdn]}-fd" }
    let(:params) do
      {
        :password => 'bar',
        :address => facts[:fqdn],
        :job_retention => '180d',
        :file_retention => '30d',
        :concurrency => 7,
      }
    end
    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}#{title}.conf")
              .with_content(/Name\s+=\s+"#{title}"/)
              .with_content(/Address\s+=\s+#{facts[:fqdn]}/)
    end
  end

  context "service address" do
    let(:title) { "#{facts[:fqdn]}:service.example.com-fd" }
    let(:params) do
      {
        :password => 'bar',
        :client_name => 'service.example.com-fd',
        :address => facts[:fqdn],
        :job_retention => '180d',
        :file_retention => '30d',
        :concurrency => 7,
      }
    end
    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}service.example.com-fd.conf")
              .with_content(/Name\s+=\s+"service.example.com-fd"/)
              .with_content(/Address\s+=\s+#{facts[:fqdn]}/)
    end
  end
end

require 'spec_helper'

describe 'bareos::client_definition' do

  let(:facts) { RSpec.configuration.default_facts }
  default_params = {
    :password => 'bar',
    :address => '127.1.2.3',
    :job_retention => '180d',
    :file_retention => '30d',
    :concurrency => 7,
  }

  prefix = '/etc/bareos/clients.d/'
  let(:pre_condition) { <<-eot
      class bareos::server {
        $client_file_prefix = '#{prefix}'
        $secrets = { "dmz" => "dmzfoo" }
        include bareos
      }
      include bareos::server
      eot
  }

  context "normal client" do
    let(:title) { "#{facts[:fqdn]}-fd" }
    let(:params) { default_params }

    it { should compile.with_all_deps }

    # password is Digest::SHA1.hexdigest("foobar")
    it do
      should contain_file("#{prefix}#{title}.conf")
              .with_content(/Name\s+=\s+"#{title}"/)
              .with_content(/Address\s+=\s+127.1.2.3/)
              .with_content(/FDPort\s+=\s+9102/)
              .with_content(/Password\s+=\s+"8843d7f92416211de9ebb963ff4ce28125932878"/)
    end
  end

  context "service address" do
    let(:title) { "#{facts[:fqdn]}/service.example.com-fd" }
    let(:params) { default_params.merge({ :port => 19102 }) }
    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}service.example.com-fd.conf")
              .with_content(/Name\s+=\s+"service.example.com-fd"/)
              .with_content(/Address\s+=\s+127.1.2.3/)
              .with_content(/FDPort\s+=\s+19102/)
              .with_content(/Password\s+=\s+"8843d7f92416211de9ebb963ff4ce28125932878"/)
    end
  end

  # deprecated
  context "service address (old style)" do
    let(:title) { "#{facts[:fqdn]}:service.example.com-fd" }
    let(:params) { default_params.merge({ :client_name => 'service.example.com-fd' }) }
    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}service.example.com-fd.conf")
              .with_content(/Name\s+=\s+"service.example.com-fd"/)
              .with_content(/Address\s+=\s+127.1.2.3/)
              .with_content(/Password\s+=\s+"8843d7f92416211de9ebb963ff4ce28125932878"/)
    end
  end

  context "security zone" do
    let(:title) { "#{facts[:fqdn]}-fd" }
    let(:params) { default_params.merge({ :security_zone => 'dmz' }) }
    it { should compile.with_all_deps }

    it do
      should contain_file("#{prefix}#{title}.conf")
              .with_content(/Name\s+=\s+"#{title}"/)
              .with_content(/Address\s+=\s+127.1.2.3/)
              .with_content(/Password\s+=\s+"15ec3e5b62e413c7f21b561d88e6be179658610d"/)
    end
  end

  context "unknown security zone" do
    let(:title) { "#{facts[:fqdn]}-fd" }
    let(:params) { default_params.merge({ :security_zone => 'hmz' }) }

    it { should compile.and_raise_error(/secret for security zone 'hmz' unknown/) }
  end

end

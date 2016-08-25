require 'spec_helper'

describe 'bareos::server' do
  on_os({:operatingsystem => 'Ubuntu'}).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it { should compile.with_all_deps }
      it { should contain_package('bareos-database-postgresql') }
      ['clients', 'jobs', 'filesets'].each do |d|
        it { should contain_file("/etc/bareos/#{d}.d/")
                     .with_ensure('directory')
                     .with_owner('root')
                     .with_group('bareos')
                     .with_purge(true)
                     .with_recurse(true)
        }
      end
    end
 
    # The value of this test may be a bit dubious, since we have to
    # duplicate the collect code.  It does check that the client code
    # exports a correctly tagged resource.  Hopefully rspec-puppet
    # will be fixed so that <<| |>> isn't a noop.
    context "collect tag on #{os} " do
      let(:facts) { facts }
      let(:pre_condition) {
        [
          'include bareos::client',
          # workaround for <<| |>> not working in rspec context
          'Bareos::Client_definition <| tag == "bareos::server::${bareos::director}" |>'
        ]
      }
      it { should compile.with_all_deps }

      it { expect(exported_resources).to contain_bareos__client_definition("#{facts[:fqdn]}-fd") }
      it { should contain_bareos__client_definition("#{facts[:fqdn]}-fd") }
    end
  end
end

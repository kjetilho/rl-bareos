require 'spec_helper'

describe 'bareos::client::fileset' do
  context "basic fileset" do
    let(:title) { 'basic' }
    let(:params) { { :include_paths => ['/custom'] } }
    it { should compile.with_all_deps }

    # Unfortunately, $bareos::client::client_name is not available
    # since we don't want to pull in bareos::client inside
    # bareos::client::fileset, so the resource name is "wrong".

    it do
      expect(exported_resources).to contain_bareos__fileset_definition('-basic')
                                     .with_include_paths(['/custom'])
                                     .with_acl_support(true)
                                     .with_ignore_changes(true)
                                     .with_exclude_dir_containing('.nobackup')
    end
  end

  context "fileset with custom name" do
    let(:title) { 'custom' }
    let(:params) { { :fileset_name => 'foo-name', :include_paths => ['/'] } }

    it { should compile.with_all_deps }
    it do
      expect(exported_resources).to contain_bareos__fileset_definition('foo-name')
    end
  end
end

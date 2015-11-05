notification :emacs

directories %w(manifests templates spec/classes)

guard 'rake', task: 'test' do
  watch('Rakefile')
  watch(/^spec\/.+\_spec.rb$/)
  watch(/^manifests\/.+\.pp$/)
  watch(/^templates\/.+\.erb$/)
end

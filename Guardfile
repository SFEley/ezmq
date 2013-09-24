guard 'bundler' do
  watch('Gemfile')
  # Uncomment next line if Gemfile contain `gemspec' command
  watch(/^.+\.gemspec/)
end

guard :rspec,
      :all_after_pass => true,
      :all_on_start => true,
      :keep_failed => true do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^spec/.+_shared\.rb$}) { "spec" }
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
  watch(%r{^spec/support/.*})  { "spec" }
end

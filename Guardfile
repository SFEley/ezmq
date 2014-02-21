guard 'bundler' do
  watch('Gemfile')
  # Uncomment next line if Gemfile contain `gemspec' command
  watch(/^.+\.gemspec/)
end

guard :rspec,
      :all_after_pass => true,
      :all_on_start => true,
      :focus_on_failed => false,
      :keep_failed => true do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^(spec.*)/.+_shared\.rb$}) { |m| m[1] }
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
  watch(%r{^spec/support/.*})  { "spec" }

  # Weird EZMQ-specific directories
  watch(%r{^lib/ezmq/socket/(.+)\.rb$})  { |m| "spec/ezmq/sockets"}
end

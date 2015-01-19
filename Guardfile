guard 'bundler' do
  watch('Gemfile')
  # Uncomment next line if Gemfile contain `gemspec' command
  watch(/^.+\.gemspec/)
end

guard :rspec,
      :all_after_pass => true,
      :all_on_start => true,
      :cmd => 'bundle exec rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^(spec.*)/.+_shared\.rb$})     { |m| m[1] }
  watch('lib/ezmq.rb')                    { |m| "spec/ezmq_spec.rb" }
  watch(%r{^lib/ezmq/zmq[\d_]+/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')            { "spec" }

end

VCR.configure do |c|
  c.cassette_library_dir = File.join(Dir.pwd, 'spec', 'vcr')
  c.hook_into :webmock
end

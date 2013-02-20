Gem::Specification.new do |s|
  s.name = 'fps-timecode'
  s.version = '0.0.2'
  s.summary = 'Implements timecode class'
  s.description = 'A library to support drop-frame and non-drop-frame timecodes'
  s.author = 'Loran Kary'
  s.email = 'kary@focalpnt.com'
  s.files = Dir['lib/**/*.rb'] + Dir['test/*']+ Dir['doc/**/*']
  s.platform = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.required_ruby_version = '>=1.9'
  s.test_files = Dir['test/test*.rb']
  s.has_rdoc = true
  s.homepage    = 'http://focalpnt.com'
end
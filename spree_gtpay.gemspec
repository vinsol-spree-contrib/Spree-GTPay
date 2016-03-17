# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_gtpay'
  s.version     = '1.0.4'
  s.summary     = 'GTPay gateway'
  s.required_ruby_version = '>= 2.1.5'

  s.author    = 'Abhishek Jain'
  s.email     = 'info@vinsol.com'
  s.homepage  = 'http://vinsol.com'
  s.license   = "MIT"

  s.description = "Enable spree store to allow payment via GTPay, a GTBank Payment Gateway for Nigeria"

  s.files = Dir['LICENSE', 'README.md', 'app/**/*', 'config/**/*', 'lib/**/*', 'db/**/*']

  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 3.0.0'
  s.add_dependency 'sqlite3'
  s.add_dependency 'httparty'

end

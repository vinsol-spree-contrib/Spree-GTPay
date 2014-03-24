# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_gtpay'
  s.version     = '1.0.0'
  s.summary     = 'GTPay gateway'
  s.required_ruby_version = '>= 1.9.3'

  s.author    = 'Abhishek Jain'
  s.email     = 'info@vinsol.com'
  s.homepage  = 'http://www.vinsol.com'

  s.files = Dir['LICENSE', 'README.md', 'app/**/*', 'config/**/*', 'lib/**/*', 'db/**/*']
  
  s.require_path = 'lib'
  s.requirements << 'none'
  s.license   = "MIT"

  s.add_dependency 'spree_core', '~> 2.0.4'

  s.add_development_dependency 'capybara', '~> 2.1'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl', '~> 4.2'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 2.13'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
end

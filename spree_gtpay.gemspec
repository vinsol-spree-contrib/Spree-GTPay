# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_gtpay'
  s.version     = '1.0.3'
  s.summary     = 'GTPay gateway'
  s.required_ruby_version = '>= 1.9.3'

  s.author    = 'Abhishek Jain'
  s.email     = 'info@vinsol.com'
  s.homepage  = 'http://www.vinsol.com'
  s.license   = "MIT"

  s.description = "Enable spree store to allow payment via GtPay"



  s.files = Dir['LICENSE', 'README.md', 'app/**/*', 'config/**/*', 'lib/**/*', 'db/**/*']
  
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 2.0.0'
  s.add_dependency 'delayed_job_active_record', '~> 4.0.0'
  s.add_development_dependency 'capybara', '~> 2.1'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl', '~> 4.2'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 2.13'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'sqlite3'
end

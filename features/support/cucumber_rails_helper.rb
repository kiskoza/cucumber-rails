# frozen_string_literal: true

module CucumberRailsHelper
  def rails_new(options = {})
    options[:name] ||= 'test_app'
    command_result =
      run_command "bundle exec rails new #{options[:name]} --skip-bundle --skip-test-unit --skip-spring --skip-bootsnap #{options[:args]}"
    expect(command_result).to have_output(/README/)
    expect(last_command_started).to be_successfully_executed
    cd options[:name]
    delete_environment_variable 'RUBYOPT'
    delete_environment_variable 'BUNDLE_BIN_PATH'
    delete_environment_variable 'BUNDLE_GEMFILE'
  end

  def install_cucumber_rails(*options)
    add_conditional_gems(options)

    gem 'capybara', group: :test
    gem 'selenium-webdriver', '~> 3.11', group: :test
    gem 'rspec-expectations', '~> 3.7', group: :test
    gem 'database_cleaner', '>= 1.1', group: :test unless options.include?(:no_database_cleaner)
    gem 'factory_bot', '>= 3.2', group: :test unless options.include?(:no_factory_bot)

    run_command_and_stop 'bundle install'
    run_command_and_stop 'bundle exec rails webpacker:install' if rails6?
    run_command_and_stop 'bundle exec rails generate cucumber:install'
  end

  def gem(name, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}

    parts = ["'#{name}'"]
    parts << args.map(&:inspect) if args.any?
    parts << options.inspect[1..-2] if options.any?
    new_parts = parts.map { |part| part.gsub(/:(\w+)=>/, '\1: ') }
    line = "gem #{new_parts.join(', ')}\n"

    # These two lines below will be left in for a short time. See Commit SHA for details.
    #
    # Remove before v2.1 is cut
    gem_regexp = /gem ["']#{name}["'].*$/
    gemfile_content = File.read(expand_path('Gemfile'))

    append_to_file('Gemfile', line)
  end

  private

  def rails6?
    `bundle exec rails -v`.start_with?('Rails 6')
  end

  def add_conditional_gems(options)
    if options.include?(:not_in_test_group)
      gem 'cucumber-rails', path: File.expand_path('.').to_s
    else
      gem 'cucumber-rails', group: :test, require: false, path: File.expand_path('.').to_s
    end

    if rails6?
      gem 'sqlite3', '~> 1.4'
    else
      gem 'sqlite3', '~> 1.3.13'
    end
  end
end

World(CucumberRailsHelper)

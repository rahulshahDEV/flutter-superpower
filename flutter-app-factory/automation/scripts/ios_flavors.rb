# Uses Xcode's project model rather than editing PBX identifiers with regexes.
require 'json'
require 'xcodeproj'
app = ARGV.fetch(0)
data = JSON.parse(File.read(ARGV.fetch(1)))
project_path = File.join(app, 'ios/Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)
runner = project.targets.find { |t| t.name == 'Runner' }
raise 'Runner target missing' unless runner
# Flutter create can inherit a developer team from this machine; never persist it.
project.targets.each do |target|
  target.build_configurations.each { |c| c.build_settings.delete('DEVELOPMENT_TEAM') }
end
%w[dev prod].each do |flavor|
  %w[Debug Profile Release].each do |mode|
    name = "#{mode}-#{flavor}"
    ([project] + project.targets).each do |owner|
      original = owner.build_configurations.find { |c| c.name == mode }
      next unless original
      config = owner.build_configurations.find { |c| c.name == name }
      unless config
        config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
        config.name = name
        config.build_settings = Marshal.load(Marshal.dump(original.build_settings))
        config.base_configuration_reference = original.base_configuration_reference
        owner.build_configuration_list.build_configurations << config
      end
      if owner.equal?(runner)
        config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = data['flavors'][flavor]['ios_bundle_id']
        config.build_settings['APP_DISPLAY_NAME'] = data['app']['name'] + (flavor == 'dev' ? ' Dev' : '')
        config.build_settings['FLUTTER_TARGET'] = "lib/main_#{flavor}.dart"
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
        admob = flavor == 'dev' || !data['monetization']['admob'] ? 'ca-app-pub-3940256099942544~1458002511' : data['monetization']['ios_app_id']
        config.build_settings['ADMOB_APP_ID'] = admob
        team = data['ios']['team_id']
        config.build_settings['DEVELOPMENT_TEAM'] = team unless team.nil? || team.empty? || team == 'REPLACE_ME'
      elsif owner.respond_to?(:name) && owner.name == 'RunnerTests'
        config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = data['flavors'][flavor]['ios_bundle_id'] + '.RunnerTests'
      end
    end
  end
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(runner)
  scheme.launch_action.build_configuration = "Debug-#{flavor}"
  scheme.test_action.build_configuration = "Debug-#{flavor}"
  scheme.profile_action.build_configuration = "Profile-#{flavor}"
  scheme.analyze_action.build_configuration = "Debug-#{flavor}"
  scheme.archive_action.build_configuration = "Release-#{flavor}"
  scheme.save_as(project_path, flavor, true)
end
project.save

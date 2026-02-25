platform :ios, '18.2'
use_frameworks!
target 'zhengqaun' do
  
  pod 'SVProgressHUD'
  pod 'IQKeyboardManager'
  pod 'JJException'
  pod 'GKNavigationBarViewController'
  pod 'FCUUID'
  pod 'DGCharts'
  
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end


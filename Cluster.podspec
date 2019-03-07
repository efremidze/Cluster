Pod::Spec.new do |s|
  s.name             = 'Cluster'
  s.version          = '2.4.6'
  s.summary          = 'Map Clustering Library'
  s.homepage         = 'https://github.com/efremidze/Cluster'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'efremidze' => 'efremidzel@hotmail.com' }
  s.documentation_url = 'https://efremidze.github.io/Cluster/'
  s.source           = { :git => 'https://github.com/efremidze/Cluster.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'Sources/*.swift'
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/*.swift'
  end
end

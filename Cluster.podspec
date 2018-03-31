Pod::Spec.new do |s|
  s.name             = 'Cluster'
  s.version          = '2.1.3'
  s.summary          = 'Map Clustering Library'
  s.homepage         = 'https://github.com/efremidze/Cluster'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'efremidze' => 'efremidzel@hotmail.com' }
  s.source           = { :git => 'https://github.com/efremidze/Cluster.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'Sources/*.swift'
end

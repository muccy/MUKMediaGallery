Pod::Spec.new do |s|
  s.name      = 'MUKMediaGallery'
  s.version   = '2.0.0'
  s.summary   = 'A simple iOS library built to provide you a component which replicates Photos app functionalities.'
  s.license   = 'BSD 3-Clause'
  s.platform  = :ios, '7.0'
  s.homepage 	= 'https://github.com/muccy/MUKMediaGallery'
  s.author = {
    'Marco Muccinelli' => 'muccymac@gmail.com'
  }
  s.source = {
    :git => '.',
    :tag => s.version.to_s
  }
  s.source_files  = 'MUKMediaGallery/**/*.{h,m}'
  s.requires_arc  = true
  s.frameworks    = 'QuartzCore', 'MediaPlayer'
  s.resource      = 'MUKMediaGallery/MUKMediaGalleryResources.bundle'
  
  s.dependency    'MUKToolkit', '~> 1.1'
  s.dependency    'LBYouTubeView', '~> 0.0'
end
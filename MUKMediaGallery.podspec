Pod::Spec.new do |s|
  s.name      = 'MUKMediaGallery'
  s.version   = '2.1.2'
  s.summary   = 'A simple iOS library built to provide you a component which replicates Photos app functionalities.'
  s.license   = { :type => 'BSD 3-Clause', :file => 'LICENSE' }
  s.platform  = :ios, '6.0'
  s.homepage 	= 'https://github.com/muccy/MUKMediaGallery'
  s.author = {
    'Marco Muccinelli' => 'muccymac@gmail.com'
  }
  s.source = {
    :git => 'https://muccy@bitbucket.org/muccy/mukmediagallery.git',
    :tag => s.version.to_s
  } 
  s.compiler_flags      = '-Wdocumentation'
  s.source_files        = 'MUKMediaGallery/**/*.{h,m}'
  s.public_header_files = 'MUKMediaGallery/*.h'
  s.requires_arc        = true
  s.frameworks          = 'QuartzCore', 'MediaPlayer'
  s.resource_bundle     = { 'MUKMediaGalleryResources' => 'MUKMediaGallery/Resources/Images/**' }
  
  s.dependency          'MUKToolkit',     '~> 1.1'
  s.dependency          'LBYouTubeView',  '~> 0.0'
  
  s.subspec "ImageScrollView" do |sp|
    sp.source_files        = 'MUKMediaGallery/MUKMediaImageScrollView.{h,m}'
    sp.public_header_files = 'MUKMediaGallery/MUKMediaImageScrollView.h'
    sp.requires_arc        = true
  end
end
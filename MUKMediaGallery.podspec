Pod::Spec.new do |s|
  s.name         = 'MUKMediaGallery'
  s.version      = '2.0.0'
  s.platform     = :ios, '5.0'
  s.license		 = 'BSD 3-Clause'
  s.summary      = 'A simple iOS library built to provide you a component which replicates Photos app functionalities'
  s.homepage 	 = 'https://github.com/muccy/MUKMediaGallery'
  s.author       = { 'Marco Muccinelli' => 'muccymac@gmail.com' }
  s.source       = { :git => 'https://github.com/muccy/MUKMediaGallery.git', :commit => '26fc70b045aa86e03bb15ee5bdbff5769675a599' }
  s.source_files = 'MUKMediaGallery/**/*.{h,m}'
  s.requires_arc = true

  s.dependency 'PSTCollectionView'
end
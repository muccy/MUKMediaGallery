Pod::Spec.new do |s|
  s.name         = 'MUKMediaGallery'
  s.version      = '2.0.0'
  s.summary      = 'Browse and see medias on iOS'
  s.author = {
    'Marco Muccinelli' => 'muccymac@gmail.com'
  }
  s.source = {
    :git => '.',
    :tag => '2.0.0'
  }
  s.source_files = 'MUKMediaGallery/*.{h,m}'
end
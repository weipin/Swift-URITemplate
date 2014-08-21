#
# Be sure to run `pod lib lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Swift-URITemplate"
  s.version          = "0.1.2"
  s.summary          = "Swift implementation of URI Template."
  s.description      = <<-DESC
                       Swift-URITemplate is a Swift implementation of URI Template -- 
                       [RFC6570](http://tools.ietf.org/html/rfc6570), can expand templates up to and 
                       including Level 4 in that specification.
                       DESC
  s.homepage         = "https://github.com/weipin/Swift-URITemplate"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { "Weipin Xia" => "weipin@me.com" }
  s.source           = { :git => "https://github.com/weipin/Swift-URITemplate.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'source/*'
end

#
# Be sure to run `pod lib lint YTXRestfulModel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "YTXRestfulModel"
  s.version          = "0.5.0"
  s.summary          = "YTXRestfulModel 提供了restful的功能"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.homepage         = "http://gitlab.baidao.com/ios/YTXRestfulModel"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "caojun" => "78612846@qq.com" }
  s.source           = { :git => "http://gitlab.baidao.com/ios/YTXRestfulModel.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = ["Pod/Classes/Model/**/*", "Pod/Classes/Protocol/**/*"]

  DBType      = "DBSYNC"
  RemoteType  = "REMOTESYNC"
  StorageType = "STORAGESYNC"

  YTXRequestRemoteSync   = { :spec_name => "YTXRequestRemoteSync",    :type => RemoteType,   :dependency => [{:name => "YTXRequest",  :version => "~> 0.1.6" }] }
  FMDBSync               = { :spec_name => "FMDBSync",                :type => DBType,       :dependency => [{:name => "FMDB",        :version => "~> 2.6"   }] }
  UserDefaultStorageSync = { :spec_name => "UserDefaultStorageSync",  :type => StorageType                                                                    }

  $all_names = []

  $all_sync = [YTXRequestRemoteSync, FMDBSync, UserDefaultStorageSync]

  $all_sync.each do |sync_spec|
    s.subspec sync_spec[:spec_name] do |ss|

      specname = sync_spec[:spec_name]

      $all_names << specname

      sources = ["Pod/Classes/Sync/#{specname}/**/*"]

      ss.source_files = sources

      name_prefix_header_contents = "#define YTX_#{specname.upcase}_EXISTS 1"

      type_prefix_header_contents = ""

      if sync_spec[:type]
        type_prefix_header_contents = "#define YTX_#{sync_spec[:type].upcase}_EXISTS 1"
      end

      ss.prefix_header_contents = name_prefix_header_contents, type_prefix_header_contents

      if sync_spec[:dependency]
        sync_spec[:dependency].each do |dep|
          ss.dependency dep[:name], dep[:version]
        end
      end

    end
  end


  s.dependency 'Mantle', '~> 1.5.7'
  s.dependency 'ReactiveCocoa', '~> 2.3.1'

  spec_names = $all_names[0...-1].join(", ") + " 和 " + $all_names[-1]

  s.description = "提供了restful的model和collection。提供这些sync:#{spec_names}"
end

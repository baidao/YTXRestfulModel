#
# Be sure to run `pod lib lint YTXRestfulModel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "YTXRestfulModel"
  s.version          = "1.2.2"
  s.summary          = "YTXRestfulModel 提供了restful的功能"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.homepage         = "https://github.com/baidao/YTXRestfulModel"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "caojun" => "78612846@qq.com" }
  s.source           = { :git => "https://github.com/baidao/YTXRestfulModel.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true
  
  s.subspec "Default" do |ss|
    ss.source_files = ["Pod/Classes/Model/**/*", "Pod/Classes/Protocol/**/*"]
    ss.dependency 'Mantle', '~> 1.5.7'
  end
  
  s.subspec "RACSupport" do |ss|
      ss.source_files = ["Pod/Classes/RACSupport/**/*"]
      ss.dependency 'ReactiveCocoa', '~> 2.3.1'
      ss.dependency 'YTXRestfulModel/Default'
  end

  _AFNetworkingRemoteSync = { :spec_name => "AFNetworkingRemoteSync",   :dependency => [{:name => "AFNetworking",  :version => "~> 2.6.3"    }]  }
  _FMDBSync               = { :spec_name => "FMDBSync",                 :dependency => [{:name => "FMDB",          :version => "~> 2.6"      }]  }
  _UserDefaultStorageSync = { :spec_name => "UserDefaultStorageSync"                                                                             }

  _all_names = []

  _all_sync = [_AFNetworkingRemoteSync, _FMDBSync, _UserDefaultStorageSync]
  
  _all_sync.each do |sync_spec|
    s.subspec sync_spec[:spec_name] do |ss|

      specname = sync_spec[:spec_name]

      _all_names << specname

      sources = ["Pod/Classes/Sync/#{specname}/**/*"]

      ss.prefix_header_contents = "#define YTX_#{specname.upcase}_EXISTS 1"
      
      ss.source_files = sources
      
      ss.dependency 'YTXRestfulModel/Default'

      if sync_spec[:dependency]
        sync_spec[:dependency].each do |dep|
          ss.dependency dep[:name], dep[:version]
        end
      end

    end
  end
  

  s.default_subspec = 'Default'

  spec_names = _all_names[0...-1].join(", ") + " 和 " + _all_names[-1]

  s.description = "提供了restful的model和collection。提供这些sync:#{spec_names}"
end

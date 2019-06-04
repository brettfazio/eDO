public_headers = ["Service/Sources/EDOClientService.h",
                  "Service/Sources/EDOClientService+Device.h",
                  "Service/Sources/EDOClientServiceStatsCollector.h",
                  "Service/Sources/EDOHostNamingService.h",
                  "Service/Sources/EDOHostService.h",
                  "Service/Sources/EDOHostService+Device.h",
                  "Service/Sources/EDORemoteVariable.h",
                  "Service/Sources/EDOServiceError.h",
                  "Service/Sources/EDOServiceException.h",
                  "Service/Sources/EDOServicePort.h",
                  "Service/Sources/NSObject+EDOValueObject.h",
                  "Device/Sources/EDODeviceConnector.h",
                  "Device/Sources/EDODeviceDetector.h"]
private_headers = (Dir.glob("*/Sources/*.h")) - public_headers

original_string_or_regex = "Service/Sources/"
replacement_string = ""

print(Dir.home)

# Dir.glob will take care of the recursivity for you
# do not use ~ but rather Dir.home
Dir.glob("#{Dir.home}/Desktop/macshapa_v2/*") do |file_name|
  text = File.read(file_name)
  replace = text.gsub!(original_string_or_regex, replacement_string)
  File.open(file_name, "w") { |file| file.puts replace }
end

original_string_or_regex = "Channel/Sources/"
Dir.glob("#{Dir.home}/Desktop/macshapa_v2/*") do |file_name|
  text = File.read(file_name)
  replace = text.gsub!(original_string_or_regex, replacement_string)
  File.open(file_name, "w") { |file| file.puts replace }
end

original_string_or_regex = "Device/Sources/"
Dir.glob("#{Dir.home}/Desktop/macshapa_v2/*") do |file_name|
  text = File.read(file_name)
  replace = text.gsub!(original_string_or_regex, replacement_string)
  File.open(file_name, "w") { |file| file.puts replace }
end

original_string_or_regex = "Measure/Sources/"
Dir.glob("#{Dir.home}/Desktop/macshapa_v2/*") do |file_name|
  text = File.read(file_name)
  replace = text.gsub!(original_string_or_regex, replacement_string)
  File.open(file_name, "w") { |file| file.puts replace }
end

Pod::Spec.new do |s|

	s.name = "eDO"
	s.version = "2.0.10"
	s.summary = "ObjC and Swift remote invocation framework"
	s.homepage = "https://github.com/brettfazio/eDO"
	s.author = "Google Inc."
	s.summary = "eDistantObject provides users an easy way to make remote invocations between processes in Objective-C and Swift without explicitly constructing RPC structures."
	s.license = { :type => "Apache 2.0", :file => "LICENSE" }
	s.source = { :git => "https://github.com/brettfazio/eDO.git", :branch => "master" }

	s.source_files = "Channel/Sources/*.{m,h}", "Service/Sources/*.{m,h}", "Measure/Sources/*.{m,h}", "Device/Sources/*.{m,h}"
	# Can't have the public headers exist in the private headers as you won't be able to import them. Made vars at top because of this.
	s.public_header_files = public_headers
	s.private_header_files = private_headers

	s.ios.deployment_target = "10.0"
	s.osx.deployment_target = "10.10"
end

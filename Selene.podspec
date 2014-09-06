Pod::Spec.new do |s|
  s.name         = "Selene"
  s.version      = "1.0.1"
  s.summary      = "Selene is a library for scheduling background task operations."
  s.description  = <<-DESC
                   Similar to the linux scheduler, Selene calculates a task's goodness to determine whether
                   the task should be executed.
                   DESC

  s.homepage     = "https://github.com/linkedin/Selene"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.authors      = { "Kirollos Risk" => "krisk@linkedin.com" }
  s.social_media_url   = "http://twitter.com/kirorisk"

  s.platform      = :ios, "7.0"
  s.source        = { :git => "https://github.com/linkedin/Selene.git", :tag => "1.0.1" }
  s.source_files  = "Selene/*.{h,m}"
  s.framework     = "Foundation"
  s.requires_arc  = true
end
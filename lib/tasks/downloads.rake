require 'octokit'
require 'feedzirra'
require 'nokogiri'
require 'open-uri'

def gcode_downloads(project)
  downloads = []
  atom_url = "http://code.google.com/feeds/p/#{project}/downloads/basic"
  feed = Feedzirra::Feed.fetch_and_parse(atom_url)
  feed.entries.each do |entry|
    downloads << [entry.entry_id, entry.published]
  end
  downloads
end

def file_url(project, filename)
  "https://#{project}.googlecode.com/files/#{filename}"
end

def bintray_file_url(package, repo, filename)
  "https://dl.bintray.com/#{package}/#{repo}/#{filename}?direct"
end

def bintray_downloads(package, repo)
  downloads = []
  url = "https://dl.bintray.com/#{package}/#{repo}"
  doc = Nokogiri::HTML(open(url))
  doc.search('a').each do |link|
    downloads << link.content
  end

  downloads
end

# find newest mac and windows binary downloads
task :downloads => :environment do
  # find latest windows version
  project = "msysgit"
  repo = "git-for-windows"
  package = "Git-for-Windows"
  win_downloads = bintray_downloads("git-for-windows", "Git-for-Windows")
  win_downloads.each do |name|
    if m = /^Git-(.*?)-(.*?)(\d{4})(\d{2})(\d{2})\.exe/.match(name)
      version = m[1]
      puts version = version
      puts name
      puts url = bintray_file_url(repo, package, name)
      puts date = DateTime.new(Integer(m[3]), Integer(m[4]), Integer(m[5]))
      puts
      v = Version.where(:name => version).first
      if v
        d = v.downloads.where(:url => url).first_or_create
        d.filename = name
        d.platform = 'windows'
        d.release_date = date
        d.save
      end
    end
  end

  # find latest mac version
  project = "git-osx-installer"
  mac_downloads = gcode_downloads(project)
  mac_downloads.each do |url, date|
    name = url.split('/').last
    if m = /git-(.*?)-/.match(name)
      url = file_url(project, name)
      version = m[1]
      puts version = version
      puts name
      puts url
      puts date
      puts
      v = Version.where(:name => version).first
      if v
        d = v.downloads.where(:url => url).first_or_create
        d.filename = name
        d.platform = 'mac'
        d.release_date = date
        d.save
      end
    end
  end
end

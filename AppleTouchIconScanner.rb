#!/usr/bin/ruby

require 'net/http'
require 'open-uri'
require 'uri'
require 'yaml'
require 'hpricot'
require 'rubygems'
require 'progressbar'
require 'timeout'

module Timeout
class TimeoutError < StandardError
end
end


ICON_DIRECTORY = File.join(File.dirname(__FILE__), "icons")
IPOD_TOUCH = "Mozilla/5.0 (iPod; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML,like Gecko) Version/3.0 Mobile/3A100a Safari/419.3"
USER_AGENT = IPOD_TOUCH
errors = []

def print_help
  puts "Usage:"
  puts "ruby %s [-d|--download] file.txt|file.html|url [file2...]" % __FILE__
end

def download_file url, target
  location = URI.parse(url)
  Net::HTTP.start(location.host) { |http|
    resp = http.get(location.path)
    open(target, "wb") { |file|
      file.write(resp.body)
     }
  }
end

def download_icon domain, url
  location = URI.parse(url)
  path     = File.join(ICON_DIRECTORY, domain)
  filename = File.basename(url)
  filepath = File.join(ICON_DIRECTORY, domain, filename)
  icon_url = url.start_with?("http") ? url : File.join("http://", domain, url)
  
  begin
    Dir.mkdir(ICON_DIRECTORY) unless File.directory?(ICON_DIRECTORY)
    Dir.mkdir(path) unless File.directory?(path)
  rescue
    errors.push "Unable to create directories for icon download."
  end
  begin
    download_file(icon_url, filepath)
  rescue
    errors.push "Unable to download '%s'." % icon_url
  end
end
  







# command line execution
if __FILE__==$0
  
  files_to_scan = []
  do_download = false
  stats = {}
  link_stats = {}
  
  $*.each do |arg|
    if (arg[0,1]=="-")
      case arg
      when "-d", "--download" then do_download = true
      end
    elsif arg.is_a?(String) && !arg.strip.empty?
      files_to_scan.push arg
    end
  end
  
  if (files_to_scan.length<1) then
    print_help
    exit
  end
  
  stats['files-count']      = files_to_scan.length
  stats['files-scanned']    = 0
  stats['files-errors']     = 0
  stats['webpages-count']   = 0
  stats['webpages-scanned'] = 0
  stats['webpages-errors']  = 0
  stats['icons-count']      = 0
  stats['icons-errors']     = 0
  stats['icons-downloaded'] = 0
  
  files_to_scan.each do |file|
    if File.exists?(file) then
      begin
        puts "Processing %s" % file
        puts "----------"
        doc = open(file) { |f| Hpricot(f) }
        links = doc/"a"
        #links = links[188..195] # for testing
        stats['webpages-count'] += links.length
        stats['files-scanned'] += 1
      rescue
        errors.push "Error. Problem opening '%s'." % file
        stats['files-errors'] += 1
      end

      pbar = ProgressBar.new("Fetching", links.length)
      links.each do |link|
        # puts "Checking '%s'" % link.to_s
        begin
          page = open(link.attributes['href'], "User-Agent" => USER_AGENT) { |p| Hpricot(p) }
          
          # record link tag statistics
          link_tags = page.search("//link")
          link_tags.each do |tag|
            name = tag.attributes['rel']
            if (link_stats[name]==nil) then
              link_stats[name] = 1
            else 
              link_stats[name] += 1
            end
          end

          # pull out the apple-touch-icon link tags
          icons = page.search("//link[@rel~='apple-touch-icon']")
          domain = URI.parse(link.attributes['href']).host

          # download the icon file if request
          if (do_download) then
            begin
              icons.each do |i|
                download_icon(domain, i.attributes['href'])
              end
              stats['icons-downloaded'] += 1
            rescue
              errors.push "Problem downloading apple-touch-icon file '%s'." % i.attributtes['href']
              stats['icons-error'] += 1
            end
          end
          stats['webpages-scanned'] += 1
        rescue
          errors.push "Problems parsing '%s'" % link.attributes['href']
          stats['webpages-errors'] += 1
        end
        
        pbar.inc
      end
      
      
      
      pbar.finish
    else
      errors.push "'%s' was not found." % f
    end
  
  end
  
  print errors.to_yaml
  puts "\nStatistics"
  print stats.to_yaml
  puts "\nLink tag statistics:"
  print link_stats.to_yaml
  
end

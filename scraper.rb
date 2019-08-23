require 'mechanize'
require 'json'
require 'cgi'
require 'ruby-progressbar'

STATIC_FILE_SERVER = 'http://i.4cdn.org'

def show_threads(path, board)
  catalog = JSON.parse(@client.get("http://boards.4chan.org/#{board}/catalog.json").body)
  catalog.each do |page|
    page['threads'].each do |thread|
      puts CGI.unescapeHTML "\nThread ##{thread['no']}(R:#{thread['replies']}/I:#{thread['images']}): #{thread['sub']}"
      puts CGI.unescapeHTML thread['com'].slice(0, 100) if thread.has_key? 'com'
      print "Scrape? (y/n/q) "
      case STDIN.gets.chomp.downcase
      when "y", "yes"
        scrape_thread(path, board, thread['no'].to_s)
      when "q", "quit", "exit"
        puts "Quitting"
        Kernel.exit
      end
    end
  end
end

def scrape_thread(path, board, thread_no)
  path = File.join(File.expand_path(path), thread_no)
  Dir.mkdir(path) unless Dir.exists?(path)
  thread = JSON.parse(@client.get("http://boards.4chan.org/#{board}/thread/#{thread_no}.json").body)
  thread['posts'].keep_if {|post| post.has_key? 'filename'}
  progressbar = ProgressBar.create(:title => "Scraping thread ##{thread_no}",
                                :total => (thread['posts'].sum {|thr| thr['fsize'] } / 1048576.0).round(2),
                                :format => "%t: %c/%C MiB %E")
  threads = []
  thread['posts'].each do |post|
    threads << Thread.new do
      filename = '%d%s' % [post['tim'], post['ext']]
      @client.get([STATIC_FILE_SERVER, board, filename].join('/')).save!(File.join(path, filename))
      progressbar.progress += (post['fsize'] / 1048576.0).round(2)
    end
  end
  threads.each(&:join)
  # progressbar.finish
  puts
end

case ARGV.count
when 1
  @client = Mechanize.new
  scrape_thread('.', ARGV[0][%r(http://boards.4chan.org/([^/]+)/thread/\d+$), 1], ARGV[0][/\d+$/])
when 2
  @client = Mechanize.new
  Dir.mkdir(ARGV[0]) unless Dir.exists?(ARGV[0])
  show_threads(*ARGV)
when 3
  @client = Mechanize.new
  Dir.mkdir(ARGV[0]) unless Dir.exists?(ARGV[0])
  scrape_thread(*ARGV)
else
  puts "Usage: ruby scraper.rb path board [thread_no]"
end

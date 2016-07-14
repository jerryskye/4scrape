require 'nokogiri'
require 'httparty'
require 'cgi'
require 'ruby-progressbar'

def show_threads(board, path)
	kek = HTTParty.get("http://boards.4chan.org/#{board}/catalog")[/catalog = .*/]
	kek = eval(kek[0, kek.index(/var \w+ =/)].rstrip.chop)
	kek[:threads].each do |thread|
		puts CGI.unescapeHTML "\nThread ##{thread[0].to_s}(R:#{thread[1][:r]}/I:#{thread[1][:i]}): #{thread[1][:sub]}"
		puts CGI.unescapeHTML thread[1][:teaser].slice(0, 100)
		print "Scrape? (y/n/q) "
		case $stdin.gets.chomp.downcase
		when "y", "yes"
			scrape_thread(board, thread, path)
		when "q", "quit", "exit"
			puts "Quitting"
			break
		end
	end
end

def scrape_thread(board, thread, path)
	uri = "http://boards.4chan.org/#{board}/thread/#{thread[0]}"
	dir = "#{path}/#{thread[0]}_#{thread[1][:sub]}"
	Dir.mkdir(dir) unless Dir.exists?(dir)
	kek = Nokogiri::HTML(HTTParty.get(uri)).css('form#delform > div.board > div.thread > div.postContainer')
	max = thread[1][:i] + 1
	progress = ProgressBar.create(:title => "Scraping thread ##{thread[0]}", :total => max, :format => "%t: |%w|")
	kek.each do |post|
		link = post.css('div.post > div.file > a.fileThumb').first
		next if link.nil?
		link = link["href"].prepend("http:")
		File.write("#{dir}/#{link[/\d+\.\w+$/]}", HTTParty.get(link))
		progress.increment
	end
end

if ARGV.count == 2
	Dir.mkdir(ARGV[1]) unless Dir.exists?(ARGV[1])
	show_threads(ARGV[0], ARGV[1])
else
	puts "Usage: ruby scraper.rb board path"
end

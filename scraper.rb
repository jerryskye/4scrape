require 'nokogiri'
require 'open-uri'
require 'httparty'
require 'cgi'

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
	print "Scraping thread ##{thread[0]}:   0.0%" 
	dir = "#{path}/#{thread[0]}"
	Dir.mkdir(dir) unless Dir.exists?(dir)
	kek = Nokogiri::HTML(open(uri)).css('form#delform > div.board > div.thread > div.postContainer')
	i = 0
	max = (thread[1][:i] + 1).to_f
	kek.each do |post|
		link = post.css('div.post > div.file > a.fileThumb').first
		next if link.nil?
		link = link["href"].prepend("http:")
		File.write("#{dir}/#{link[/\d+\.\w+$/]}", HTTParty.get(link))
		i += 1
		printf "\b\b\b\b\b\b%5.1f%%", (i / max * 100)
	end
	puts
end

path = ARGV.include?("-p") ? ARGV[ARGV.index("-p") + 1] : "dw"
Dir.mkdir(path) unless Dir.exists?(path)
if board = ARGV.index("-b")
	show_threads(ARGV[board + 1], path)
else
	puts "Usage: ruby scraper.rb -b board [-p path]"
end

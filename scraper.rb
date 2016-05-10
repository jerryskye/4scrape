require 'pry'
require 'nokogiri'
require 'open-uri'
require 'httparty'
require 'cgi'

def show_threads(board, path = "dw")
	kek = HTTParty.get("http://boards.4chan.org/#{board}/catalog")[/catalog = .*/]
	kek = eval(kek[0, kek.index(/var \w+ =/)].rstrip.chop)
	kek[:threads].each do |thread|
		puts CGI.unescapeHTML "\nThread ##{thread[0].to_s}(R:#{thread[1][:r]}/I:#{thread[1][:i]}): #{thread[1][:sub]}"
		puts CGI.unescapeHTML thread[1][:teaser].slice(0, 100)
		print "Scrape? (y/n/q) "
		case gets.chomp.downcase
		when "y", "yes"
			scrape_thread(board, thread[0].to_s, path)
		when "q", "quit", "exit"
			break
		end
	end
end

def scrape_thread(board, thread, path)
	uri = "http://boards.4chan.org/#{board}/thread/#{thread}"
	puts "Scraping #{uri}"
	dir = "#{path}/#{thread}"
	Dir.mkdir(dir) unless Dir.exists?(dir)
	kek = Nokogiri::HTML(open(uri)).css('form#delform > div.board > div.thread > div.postContainer')
	kek.each do |post|
		link = post.css('div.post > div.file > a.fileThumb').first
		next if link.nil?
		link = link["href"].prepend("http:")
		File.write("dw/#{thread}/#{link[/\d+\.\w+$/]}", HTTParty.get(link))
	end
end
pry

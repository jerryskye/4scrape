require 'pry'
require 'httparty'
require 'cgi'

def show_threads(board)
	kek = HTTParty.get("http://boards.4chan.org/#{board}/catalog")
	kek = kek[/catalog = .*/]
	kek = kek[0, kek.index(/var \w+ =/)].rstrip.chop
	kek = eval kek
	kek[:threads].each do |thread|
		puts CGI.unescapeHTML "\nThread ##{thread[0].to_s}(R:#{thread[1][:r]}/I:#{thread[1][:i]}): #{thread[1][:sub]}"
		puts CGI.unescapeHTML thread[1][:teaser].slice(0, 100)
		print "Scrape? (y/n/q) "
		case gets.chomp.downcase
		when "y", "yes"
			scrape_thread(board, thread[0].to_s)
		when "q", "quit", "exit"
			break
		end
	end
end

def scrape_thread(board, thread)
	uri = "http://boards.4chan.org/#{board}/#{thread}"
	puts "Scraping #{uri}"
end
pry

#!/usr/bin/env ruby
#
# Comics - weekly notifier
#   by Chris Brasington
# https://github.com/chrisbrasington/comic-books-weekly
#
# comiclist.com tends to update on Monday, so this is most accurate
#   after Monday and before the next week.
#
require 'rss'
require 'open-uri'
require 'nokogiri'
require 'yaml'
require 'net/https'
require 'date'
require './settings'

# remove html
def sanitize s
   s = Nokogiri::HTML(s).text
   s = s.gsub(/\(.*\)/, "")
end

# comic class from csv
class Comic
  attr_accessor :name, :price, :short_name
  def initialize(csv)
    begin
      data = sanitize(csv).split(',')
      @name = data[0].chomp(' ')
      @price = data[1].delete(' ').sub!('$', '').to_f
      # short name is lowercase name without issue #
      @short_name = @name.downcase.split('#')[0].chomp(' ')
    rescue
    end
  end
  def to_s
    s = @name
  end
end

# pushover notification
def pushover(apptoken, usertoken, message)
  puts 'Responding via pushover.'
  puts
  url = URI.parse("https://api.pushover.net/1/messages.json")
  req = Net::HTTP::Post.new(url.path)
  req.set_form_data({
                        :token => apptoken,
                        :user => usertoken,
                        :message => message,
                    })
  res = Net::HTTP.new(url.host, url.port)
  res.use_ssl = true
  res.verify_mode = OpenSSL::SSL::VERIFY_PEER
  res.start {|http| http.request(req) }
end

# 0 - Sunday
# 1 - Monday
# 2 - Tuesday 
# 3 - Wednesday
# 4 - Thursday
# 5 - Friday
# 6 - Saturday
def get_wednesday 
  # Wednesday
  if Date.today.wday == 3
    return Date.today
  end
  # add if Sunday, Monday, Tuesday
  if(Date.today.wday < 3)
    return Date.today + (3 - Date.today.wday)
  end
  
  # subtract if Thursday, Friday, Saturday
  return Date.today - (Date.today.wday - 3)
end

# parse date from feed title
def get_feed_date(item)
  date = item.to_s[/\<title>(.*?)<\/title>/,1] 
  
  if date.nil?
    date = item.to_s[/for (.*?) \(/,1] 
  else
    date.slice! "ComicList: New Comic Book Releases List for "
    date.slice! " (1 Week Out)"
  end

  return Date.strptime(date,"%m/%d/%Y")
end

# parse a week of comic content
def parse_feed_item(item, pull)

  # gather all wildcarded pull items
  wildcards = []
  pull.each do |p|
    if p.include? '*' 
      wildcards.push(p.dup.gsub!('*',''))
    end
  end

  # found comics
  comics = []

  # clean up item
  item = Nokogiri::HTML(item.to_s).text.to_s
  item = item.gsub("\n",'')

  # split per row
  item.to_s.split('<br />').each do |row|
      
    # looking only for numbered issues (not tradeback (TP) or AR merchandise)
    # remove the + ' #' if you want to allow less 'full titles'
    #   for example, 'Star Wars' will pick up seoncary comics like 'Star Wars Darth Vader'
    #   with the space #, it'll only pick up strictly 
    #   'Star Wars #' comics of that single series
    # 'annual' allows catching annuals of comics in pull, not specified as annuals
    # skip variants, they can show up weeks after initial release
    if row.include? '#' and not row.include? "Variant"
      # comic object
      comic = Comic.new(row.to_s)

      # skip over bad parse
      if comic.nil? or comic.short_name.nil?
        next
      end
      
      # if not already added (avoid duplicates)
      #   and matches a record in the pull.
      # This second check helps remove accidental wildcarding
      # Example: if you're looking for 'Batman' the include? will
      #   also pick up 'All-Star Batman'. 
      # It'll only accept if it is in the pull text
      #   with the exception of annuals.
      if !comics.any? {|c| c.name == comic.name} and 
        (
          pull.any?{ |p| p.to_s == comic.short_name} or
          pull.any?{ |p| p.to_s + " annual" == comic.short_name} 
        )
        # add comic
        comics.push(comic)
      # check comic against any wildcards in the pull
      # Example: "batman creature*" will be found within "batman creature of the night"
      #   "nightwing*" will be found within "nightwing the new order"
      else
        wildcards.each do |w|
          if comic.short_name.include? w.to_s and !comics.any? {|c| c.name == comic.name}
            comics.push(comic)
          end
        end
      end
    end
  end
  # sort and print
  comics = comics.sort_by { |c| [-c.name] }
  
  return comics
end

# using date parsed out of feed
# compare to current wednesday and create
# readable message
def get_week_message(feed_date)

  response = ''

  # subtract days apart
  dif = (get_wednesday()-feed_date)

  # this week
  if dif == 0
    response = 'This Week'
  else
    # 1 week difference
    if dif.abs <= 7
      response = 'One Week '
    # 2 week difference
    elsif dif.abs <= 14
     response = 'Two Weeks '
    # 3+ week difference (use number)
    elsif dif.abs <= 21
      response = (dif.abs/7) + ' Weeks '
    end
    # future - 1 week away as "next week"
    if dif < 0 and dif.abs <= 7
      response = 'Next Week'
    # X weeks in the future
    elsif dif < 0
      response += 'Away'
    # past - 1 week ago as "last week"
    elsif dif > 0 and dif.abs <= 7
      response = 'Last Week'
    # X weeks in the past
    else
      response += 'Ago'
    end
  end

  # special - non-Wednesday feed date
  # such as halloween or local comicbook shop day
  #   (maybe free-comic-book-day or batman day but those are likely on wednesday already)
  if feed_date.wday != 3
    # message the day of the week difference
    response += ' ' + feed_date.strftime("%A").upcase
  end

  return response
end

# parse any week against pull
# track dates to avoid duplication if called multiple times
#   with different feed
def parse_week(feed, pull, full_message, dates_tracked)
  # parse this week, then last week
  feed.items.each do |item|
  
    # partial message of this feed
    message = ''

    # parse comics from feed
    comics = parse_feed_item(item, pull)

    # wednesday
    wed_feed = get_feed_date(item)

    # if date already tracked from prior feed run, skip
    if dates_tracked.include? wed_feed
      next
    end
    dates_tracked.push(wed_feed)

    # get weekly message
    message += get_week_message(wed_feed) + " (" + wed_feed.strftime("%m/%d/%Y") + ") "

    # individual comic message
    comics_message = ""

    # aggregate week price
    price = 0

    # add each comic to message
    comics.each do |c|
      price += c.price.to_f
      comics_message += c.to_s
      comics_message += "\n"
    end

    # append message  
    message += "- $" + price.round(2).to_s + "\n"
    message += comics_message
    full_message += message
    full_message += "\n"
  end

  return full_message
end

# main program
def main()

  # provide pull list file
  if ARGV.empty?
    puts 'Please provide pull list.'
    exit
  end

  # dates tracked to avoid duplication with multiple feeds
  dates_tracked = []

  # individual feed message
  feed = ''

  # weekly comic feed
  url_this_week = 'http://feeds.feedburner.com/comiclistfeed?format=xml'

  # next weeks comic feed
  url_next_week = 'http://feeds.feedburner.com/comiclistnextweek?format=xml'

  # pull list of comics
  pull = File.read(ARGV[0]).split("\n").map(&:downcase)

  # parse RSS feed
  # this week and last week (typically) 
  # sometimes (on Sunday or Monday) this may be last week and 2 weeks ago
  open(url_this_week) do |rss|
    feed = RSS::Parser.parse(rss)
  end

  # pushover message
  full_message = parse_week(feed, pull, '', dates_tracked)

  # parse RSS feed
  # next week feed (typically)
  # sometimes (on Sunday or Monday) this may be the current week
  open(url_next_week) do |rss|
    # parse RSS
    feed = RSS::Parser.parse(rss)
  end

  # pushover message
  full_message = parse_week(feed, pull, full_message, dates_tracked)

  # display full message
  puts full_message

  # if pushover setting exists, respond via pushover
  if !ARGV[1].nil?
    settings = Settings.new(ARGV[1])
    if !settings.list['pushover'].nil?
      apitoken = settings.list['pushover']['apitoken']
      usertoken = settings.list['pushover']['userkey']
      pushover(apitoken, usertoken, full_message)
    end
  end
end

# run main
main()
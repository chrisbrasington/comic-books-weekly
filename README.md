## Comics - Weekly Notifier

Parses [Comicslist](http://www.comiclist.com/index.php) weekly RSS feed looking for comics included in pull.txt to generate a list of comics which came out this week on Wednesday (and special days like free-comic-book day). TP (Trade Paperbacks) and AR (Ask Retailer Pricing) Merchandise is ignored. Variants (dupes) are ignored.

#### Parameters:
```
comics.rb pull.txt settings.yml 
```
First parameter is pull list. Second parameter is pushover settings file. If [PushOver](https://pushover.net/) settings exist, notification is sent via PushOver.
#### Sample pull.txt
```
Batman
Batman White Knight
Bombshells*
Invader Zim
Mister Miracle
Phoenix*
Spider-Man Deadpool #26
Star Wars
Star Wars Darth Vader
```
#### Pull configuration:
Looking only for numbered issues (not tradeback (TP) or AR merchandise). Skip variants, they can show up weeks after initial release. Include annuals.

Titles are strict to main series: name + ' #'. Example: 'Batman' will only grab 'Batman #'. If extra series are desired, pull file should include a wildcard symbol '*'.

'Batman' will grab only main series...
```
'Batman #' and 'Batman Annual #'
```
 'Batman*' will grab everything batman related..
```
'Batman #', 'Batman Beyond #', 'All-Star Batman #', 'Batman and Robin #', 'Batman White Knight #' etc..
```
'Nightwing*' will grab..
```
'Nightwing #' and 'Nightwing New Order #'
```
'Batman Creature*', though wildcarded, will only grab one series:
```
'Batman Creature of the Night'
```
Spider-Man Deadpool #26, because pull file includes '#' in-line, only that single issue will pull that single issue.
```
'Spider-Man Deadpool #26'
```
    
#### Sample Input
This week: [http://www.comiclist.com/index.php/newreleases/this-week](http://www.comiclist.com/index.php/newreleases/this-week)
Next week: [https://feeds.feedburner.com/comiclistnextweek](https://feeds.feedburner.com/comiclistnextweek)
#### Sample Output
```
This Week (01/10/2018) - $15.96
  Mister Miracle #6
  Phoenix Resurrection The Return Of Jean Grey #3 *
  Spider-Man Deadpool #26
  Star Wars Darth Vader #10

Last Week (01/03/2018) - $17.95
  Batman #38
  Batman White Knight #4
  Bombshells United #9
  Phoenix Resurrection The Return Of Jean Grey #2 *
  Star Wars #41

Next Week (01/17/2018) - $9.97
  Batman #39
  Bombshells United #10
  Star Wars #42
```

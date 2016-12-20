## Comics - Weekly Notifier

Parses [Comicslist](http://www.comiclist.com/index.php) weekly RSS feed looking for comics included in pull.txt to generate a list of comics which came out this week on Wednesday. TP (Trade Paperbacks) and AR (Ask Retailer Pricing) Merchandise is ignored. Dupes (variants) are ignored.

If [PushOver](https://pushover.net/) settings exist, notification is sent via PushOver.

### Sample pull.txt
```
Descender
Futurama
Invader Zim
Star Wars
```
### Sample Input
Releases from [this week](http://www.comiclist.com/index.php/newreleases/this-week).
```
<p><strong><u>ONI PRESS</u></strong><br />
<a href="http://comics.gocollect.com/priceguide/view/962026">Invader Zim #16 (Cover A Aaron Alexovich)</a>, $3.99<br />
<a href="http://comics.gocollect.com/priceguide/view/962027">Invader Zim #16 (Cover B Shmorky)</a>, $3.99<br />
<a href="http://comics.gocollect.com/priceguide/view/962665">Night's Dominion #4</a>, $3.99<br />
</p>
```
### Sample Output
```
This Week 12/21/2016
Invader Zim #16
```
### Full Output
```
Comics: This Week (12/21/2016)
Invader Zim #16

Last Week (12/14/2016)
Descender #17

Next Week (12/28/2016)
Monstress #9
Rick And Morty #21
Star Wars #26
```
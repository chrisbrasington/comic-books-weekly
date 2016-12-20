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
12/14/16,IMAGE COMICS,Descender #17,$2.99
12/14/16,IMAGE COMICS,Descender Volume 3 Singularities TP,$14.99
12/14/16,IMAGE COMICS,Drifter #15 (Cover A Nic Klein),$3.99
12/14/16,IMAGE COMICS,Drifter #15 (Cover B David Rubin),$3.99
12/14/16,IMAGE COMICS,Fuse #24,$3.99
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
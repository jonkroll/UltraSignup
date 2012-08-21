UltraSignup for iOS
=============

This was an early prototype I built some time back of an iPhone client to UltraSignup.com, a database of trail race and ultramathon results.  It was built against an early, unreleased API that still has not been completed, and as a result some of the data access is quite slow.  Also, since it was started a while back it doesn't take full advantage of some more modern iOS development techniques.  However I think the layout and design is good, and I would like to return to this in the future if the UltraSignup API matures and becomes fully available.

Features:
-------------

* Search for runner name or event name
* See past results for a runner
* See results for all past dates of any event
* Filter results by gender
* See event location on map (using MapKit)
* View results from recent races in your area (using CoreLocation)
* Read recent news headlines from Ultrarunning.com (from RSS feed)
* Downloaded result listings are cached


Sample Screenshots:
-------------

![UltraSignup Screenshot 1](https://github.com/downloads/jonkroll/UltraSignup/ultrasignup-screenshot-1.png)
![UltraSignup Screenshot 2](https://github.com/downloads/jonkroll/UltraSignup/ultrasignup-screenshot-2.png)
![UltraSignup Screenshot 3](https://github.com/downloads/jonkroll/UltraSignup/ultrasignup-screenshot-3.png)

![UltraSignup Screenshot 4](https://github.com/downloads/jonkroll/UltraSignup/ultrasignup-screenshot-4.png)
![UltraSignup Screenshot 5](https://github.com/downloads/jonkroll/UltraSignup/ultrasignup-screenshot-5.png)
![UltraSignup Screenshot 6](https://github.com/downloads/jonkroll/UltraSignup/ultrasignup-screenshot-6.png)


Credit to Open Source iOS Libraries used
-------------

- [ASIHTTPRequest](http://allseeing-i.com/ASIHTTPRequest/), a formerly popular networking library that is no longer being actively maintained.
- [FlurryAnalytics](http://www.flurry.com/flurry-analytics.html), a mobile analytics package.
- [MBProcessHUD](https://github.com/jdg/MBProgressHUD), an animated spinner.
- [RaptureXML](https://github.com/ZaBlanc/RaptureXML), a simplt to use, DOM-based XML parser.
- [SBJSON](http://stig.github.com/json-framework/), an Objective-C JSON parser.  iOS 5 now offers NSJSONSerialization, so the app could be rewritten without using this library.


Thoughts/Questions/Improvements?
-------------
Send them to jonkroll@gmail.com
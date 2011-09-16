Meemi for iOS
=============

Meemi for iOS is an application to access the Meemi social network with iPhone/iPad.

***
[Meemi](http://meemi.com/) in itself is an Italian site that combines the social networking and microblogging in a single instrument, generating a constant stream of information, called lifestream, collecting and sharing micro contents quickly and easily with friends, the memes.

***
The compiled application can be downloaded for free on the [App Store](itms://itunes.apple.com/us/app/meemi/id379646447?mt=8). Instruction for using it are available on the [main site](http://www.iltofa.com/Meemi/)
*The source code is released here under the [MIT license](http://www.opensource.org/licenses/mit-license.php)* (a very liberal software license). You have to maintain my copyright notice but otherwise you can do (almost) what you want with the code.
Legalese apart, I'm available to help you both in understanding the code and in being open to re-submit to the App Store with any modification the community thinks will be OK for the application.

***
The application is my first try at CoreData and has been refactored many time for this reason. :) Some remains of the refactoring are present in the model classes which refactoring is not complete (it's somewhat in the middle, it worked so it was good enough to ship).

The application design has been heavily influenced by the requisite (a personal one) that the application should work seamlessly in low bandwidth situation. Therefore caching is aggressively applied in many part of the application.

This application do not use html, nor styled text in his table cells, this because many of the app *"customers"* were having iPhone 3G (or the "original" ones) and the scrolling speed was a critical consideration (I'm very fond of the reached speed in scrolling).

***
Meemi makes use of some OSS libraries and frameworks:
* [appirater](https://github.com/arashpayan/appirater) to send customer to appstore for evaluation.
* [SFHFKeychainUtils](http://github.com/ldandersen/scifihifi-iphone/tree/master/security/) for I/O on keychain.
* [ASIHTTPRequest](http://allseeing-i.com/ASIHTTPRequest/) (for network I/O)
* [RegexKitLite](http://regexkit.sourceforge.net/) by John Engelhart for regex.
* Some category on UIImage, initially by Trevor Harmon and heavily modified.
* the icons derive from the free kit of [Joseph Wain](http://glyphish.com/)

***
**Things to do**

While the application in itself is reliably working, I resolved to release it to the public because there are many things that could (and should) be improved in it and I have not enough time to work on it anymore.

Icons and, more in general, the aspect of the application can be easily improved.

There are some subtle bug in reading the discussions created by some server side modifications that could be fixed.

An iPad UI can be added.

The application should run under iOS 3.x but it don't... I really don't know why because I don't have anymore any iOS3 device so I cannot check it.

Have fun!

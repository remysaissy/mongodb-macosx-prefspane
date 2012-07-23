mongodb-macosx-prefspane
========================

This Preferences pane for MongoDB.

![Screenshot](https://github.com/remysaissy/mongodb-macosx-prefspane/raw/master/doc/screenshot%20started.png)

Prerequisite
-------

Install MongoDB using homebrew (http://mxcl.github.com/homebrew/).

    brew install mongodb


Functionalities
-------

The following functionalities are supported:

* Indicates if the server is running.
* Start / Stop the MongoDB Server
* Install / Uninstall MongoDB Server for startup at login time (LaunchAgent)
* Seamlessly migrate your homebrew launchd plist file so you won't loose your modifications when you check automatic startup
* Disabling automatic startup won't loose your plist, it will be moved as a .disabled file and restored if needed

Downloading
-------

The latest version is in the download directory of the source tree.
(https://github.com/remysaissy/mongodb-macosx-prefspane/raw/master/download/MongoDB.prefPane.zip)


Installing
-------

* Download the latest version
* Unzip the archive
* Execute MongoDB.prefPane. This will install it in your preferences panel

Note: To Mountain Lion users. This application is presently not on the app store and therefore it is not signed. You can still install it but don't be surprised to have an alert about it.

Contributing
------------

Want to contribute? Great!

1. Fork it.
2. Create a branch (`git checkout -b my_mongodb_prefspane`)
3. Commit your changes (`git commit -am "Added Installer"`)
4. Push to the branch (`git push origin my_mongodb_prefspane`)
5. Create an [Issue][1] with a link to your branch
6. Enjoy a refreshing Diet Coke and wait

[1]: https://github.com/remysaissy/mongodb-macosx-prefspane/issues

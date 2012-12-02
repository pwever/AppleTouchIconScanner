Apple Touch Icon Scanner
========================

Description
-----------

A ruby script that parses a text file and crawls all links in order to build statistics about the usage of apple-touch-icon usage.

Usage
-----

    ruby AppleTouchIconScanner.rb source-file.html

Sample Output
-------------

    # Scan started.
    # Scanning link 1 of 103: "http://www.yahoo.com"
    # ....
    # Scanning link 103 of 103: "http://news.bbc.co.uk"
    # ================================================
    # 78, or 76% of sites provided a "apple-touch-icon" link.

Dependencies
------------

* yaml
* hpricot
* The output uses the [progressbar gem](http://gemcutter.org/gems/progressbar).



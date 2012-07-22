#!/bin/sh

ibtool --generate-strings-file src/main/resources/en.lproj/InfoPlist.strings src/main/resources/en.lproj/MongoDBPrefsPane.xib
genstrings -genstrings -o src/main/resources/en.lproj $(find src/main/objc -type f -name '*.m' -print | tr '\n' ' ')


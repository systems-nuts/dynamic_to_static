#!/bin/bash

# just remove all files but not sources

cd tests
rm -f `ls | grep -v "\.[ch]$"`
cd -


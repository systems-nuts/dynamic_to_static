#!/usr/bin/python

# Script to get rid of got_plt symbols and declare them external
# currently supports clang and musl-gcc
#
# Antonio Barbalace, Stevens 2019

import re
import sys
import os

# check command line arguments, need the file to open as first argument
if (len(sys.argv)<3):
 print "Usage: " + sys.argv[0] + " compiler file.ll"
 sys.exit(1)
# check if first file exists
file_exist = os.path.isfile(sys.argv[2])
if (file_exist):
 file_name = sys.argv[2]
else:
 print "Error: file1 " + sys.argv[2] + " doesn't exist"
 sys.exit(1)
# no need to check the compiler
compiler=sys.argv[1]

#file.close()
file_desc = open(file_name,"r")

# use patterns based on the compiler, we support clang, musl-gcc
if (compiler=="clang"):
 got_plt_pattern = re.compile("got_plt[ \t]+=[ \t]+")
 got_plt_member = re.compile("@([a-zA-Z0-9_]+)")
elif (compiler=="musl-gcc"):
 got_plt_pattern = re.compile("_got[ \t]+=[ \t]+")
 got_plt_member = re.compile("@([a-zA-Z0-9_]+)[ \t]+to[ \t]+")
else:
 print "Error: compiler "+compiler+" not supported"
 sys.exit(1)

got_plt_open = re.compile("<{")
#got_plt_close = re.compile("}>")

XXXpattern="SSSSS"
members =[]

sysvcc_signature = "x86_64_sysvcc"
sysvcc_pattern = re.compile("declare extern_weak "+sysvcc_signature+" [a-z0-9]+ @")
sysvcc_funcName = re.compile("@([a-zA-Z0-9_]+)\(")

for line in file_desc: 
 # search for got_plt line(s) and substitute   
 got_plt_match = got_plt_pattern.search(line)
 if got_plt_match:
  # find the symbols first
  open_match = got_plt_open.search(line, got_plt_match.end())
  if open_match:
   end_index = open_match.end()   
   while True:
    member_match = got_plt_member.search(line, end_index)
    if member_match:
     #print member_match.group(1) + " at " + str(member_match.start())
     members.append(member_match.group(1))
     end_index = member_match.end()
    else:
     break
  # then do substitute the text with the new text 
  for member in members:
   line = re.sub(r" @"+member+" ", r" @"+XXXpattern+member+" ",line.rstrip())
  print line
  continue
 # search for weak external symbols and add external symbols    
 sysvcc_match = sysvcc_pattern.search(line)
 if sysvcc_match:
  # check if the symbol is to be substituted or not
  funcName_match = sysvcc_funcName.search(line, sysvcc_match.end() -1)
  if funcName_match:
   #print "found: "+funcName_match.group(1)
   if (funcName_match.group(1) in members):
    # substitute previous line
    lineSub = re.sub(r" @"+funcName_match.group(1)+"\(", " @"+XXXpattern+funcName_match.group(1)+"(",line.rstrip())
    print lineSub
    # create a new line
    lineSubNew = re.sub(r" extern_weak "+sysvcc_signature+" "," ",line.rstrip())
    print lineSubNew
    continue
 # if this is just a normal line, just print it
 print line
 
sys.exit(0)


#!/usr/bin/env perl
use strict;
use warnings;
while (<>) {   # Read input from command-line into default variable $_
    if ($_ =~ /\/\/\|(.*)$/){
	print $1;
	print "\n";
    }
#print $_;
#print "xxx";
}

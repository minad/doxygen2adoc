#!/usr/bin/perl -w
use strict;
use File::Slurper qw(read_text write_text);
use utf8;
use open ':std', ':encoding(UTF-8)';

my $code = read_text $ARGV[0];
my @lines = split /\n/, $code;

my $STATE_INIT = 0;
my $STATE_COMMENT = 1;
my $STATE_FN = 2;

my $state = $STATE_INIT;
my $indent = '';
foreach my $line (@lines) {
    if ($state == $STATE_INIT) {
        if ($line =~ /^\/\*\*/) {
            print "$line\n";
            $state = $STATE_COMMENT;
        } elsif ($line =~ qr(^///)) {
            print "$line\n";
        } elsif ($line =~ /^\s*(function\s+\w+)\((.*?)\)\s*\s*{.*?}$/) {
            my $name = $1;
            my $args = join ', ', map { "jsvalue $_" } split(/\s*,\s*/, $2);
            print "$name($args) {}\n";
        } elsif ($line =~ /^(\s*)(function\s+\w+)\((.*?)\)\s*\s*{/) {
            $indent = $1;
            my $name = $2;
            my $args = join ', ', map { "jsvalue $_" } split(/\s*,\s*/, $3);
            print "$name($args) {\n";
            $state = $STATE_FN;
        } else {
            print "\n";
        }
    } elsif ($state == $STATE_COMMENT) {
        print "$line\n";
        $state = $STATE_INIT if ($line =~ /^\s*\*\/\s*$/);
    } elsif ($state == $STATE_FN) {
        if ($line =~ /^$indent\}\s*$/) {
            print "}\n";
            $state = $STATE_INIT;
        } else {
            print "\n";
        }
    }
}

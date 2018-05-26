#!/usr/bin/perl -w
use strict;
use File::Slurper qw(read_text write_text);
use utf8;
use open ':std', ':encoding(UTF-8)';

# Until asciidoctor gets inline syntax highlighting we do it here
# The highlighter understands a tiny bit of C and Java.
sub inline_highlight {
    my ($s) = @_;

    # Remove more jsvalues
    $s =~ s/\bjsvalue\s+//g;

    # Fix pointers with spaces around
    $s =~ s/\s+(\*+)\s+/$1 /g;
    $s =~ s/\s+(\*+)$/$1/g;

    # Fix pointers followed by variable name, comma or closing parenthesis
    $s =~ s/\s+(\*+)(\w)/$1 $2/g;
    $s =~ s/\s+(\*+)([,\)])/$1$2/g;

    # Replace pointer with entity to avoid asciidoc interpretation
    $s =~ s/\*/{empty}pass:[*]/g;

    # Remove space before java array types
    $s =~ s/(\w+)\s+\[\]/$1\[\]/g;

    # Remove space before java generic types
    $s =~ s/<\s+/</g;
    $s =~ s/\s+>/>/g;
    $s =~ s/</{empty}pass:[&lt;]/g;
    $s =~ s/>/{empty}pass:[&gt;]/g;

    # Remove multiple spaces
    $s =~ s/\s+/ /g;

    # Highlight keywords
    $s =~ s/\b(function|continuation|u?int\d+_t|size_t|double|float|short|int|unsigned|long|void|const|char|final|struct|bool|union|typedef|#define|boolean)\b/*$1*/g;

    return $s;
}

sub verbatim {
    my ($s) = @_;
    $s =~ s/^\n*|\n*$//g;
    if ($s =~ /\+--|─/) {
        # ditaa doesn't understand box drawing characters
        $s =~ s/─/-/g;
        $s =~ s/[┌┬┐├┤└┴┘┼]/+/g;
        $s =~ s/│/|/g;
        $s =~ s/▶/>/g;
        return "[ditaa,format=svg,shadows=false,separation=false,transparent=true]\n....\n$s\n....";
    } else {
        return "....\n$s\n....";
    }
}

my $s = read_text $ARGV[0];

# Remove jsvalue types from javascript doxygen
$s =~ s/<inline-highlight>\s*jsvalue\s*<\/inline-highlight>\s*//g;

# Highlight inline
$s =~ s/<inline-highlight>(.*?)<\/inline-highlight>/inline_highlight($1)/eg;

# Fix verbatim blocks
$s =~ s/\.\.\.\.(.*?)\.\.\.\./verbatim($1)/egs;

write_text $ARGV[0], $s;

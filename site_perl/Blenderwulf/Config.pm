package Blenderwulf::Config;

use strict;
use warnings;

BEGIN {
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(conf_value);
}

use Exporter;

my %conf;

sub import {    
    while(<DATA>) {
        chomp;
        my ($k, $v) = split /\s*=\s*/;
        next unless $k;
        $conf{$k} = $v;
    }
    Blenderwulf::Config->export_to_level(1, @_);
}

sub conf_value {
    my $key = shift;
    return $conf{$key};
}

1;

__DATA__
blender_command=~/Downloads/blender-2.80-aa003c73245f-linux-glibc224-x86_64/blender

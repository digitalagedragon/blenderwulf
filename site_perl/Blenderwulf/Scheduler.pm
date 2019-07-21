package Blenderwulf::Scheduler;

use strict;
use warnings;

sub new {
    my $that = shift;
    my $class = ref($that) || $that;

    return bless {
    }, $class;
}

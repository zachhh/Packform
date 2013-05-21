#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'Packform' ) || print "Bail out!\n";
    use_ok( 'Packform::Input' ) || print "Bail out!\n";
    use_ok( 'Packform::Input::Simple' ) || print "Bail out!\n";
    use_ok( 'Packform::Input::Option' ) || print "Bail out!\n";
    use_ok( 'Packform::Input::Plugin' ) || print "Bail out!\n";
}

#diag( "Testing Packform $Packform::VERSION, Perl $], $^X" );

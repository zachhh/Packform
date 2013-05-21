#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN { use_ok('Packform'); }

use Packform;

# Create a global Packform object
my $ui = Packform->new();




# Let Test::More know that the tests are complete
done_testing();


#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN { use_ok('Packform'); }

use Packform;




# SETTERS / GETTERS FOR THE CORE RESPONSE
# These are tested here
#	set_target set_title set_heading set_url set_frontend set_context 
#	set_err add_info set_persistent_bottom set_persisten_top set_default_suffix
#	get_target get_title get_heading get_url get_frontend get_err 
#	get_persistent_bottom get_persistent_top get_default_suffix 

my %strings = ();

# Create a global Packform object
my $ui = Packform->new();

# Load up the tests
add_string('Target');
add_string('Title');
add_string('Heading');
add_string('Url');
add_string('Frontend',1.0);
add_string('Context');
add_string('Error',undef,'err');
add_string('Persistent Bottom',undef,'sticky_bottom','persistent_bottom');
add_string('Persistent Top',undef,'sticky_top','persistent_top');

# Do the tests
while (my ($l,$hash) = each %strings) { do_test($l,$hash); }

# Let Test::More know that the tests are complete
done_testing();

# Do the test
sub do_test {
	# Grab the information
	my ($label, $attrs) = @_;
	my $suff = $attrs->{suffix};
	my $val = $attrs->{val};
	my $key = $attrs->{key};
	my $set = "set_$suff";
	my $get = "get_$suff";
	
	# Check the creation of the object
	ok($ui->$set($val), "Set $label with $set($val)");
	# Check the existance of the internal hash key
	#ok(exists $ui->{$key}, "Key for $label");
	# Check the value of the internal hash key
	#is($ui->{$key}, $val, "Internal value for $label");
	# Check the getter
	if ($ui->can($get)) {
		is($ui->$get(), $val, "Get $label with $get");
	}
}

sub add_string {
	my ($label,$value,$key,$suffix) = @_;
	$value //= $label;
	$key //= lc $label;
	$suffix //= $key;
	$strings{$label} = { 'val' => $value, 'key' => $key, 'suffix' => $suffix };
}


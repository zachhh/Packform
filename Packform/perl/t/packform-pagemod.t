#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN { use_ok('Packform'); }

use Packform;

# These all manage the current page
#
#	remove_target_from_page leave_target_on_page
#	remove_all_targets_from_page leave_all_targets_on_page
#	remove_all_inputs_from_page leave_all_inputs_on_page
#	remove_all_buttons_from_page leave_all_buttons_on_page
#	remove_all_pars_from_page leave_all_pars_on_page
#	remove_dups_from_page leave_dups_on_page
#	remove_input_from_target leave_input_on_target
#	remove_all_inputs_from_target leave_all_inputs_on_target
#	remove_all_buttons_from_target leave_all_buttons_on_target
#	remove_all_pars_from_target leave_all_pars_on_target
#	remove_dups_from_target leave_dups_on_target


my $ui = Packform->new();

my @config = ();

add_config('target','page','xtargets',1);
add_config('input','page','xinputs',1);
add_config('all_targets','page','xalltargets');
add_config('all_inputs','page','xallinputs');
add_config('all_buttons','page','xallbuttons');
add_config('all_pars','page','xallpars');
add_config('dups','page','xdups');
add_config('input','target','xinptarget',1);
add_config('all_inputs','target','xallinputstarget');
add_config('all_buttons','target','xallbuttonstarget');
add_config('all_pars','target','xallparstarget');
add_config('dups','target','xdupstarget');

foreach (@config) { do_test($_); }

done_testing();

sub do_test {
	my $data = shift;
	my ($what,$where,$key,$val,$arr) = @$data;
	my $add = 'remove_' . $what . '_from_' . $where;
	my $cancel = 'leave_' . $what . '_on_' . $where;
	$ui->$add($val);
	ok( exists $ui->{$key}, "Key $key exists");
	if ($arr) { ok ( scalar grep { /$val/ } @{$ui->{$key}}, "Appended $val to $key array" ); }
	else { ok ( $ui->{$key}, "Key $key is true"); }
	if ($arr) {
		$ui->$cancel($val);
		is( scalar(grep { /$val/ } @{$ui->{$key}}), 0, "Remove $val from $key on cancel" ); 
	}
	else {
		$ui->$cancel();
		ok( ! exists $ui->{$key}, "Key $key removed upon cancel");
	}
}


sub add_config {
	my ($what,$where,$key,$arr,$val) = @_;
	$val //= $key;
	$arr //= 0;
	push @config, [$what,$where,$key,$val,$arr];
}



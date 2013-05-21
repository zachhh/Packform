#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN { use_ok('Packform'); }

use Packform;

# All inputs should be able to do these things
my @methods = qw(
	set_value get_value set_name get_name set_prompt get_prompt
	set_suffix get_suffix set_attrs get_attr get_attrs set_global set_noglobal 
	_carp_required_attributes _html_prefix _html_attrs _html_suffix
	_set_attr _is_plugin _is_option _has_name_not_value _get_args
);

my @shared = qw( as_html _bootstrap _init_defaults );

# specific to the plugin type
my @plugin = qw( set_plugin_attrs get_plugin_attrs );
# specific to option inputs
# Although the label-related methods only apply to radios, the method should
# be available to any Packform::Input::Option
my @option = qw( 
	add_options add_option append_option append_options
	prepend_option prepend_options get_options
	label_before label_after get_label_location
	_radio_html _select_html _sorted_opts
);


my $ui = Packform->new();
my $simp = $ui->new_text('test');
my $opt = $ui->new_select('test');
my $plug = $ui->new_date('test');

# Check that everything inherits from Packform::Input properly
foreach my $method (@methods) {
	can_ok($simp, $method);
	can_ok($opt,  $method);
	can_ok($plug, $method);
	can_ok('Packform::Input', $method);
	can_ok('Packform::Input::Simple', $method);
	can_ok('Packform::Input::Option', $method);
	can_ok('Packform::Input::Plugin', $method);
}

# Common to all types, but not part of Packform::Input
foreach my $method (@shared) {
	can_ok($simp, $method);
	can_ok($opt,  $method);
	can_ok($plug, $method);
	can_ok('Packform::Input::Simple', $method);
	can_ok('Packform::Input::Option', $method);
	can_ok('Packform::Input::Plugin', $method);
}

foreach my $method (@plugin) {
	ok( ! $opt->can($method), "Options should not be able to $method");
	ok( ! $simp->can($method), "Simple inputs should not be able to $method");
	ok( $plug->can($method), "Plugins should be able to $method");
}

foreach my $method (@option) {
	ok( $opt->can($method), "Options should be able to $method");
	ok( ! $simp->can($method), "Simple inputs should not be able to $method");
	ok( ! $plug->can($method), "Plugins should not be able to $method");
}


done_testing();



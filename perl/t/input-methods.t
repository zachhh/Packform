#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN { use_ok('Packform'); }

use Packform;

# Create a global Packform object
my $ui = Packform->new();

my $name = 'name';
my $value = 'value';
my $prompt = 'prompt';
my $suffix = 'suffix';

# Different option styles for testing sorts
# suitable for testing alphabetically and numerically
my $opt1 = [ '10', '7', '30' ];
my $opt2 = [ ['1','10'], ['9','4'], ['100','7'], ['45','1'] ];
my $opt3 = { 1 => '10', 9 => '4', 100 => '7', 45 => '1' };

# attributes to assign to see if they make it
my $attrs = { 'a' => 'a value', 'b' => 'b value', 'c' => 'c value' };

# Test full calling styles

my $type;

my $obj;
my @standard = qw(text button password textarea checkbox);

###############
# Test for complete definition at construction time.
###############

# Test standard name, value, prompt, suffix for the standard inputs.
foreach $type (@standard) {
    # Define the method to construct the object
    my $meth = "new_$type";
    # Create the object
    $obj = $ui->$meth($name, value => $value, prompt => $prompt, suffix => $suffix, attrs => $attrs);
    check_standard($obj,$type,$name,$value,$prompt,$suffix,$attrs);
}

# Test select boxes
$type = 'select';
$obj = $ui->new_select(
        $name,
        value => $value,
        prompt => $prompt,
        suffix => $suffix,
        attrs => $attrs,
        opts => $opt1,
        sort => 'numeric');

# Test the standard attributes
check_standard($obj,$type,$name,$value,$prompt,$suffix,$attrs);

# check that the options are sorted correctly
ok($obj->{opts}, "$type opts set");
# NOTE: We only have to test that the sort is being called.
# This uses the same internals as adding options.
# It is also the same for radios, so we don't have to test twice.

# Build what we expect to have
my @expected = map { { val => $_, txt => $_ } } sort { $a <=> $b } @$opt1;
is_deeply($obj->{opts}, \@expected, "$type simple numeric sort");


# Test radio groups
$type = 'radio';
$obj = $ui->new_radio(
        $name,
        value => $value,
        prompt => $prompt,
        suffix => $suffix,
        attrs => $attrs,
        opts => $opt1,
        sort => 'numeric',
        labelloc => 'after',
        itemsuffix => 'thesuff');

# Test the standard attributes
check_standard($obj,$type,$name,$value,$prompt,$suffix,$attrs);
is($obj->{labelloc},'after',"$type label location internal");
is($obj->get_label_location,'after',"$type label location");
is($obj->{itemsuffix},'thesuff',"$type item suffix internal");
is($obj->get_item_suffix,'thesuff',"$type item suffix");

# check that the options are there
ok($obj->{opts}, "$type opts set");

# Test date
$type = 'date';
$obj = $ui->new_date(
        $name,
        value => $value,
        prompt => $prompt,
        suffix => $suffix,
        attrs => $attrs,
        pluginattrs => $attrs);

check_standard($obj,$type,$name,$value,$prompt,$suffix,$attrs);
check_pluginattrs($obj,$attrs);

# Test modal
$type = 'modal';
$obj = $ui->new_modal(
        $name,
        value => $value,
        prompt => $prompt,
        suffix => $suffix,
        attrs => $attrs,
        pluginattrs => $attrs);
# Modals lose their name as it becomes the title....
check_standard($obj,$type,$name,$value,$prompt,$suffix,$attrs);
check_pluginattrs($obj,$attrs);

# Test wysiwyg
$type = 'wysiwyg';
$obj = $ui->new_wysiwyg(
        $name,
        value => $value,
        prompt => $prompt,
        suffix => $suffix,
        attrs => $attrs,
        pluginattrs => $attrs);
check_standard($obj,$type,$name,$value,$prompt,$suffix,$attrs);
check_pluginattrs($obj,$attrs);

# Test hidden inputs
$obj = $ui->new_hidden($name, value => $value, global => 1);
is($obj->{name}, $name, "hidden name internal");
is($obj->{value},$value, "hidden value internal");
ok($obj->{global}, "hidden global internal");
is($obj->get_name,$name,"hidden name");
is($obj->get_value,$value,"hidden value");



###############
# Test for minimal definition and methods to set properties
###############

# Test standard inputs
foreach $type (@standard) {
    # Define the method to construct the object
    my $meth = "new_$type";
    # Create the object
    $obj = $ui->$meth($name);
    if ($type eq 'button') { $obj->set_name($name); }
    $obj->set_value($value);
    $obj->set_prompt($prompt);
    $obj->set_suffix($suffix);
    $obj->set_attrs(%$attrs);
    check_standard($obj,$type,$name,$value,$prompt,$suffix,$attrs);
}


# Test select boxes
$obj = $ui->new_select($name);
$obj->set_value($value);
$obj->set_prompt($prompt);
$obj->set_suffix($suffix);
$obj->set_attrs(%$attrs);
$obj->add_options($opt1);
# Test the standard attributes
check_standard($obj,$type,$name,$value,$prompt,$suffix,$attrs);
# check that the options are there
ok(scalar @{$obj->{opts}}, "$type opts set with array");

# Clear the options
$obj->clear_options;
is(scalar @{$obj->{opts}},0, "$type clear options");

# Take it through its paces with the various types of data and sorts
$obj->add_options($opt2);
ok(scalar @{$obj->{opts}}, "$type opts set with array of arrays");
$obj->clear_options;
$obj->add_options($opt3);
ok(scalar @{$obj->{opts}}, "$type opts set with hash");

# Use the array of arrays for the testing the sorts
$obj->clear_options();
$obj->add_options($opt2,'val_num');
@expected = map { { val => $_->[0], txt => $_->[1] } } sort { $a->[0] <=> $b->[0] } @$opt2;
is_deeply($obj->{opts},\@expected, "numeric sort by value");

$obj->clear_options();
$obj->add_options($opt2,'num');
@expected = map { { val => $_->[0], txt => $_->[1] } } sort { $a->[1] <=> $b->[1] } @$opt2;
is_deeply($obj->{opts},\@expected, "numeric sort by display text");

$obj->clear_options();
$obj->add_options($opt2,'val_num_desc');
@expected = map { { val => $_->[0], txt => $_->[1] } } sort { $b->[0] <=> $a->[0] } @$opt2;
is_deeply($obj->{opts},\@expected, "numeric sort by value descending");

$obj->clear_options();
$obj->add_options($opt2,'num_desc');
@expected = map { { val => $_->[0], txt => $_->[1] } } sort { $b->[1] <=> $a->[1] } @$opt2;
is_deeply($obj->{opts},\@expected, "numeric sort by display text descending");

$obj->clear_options();
$obj->add_options($opt2,'val');
@expected = map { { val => $_->[0], txt => $_->[1] } } sort { $a->[0] cmp $b->[0] } @$opt2;
is_deeply($obj->{opts},\@expected, "text sort by value");

$obj->clear_options();
$obj->add_options($opt2,'text');
@expected = map { { val => $_->[0], txt => $_->[1] } } sort { $a->[1] cmp $b->[1] } @$opt2;
is_deeply($obj->{opts},\@expected, "text sort by display text");

$obj->clear_options();
$obj->add_options($opt2,'val_desc');
@expected = map { { val => $_->[0], txt => $_->[1] } } sort { $b->[0] cmp $a->[0] } @$opt2;
is_deeply($obj->{opts},\@expected, "text sort by value descending");

$obj->clear_options();
$obj->add_options($opt2,'text_desc');
@expected = map { { val => $_->[0], txt => $_->[1] } } sort { $b->[1] cmp $a->[1] } @$opt2;
is_deeply($obj->{opts},\@expected, "text sort by display text descending");

# Test radio groups
$type = 'radio';
$obj = $ui->new_radio($name);
$obj->set_value($value);
$obj->set_prompt($prompt);
$obj->set_suffix($suffix);
$obj->set_attrs(%$attrs);
$obj->add_options($opt1);
$obj->set_item_suffix('itemsuff');
$obj->label_after;
check_standard($obj,$type,$name,$value,$prompt,$suffix,$attrs);
ok(scalar @{$obj->{opts}}, "$type opts set with array");
is($obj->get_item_suffix,'itemsuff',"$type item suffix");
is($obj->get_label_location,'after',"$type label location");


# Test date
$type = 'date';
$obj = $ui->new_date($name);
$obj->set_value($value);
$obj->set_prompt($prompt);
$obj->set_suffix($suffix);
$obj->set_attrs(%$attrs);
$obj->set_plugin_attrs(%$attrs);
check_standard($obj,$type,$name,$value,$prompt,$suffix,$attrs);
check_pluginattrs($obj,$attrs);

# Test wysiwyg
$type = 'wysiwyg';
$obj = $ui->new_wysiwyg($name);
$obj->set_value($value);
$obj->set_prompt($prompt);
$obj->set_suffix($suffix);
$obj->set_attrs(%$attrs);
$obj->set_plugin_attrs(%$attrs);
check_standard($obj,$type,$name,$value,$prompt,$suffix,$attrs);
check_pluginattrs($obj,$attrs);

# Test modal
$type = 'modal';
$obj = $ui->new_modal($name);
$obj->set_value($value);
$obj->set_prompt($prompt);
$obj->set_suffix($suffix);
$obj->set_attrs(%$attrs);
$obj->set_plugin_attrs(%$attrs);
check_standard($obj,$type,$name,$value,$prompt,$suffix,$attrs);
check_pluginattrs($obj,$attrs);

# Hidden inputs require a name and a value at construction time.
$type = 'hidden';
$obj = $ui->new_hidden($name, value => $value);
$obj->set_value('different');
is($obj->get_value, 'different', 'Change hidden input value');

###############
# Test alternate construction types
###############

# Test button
ok($obj = $ui->new_button(), 'empty button construction');
$obj = $ui->new_button($name,$value);
is($obj->get_value,$value,"two-parameter button construction");
$obj = $ui->new_button($value);
is($obj->get_value,$value,"one-parameter button construction");

# Test paragraph
$obj = $ui->new_paragraph($name,$value);
is($obj->get_value,$value,"two-parameter button construction");
$obj = $ui->new_paragraph($value);
is($obj->get_value,$value,"one-parameter button construction");

# Test modal
$obj = $ui->new_modal($name,$value);
is($obj->get_value,$value,"two-parameter modal construction");
$obj = $ui->new_modal($value);
is($obj->get_value,$value,"one-parameter modal construction");

# Test hidden inputs
$obj = $ui->new_hidden($name,$value);
is($obj->get_value,$value,"two-parameter hidden input construction");

# Let Test::More know that the tests are complete
done_testing();

sub check_standard {
    my ($obj,$type,$name,$value,$prompt,$suffix,$attrs) = @_;
    # Check that we get back what we put in
    
    if ($type eq 'modal') {
        is($obj->{pluginattrs}->{title}, $name, "modal name to title");
    }
    else {
        is($obj->{name}, $name, "$type name internal");
        is($obj->get_name, $name, "$type name");
    }
    is($obj->{value}, $value, "$type value internal");
    is($obj->get_value, $value, "$type value");
    is($obj->{prompt}, $prompt, "$type prompt internal");
    is($obj->get_prompt, $prompt, "$type prompt");
    is($obj->{suffix}, $suffix, "$type suffix internal");
    is($obj->get_suffix, $suffix, "$type suffix");
    ok($obj->{attrs}, "$type attrs set internally");
    unless (exists $obj->{attrs}) { return; }
    while (my ($k,$v) = each %{$obj->{attrs}}) {
        ok( exists $attrs->{$k}, "$type superfluous attributes");
        is( $v, $attrs->{$k}, "$type attributes");
    }
    while (my ($k,$v) = each %$attrs) {
        is( $obj->get_attr($k), $v, "$type attributes accessed individually");
    }
}

sub check_pluginattrs {
    my ($obj,$atts) = @_;
    my %plug = $obj->get_plugin_attrs;
    while (my ($k,$v) = each %$atts) {
        ok(exists $plug{$k}, "$obj->{type} plugin attributes exist");
        ok(((exists $plug{$k}) and ($plug{$k} eq $v)), "$obj->{type} plugin attributes set");
    }
}


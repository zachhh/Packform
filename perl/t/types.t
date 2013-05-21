#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Packform;

plan tests => 27;

my $simple = 'Packform::Input::Simple';
my $plugin = 'Packform::Input::Plugin';
my $option = 'Packform::Input::Option';
my $obj;

my $ui = Packform->new();
isa_ok($ui,'Packform');

# Test object type with new_*

$obj = $ui->new_button();
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->new_submit();
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->new_text('test');
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->new_textarea('test');
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->new_checkbox('test');
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->new_password('test');
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->new_paragraph('test');
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->new_hidden('test', value => 'test');
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->new_radio('test');
isa_ok($obj,$option);
undef $obj;

$obj = $ui->new_select('test');
isa_ok($obj,$option);
undef $obj;

$obj = $ui->new_date('test');
isa_ok($obj,$plugin);
undef $obj;

$obj = $ui->new_modal('test');
isa_ok($obj,$plugin);
undef $obj;

$obj = $ui->new_wysiwyg('test');
isa_ok($obj,$plugin);
undef $obj;

# Test object type with add_*
$obj = $ui->add_button();
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->add_submit();
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->add_text('test');
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->add_textarea('test');
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->add_checkbox('test');
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->add_password('test');
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->add_paragraph('test');
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->add_hidden('test', value => 'test');
isa_ok($obj,$simple);
undef $obj;

$obj = $ui->add_radio('test');
isa_ok($obj,$option);
undef $obj;

$obj = $ui->add_select('test');
isa_ok($obj,$option);
undef $obj;

$obj = $ui->add_date('test');
isa_ok($obj,$plugin);
undef $obj;

$obj = $ui->add_modal('test');
isa_ok($obj,$plugin);
undef $obj;

$obj = $ui->add_wysiwyg('test');
isa_ok($obj,$plugin);
undef $obj;



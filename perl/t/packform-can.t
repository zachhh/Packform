#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN { use_ok('Packform'); }

my @methods = qw(
	set_target set_title set_heading set_url set_frontend set_context 
	set_err add_info set_persistent_bottom set_persistent_top set_default_suffix
	get_target get_title get_heading get_url get_frontend get_err 
	get_persistent_bottom get_persistent_top get_default_suffix 
	add_input add_button new_button add_submit new_submit add_text new_text
	add_textarea new_textarea add_radio new_radio add_select new_select
	add_checkbox new_checkbox add_paragraph new_paragraph add_hidden new_hidden
	add_hidden_hash add_date new_date add_modal new_modal add_wysiwyg new_wysiwyg
	get_input_by_name input_exists get_all_names get_all_inputs clear_inputs
	remove_input remove_buttons remove_target_from_page leave_target_on_page
	remove_all_targets_from_page leave_all_targets_on_page
	remove_all_inputs_from_page leave_all_inputs_on_page
	remove_all_buttons_from_page leave_all_buttons_on_page
	remove_all_pars_from_page leave_all_pars_on_page
	remove_dups_from_page leave_dups_on_page
	remove_input_from_target leave_input_on_target
	remove_all_inputs_from_target leave_all_inputs_on_target
	remove_all_buttons_from_target leave_all_buttons_on_target
	remove_all_pars_from_target leave_all_pars_on_target
	remove_dups_from_target leave_dups_on_target
	input_err html_output json_output 
	set_jquery_version set_jqueryui_version set_jqueryui_theme
	set_tinymce_file set_js_path set_css_path set_page_title set_meta_data
	set_doctype add_stylesheets add_stylesheet splice_header splice_html
	html_full get_jquery_tags get_jq_js get_jqui_js get_jqui_css get_tinymce_tags
	get_frontend_tags get_pf_js get_pf_css get_stylesheet_tags html_header
	_set_attr _set_param _delete_param _set_config _add_input _new_input);

my $ui = Packform->new();

foreach my $method (@methods) {
	can_ok($ui, $method);
	can_ok('Packform', $method);
}

done_testing();


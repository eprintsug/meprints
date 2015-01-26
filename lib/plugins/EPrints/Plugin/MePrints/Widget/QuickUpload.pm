package EPrints::Plugin::MePrints::Widget::QuickUpload;

use EPrints::Plugin::MePrints::Widget;
@ISA = ( 'EPrints::Plugin::MePrints::Widget' );

use strict;

sub new
{

	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );
	
	$self->{name} = "EPrints Profile System: Quick Upload";
	$self->{visible} = "all";
	$self->{advertise} = 1;

	if( defined $self->{session} && defined $self->{session}->current_user )
	{
		unless( $self->{session}->current_user->has_role( 'deposit' ) )
		{
			$self->{enable} = 0;
		}
	}

	return $self;

}

sub render_content
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $user = $self->{user};
	my $id = "QuickUpload";

	my $frag = $session->make_doc_fragment;

	my $form = $session->render_form( "POST", $session->get_repository->get_conf( "rel_path" )."/cgi/users/home");

	my $hidden_field = $session->make_element("input", "name"=>"screen", "id"=>"screen", "value"=>"User::Homepage", "type"=>"hidden");
	$form->appendChild( $hidden_field );

	$hidden_field = $session->make_element("input", "name"=>"widget", "id"=>"widget", "value"=>"MePrints::Widget::QuickUpload", "type"=>"hidden");
	$form->appendChild( $hidden_field );

	my $file_button = $session->make_element( "input",
		name => $id."_file",
		id => "filename",
		type => "file",
	);
	$form->appendChild( $file_button );

	$form->appendChild( $session->render_action_buttons(
		_class => "ep_form_button_bar",
		quickupload => $self->phrase( "add_file" ) ));

	$frag->appendChild( $form );

	return $frag;

}

sub allow_quickupload 
{
	my ( $self ) = @_;
	return 1; 
}

sub action_quickupload
{
	my ( $self ) = @_;
	my $session = $self->{session};

        my $eprint_ds = $session->get_repository->get_dataset( 'eprint' );
	my $eprint_data = {
				"eprint_status" => "inbox",
			 	"userid" => $session->current_user->get_id(),
	};
	my $eprint = $eprint_ds->create_object( $session, $eprint_data );
#	my $eprint = EPrints::DataObj::EPrint->create_from_data($session, $eprint_data, $eprint_ds); 

	unless( defined $eprint )
	{
		return;
	}

        my $doc_ds = $session->get_repository->get_dataset( 'document' );
	my $doc_data = { eprintid => $eprint->get_id };
        $doc_data->{format} = $session->get_repository->call( 'guess_doc_type',
                $session,
                $session->param( "QuickUpload"."_file" ) 
	);
        my $document = $doc_ds->create_object( $session, $doc_data );

        unless( defined $document )
        {
                return;
        }

        my $success = EPrints::Apache::AnApache::upload_doc_file(
                $session,
                $document,
                "QuickUpload"."_file" 
	);

        unless( $success )
        {
                $document->remove();
                return;
        }

	$self->{redirect} = $session->get_repository->get_conf( "rel_path" ).'/cgi/users/home?screen=EPrint::Edit&eprintid='.$eprint->get_id();

	return;
}


1;

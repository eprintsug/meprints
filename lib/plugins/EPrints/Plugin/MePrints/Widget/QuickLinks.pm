package EPrints::Plugin::MePrints::Widget::QuickLinks;

use EPrints::Plugin::MePrints::Widget;

@ISA = ( 'EPrints::Plugin::MePrints::Widget', 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;
	
	my $self = $class->SUPER::new(%params);

	$self->{name} = "EPrints Profile System: Quick Links Widget";
	$self->{visible} = "all";
	$self->{advertise} = 1;

	$self->{surround} = 'Simple';
	$self->{render_title} = 0;
	$self->{show_in_controls} = 0;
	
	return $self;	
}

sub render_content
{
        my( $self ) = @_;

        my $session = $self->{session};
        my $user = $self->{user};
	my $upload_picture_plugin = $session->plugin( "Screen::User::UploadPicture" );
	
	if( defined $upload_picture_plugin )
	{
		if( $session->current_user->get_id == $user->get_id )
		{
			$upload_picture_plugin->{hidden} = 1;
		}
		else
		{
			$upload_picture_plugin->{hidden} = 0;
		}
	}

        $self->{processor}->{user} = $user;
        $self->{processor}->{userid} = $user->get_id;

        my $frag = $session->make_doc_fragment;

        $frag->appendChild( $self->render_action_list_bar( "user_actions", ['userid'] ) );

        return $frag;
}


1;

package EPrints::Plugin::Screen::User::EditLink;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	if( defined $self->{session} && !$self->{session}->config( "meprints_enabled" ) )
	{
		return $self;
	}

	$self->{actions} = [qw/ redirect /];

	$self->{appears} = [
		{
			place => 'user_actions',
			action => 'redirect',
			position => 100,
		}
	];

	return $self;
}

sub properties_from
{
        my( $self ) = @_;

	$self->EPrints::Plugin::Screen::User::Homepage::properties_from;
}


sub can_be_viewed
{
	my( $self ) = @_;

	return 0 unless( defined $self->{session} && defined $self->{session}->current_user );

	my $user = EPrints::Plugin::MePrints::get_user( $self->{session} );
	return $self->{session}->current_user->allow( 'user/edit', $user );
}

sub allow_redirect
{
	my( $self ) = @_;

	return $self->can_be_viewed;
}

sub action_redirect
{
	my( $self ) = @_;

        my $session = $self->{session};

        my $url = URI->new( $session->config( 'userhome' )  );
        $url->query_form(
                screen => 'Workflow::Edit',
                dataset => 'user',
		dataobj => $self->{processor}->{user}->get_id 
                );

        $session->redirect( $url );
	$session->terminate;
	exit;
}	


1;



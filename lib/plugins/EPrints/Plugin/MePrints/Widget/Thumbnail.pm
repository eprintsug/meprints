package EPrints::Plugin::MePrints::Widget::Thumbnail;

use EPrints::Plugin::MePrints::Widget;

@ISA = ( 'EPrints::Plugin::MePrints::Widget' );

use strict;

sub new
{
	my( $class, %params ) = @_;
	
	my $self = $class->SUPER::new( %params );
	
	if ( !$self->{session} )
	{
		$self->{session} = $self->{processor}->{session};
	}

	$self->{name} = "EPrints Profile System: User Image Widget";
	$self->{visible} = "all";
	$self->{advertise} = 1;

	$self->{render_title} = 0;
	$self->{show_in_controls} = 0;

	$self->{surround} = "Simple";

	return $self;
}

sub render_content
{
	my( $self ) = @_;

	# sf2 - thumbnail is done in the user citation 'profile.xml'
	# return $self->{session}->make_doc_fragment if( $self->{static} );

	return $self->{session}->make_element( "img", alt => "Profile Picture", src => $self->{user}->get_picture_url );
}

1;


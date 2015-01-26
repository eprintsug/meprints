package EPrints::Plugin::MePrints::Widget::Details;

use EPrints::Plugin::MePrints::Widget;
@ISA = ( 'EPrints::Plugin::MePrints::Widget' );

use strict;

sub new
{
	my( $class, %params ) = @_;
	
	my $self = $class->SUPER::new(%params);

	$self->{name} = "EPrints Profile System: User Details Widget";
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

	my $citation = $self->{static} ? 'profile' : 'details';

	return $self->{user}->render_citation( $citation );
}

1;

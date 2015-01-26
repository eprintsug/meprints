package EPrints::Plugin::Screen::Admin::RegenMePrints;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{actions} = [qw/ regen_meprints /]; 
		
	$self->{appears} = [
		{ 
			place => "admin_actions_system", 
			position => 1265, 
			action => "regen_meprints",
		},
	];

	return $self;
}

sub allow_regen_meprints
{
	my( $self ) = @_;

	return $self->allow( "config/regen_abstracts" );
}

sub action_regen_meprints
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $file = $session->get_repository->get_conf( "variables_path" )."/meprints.timestamp";
	unless( open( CHANGEDFILE, ">$file" ) )
	{
		$self->{processor}->add_message( "error",
			$self->html_phrase( "failed" ) );
		$self->{processor}->{screenid} = "Admin";
		return;
	}
	print CHANGEDFILE "This file last poked at: ".EPrints::Time::human_time()."\n";
	close CHANGEDFILE;

	$self->{processor}->add_message( "message",
		$self->html_phrase( "ok" ) );
	$self->{processor}->{screenid} = "Admin";
}	




1;

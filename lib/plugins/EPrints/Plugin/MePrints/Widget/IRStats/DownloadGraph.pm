package EPrints::Plugin::MePrints::Widget::IRStats::DownloadGraph;

use EPrints::Plugin::MePrints::Widget;
@ISA = ( 'EPrints::Plugin::MePrints::Widget' );

use strict;

sub new
{
	my( $class, %params ) = @_;
	
	my $self = $class->SUPER::new( %params );
	
	$self->{name} = "EPrints Profile System: IRStats";
	
	if ( !$self->{session} )
	{
		$self->{session} = $self->{processor}->{session};
	}

	$self->{visible} = "all";
	$self->{advertise} = 1;

	return $self;
}

sub render_content
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $user = $self->{user};

	my $frag = $session->make_doc_fragment;

	if ($session->get_repository->can_call('irstats_meprints_content'))
	{
		$frag->appendChild($session->get_repository->call('irstats_meprints_content', $session, $user));
	}
	else
	{
		$frag->appendChild( $session->make_text( 'Stats are not available on this system.' ) );
	}

	return $frag;

}

1;

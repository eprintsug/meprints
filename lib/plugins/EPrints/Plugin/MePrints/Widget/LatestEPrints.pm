package EPrints::Plugin::MePrints::Widget::LatestEPrints;

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

	$self->{name} = "EPrints Profile System: Published List Widget";
	$self->{visible} = "all";
	$self->{advertise} = 1;
	$self->{max_display} = 10;

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

	my $frag = $session->make_doc_fragment;

	my $items = $user->owned_eprints_list( dataset => $session->dataset( 'archive' ) );
	$items->reorder( 'datestamp' );

	if( $items->count )
	{
		my $itemlist = $session->make_element( "ol" );

		foreach my $eprint ( $items->get_records ( 0, $self->{max_display} ) )
		{
			my $li = $itemlist->appendChild( $session->make_element( 'li' ) );
			$li->appendChild( $eprint->render_citation_link() );
		}

		$frag->appendChild( $itemlist );
	}
	else
	{
		$frag->appendChild( $self->html_phrase( "noitems" ) );
	}

	return $frag;

}

1;

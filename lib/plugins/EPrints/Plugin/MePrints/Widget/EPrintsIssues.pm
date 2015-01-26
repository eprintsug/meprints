package EPrints::Plugin::MePrints::Widget::EPrintsIssues;

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

	$self->{name} = "EPrints Profile System: EPrint Issues Widget";
	$self->{visible} = "all";
	$self->{advertise} = 1;

	$self->{max_display} = 5;

	return $self;

}

sub render_content
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $user = $self->{user};

	my $frag = $session->make_doc_fragment;
	
	my $list = $user->owned_eprints_list( dataset => $session->dataset( 'archive' ) );
	$list->reorder( 'datestamp' );
	
	if( $list->count )
	{
		my @issueeprints = ();

		my @resultset = $list->get_records(0, $self->{max_display} );
	
		foreach my $eprint ( @resultset )
		{
			if ( $eprint->get_value( "item_issues_count" ) )
			{
				push( @issueeprints, $eprint );	
			}
		}
		
		if ( scalar @issueeprints )
		{
			$frag->appendChild( $self->html_phrase( "issuemessage" ) );
			
			my $issuelist = $session->make_element( "ul" );

			foreach my $eprint ( @issueeprints )
			{
				my $issueitem = $session->make_element( "li" );
				my $itemeditlink = $session->render_link( $session->get_repository->get_conf( "userhome" )."?screen=EPrint::View&eprintid=".$eprint->get_id );
				$itemeditlink->appendChild( $session->make_text( $eprint->get_value( "title" ) ) );
				$issueitem->appendChild( $itemeditlink );
			
				$issueitem->appendChild( $eprint->render_value( "item_issues" ) );

				$issuelist->appendChild( $issueitem );			
			}
		
			$frag->appendChild( $issuelist );
	
		}	
		else
		{
			$frag->appendChild( $self->html_phrase( "noissues" ) );
		}
	}
	else
	{
		$frag->appendChild( $self->html_phrase( "noitems" ) );
	}

	return $frag;
}

1;

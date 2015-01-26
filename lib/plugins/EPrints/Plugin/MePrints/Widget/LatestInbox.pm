package EPrints::Plugin::MePrints::Widget::LatestInbox;

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

	$self->{name} = "EPrints Profile System: Inbox Widget";
	$self->{visible} = "all";
	$self->{advertise} = 1;

	$self->{max_display} = 10;
	
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

	if ( $list->count )
	{
		$frag->appendChild( $self->html_phrase( "click_to_edit" ) );
		my $itemlist = $session->make_element( "ol" );
		my $edit_uri = $session->get_repository->get_conf( "rel_path" )."/cgi/users/home?screen=EPrint::Edit&eprintid=";
	
		foreach my $eprint ( $list->get_records ( 0, $self->{max_display} ) )
		{
			# make this an edit link
			my $edit_link = $session->render_link( "$edit_uri".$eprint->get_id );
			$edit_link->appendChild( $eprint->render_value( "title" ) );
			my $item = $session->make_element( "li" );
			$item->appendChild( $edit_link );
			$itemlist->appendChild( $item );
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

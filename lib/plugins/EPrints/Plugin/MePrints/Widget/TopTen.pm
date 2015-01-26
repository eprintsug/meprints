package EPrints::Plugin::MePrints::Widget::TopTen;

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

	$self->{name} = "EPrints Profile System: Top Viewed Widgets";
	$self->{visible} = "all";
	$self->{advertise} = 1;

	# max number of items to display
	$self->{max_display} = 10;
	
	return $self;
}

sub render_content
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $user = $self->{user};

	my $frag = $session->make_doc_fragment;

	my @data = @{$self->get_stats()};

	my $repo_url = $session->get_repository->get_conf( "base_url" );

	if(scalar(@data))
	{
		my $table = $session->make_element( "table" );

		my $thead = $session->make_element( "thead" );
		my $headrow = $session->make_element( "tr" );

		my $headcell = $session->make_element( "th" );
		$headrow->appendChild( $headcell );
		$headcell->appendChild( $session->make_text( "" ) );
		
		$headcell = $session->make_element( "th" );
		$headrow->appendChild( $headcell );
		$headcell->appendChild( $self->html_phrase( "eprinttitle" ) );
		$headcell = $session->make_element( "th" );
		$headcell->appendChild( $session->make_text( "Views" ) );
		$headrow->appendChild( $headcell );
		$thead->appendChild( $headrow );
		$table->appendChild( $thead );

		my $tbody = $session->make_element( "tbody" );

		my $item_count = 0;
		foreach ( @data )
		{
			my $eprint = $_->{eprint};
			my $count = $_->{count};	

			my $tablerow = $session->make_element( "tr" );
			my $cell = $session->make_element( "td" );
			$cell->appendChild( $session->make_text( ++$item_count ) );
			$tablerow->appendChild( $cell );			

			$cell = $session->make_element( "td" );
			my $link = $session->make_element( "a", href=>"$repo_url/".$eprint->get_id );
			$link->appendChild( $session->make_text( $eprint->get_value( "title" ) ) );
			$cell->appendChild( $link );
			$tablerow->appendChild( $cell );
			$tbody->appendChild( $tablerow );
			
			$cell = $session->make_element( "td" );
			$cell->appendChild( $session->make_text( "$count"  ) );
			$tablerow->appendChild( $cell );
		}

		$table->appendChild( $tbody );

		$frag->appendChild( $table );
	}
	else
	{
		$frag->appendChild( $self->html_phrase( "noitems" ) );
	}

	return $frag;

}

sub get_stats
{
	my( $self ) = @_;

	my $user = $self->{user};
	my $session = $self->{session};

	my $list = $user->owned_eprints_list( dataset => $session->dataset( 'archive' ) );

	my $limit = $self->{max_display};
	my @data;

	if(!$list->count()){return \@data;}

	my $ids_string = join(",", @{$list->get_ids()});

	my $sql = "SELECT DISTINCT referent_id, COUNT(referent_id) FROM access WHERE service_type_id='?abstract=yes' AND referent_id IN (".$ids_string.") GROUP BY referent_id ORDER BY COUNT(referent_id) DESC;";

	my $sth = $self->{session}->get_database->prepare( $sql );
	$self->{session}->get_database->execute( $sth , $sql );

	for(my $i=0; $i < $limit; $i++) 
	{
		my @row = $sth->fetchrow_array; 
		if(!@row){last;}
		my $epid = $row[0];
		my $count = $row[1];

		my $eprint = EPrints::DataObj::EPrint->new( $self->{session}, $row[0] );
		next unless( defined $eprint );
	
		push @data, { eprint=>$eprint, count=>$row[1] };
	}

	return \@data;
}











1;

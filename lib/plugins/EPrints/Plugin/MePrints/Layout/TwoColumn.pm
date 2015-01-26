package EPrints::Plugin::MePrints::Layout::TwoColumn;

use strict;

use EPrints::Plugin::MePrints::Layout;
our @ISA = qw/ EPrints::Plugin::MePrints::Layout /;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new(%params);

        $self->{name} = "Widget Default 2-Column Layout";

        return $self;
}

sub render
{
	my( $self ) = @_;

	my $user = $self->{user};

	unless( defined $user )
	{
		return $self->html_phrase( "no_user" );
	}
	
	my $session = $self->{session};

	my $page = $session->make_doc_fragment;
	$page->appendChild( $self->render_core_widgets( ) );

	my $widget_wrapper = $session->make_element( "div", "class"=>"meprints_widget_wrapper"); 
	$page->appendChild( $widget_wrapper );

	my $user_widgets;
	if( $self->{static} )
	{
		$user_widgets = $user->get_profile_widgets();
	}
	else
	{
		$user_widgets = $user->get_homepage_widgets();
	}
	if( $self->{static} || (defined $session->current_user && ( $user->get_id == $session->current_user->get_id ) ) ){
		my $colname = 'left';
		my $column = $session->make_element( "div", class => "ep_profile_column", id => "ep_profile_".$colname."col" );
		$widget_wrapper->appendChild( $column );
		my $counter = 1;	# counter for the scriptaculous wrappers

		foreach my $widget_id ( @$user_widgets )
		{
			if( $widget_id eq '__SEPARATOR__' )
			{
				last if( $colname eq 'right' );
				$colname = 'right';

				if( $counter == 1 )	# i.e. we haven't put any widgets in the previous column
				{
					my $div_msg = $session->make_element( "div", id => "_internal_message_".$colname."col", style=>"font-style:italic;color:#666666;" );
					$column->appendChild( $div_msg );
					$div_msg->appendChild( $session->make_text( "You may drop your widgets here" ) );
				}
				
				$column = $session->make_element( "div", class => "ep_profile_column", id => "ep_profile_".$colname."col" );
				$widget_wrapper->appendChild( $column );
				$counter = 1;
				next;
			}
			
			my $plugin = $session->plugin( "MePrints::Widget::".$widget_id, processor => $self->{processor}, static => $self->{static} );

			if( defined $plugin ) 
			{
				next if( defined $plugin->{enable} && !$plugin->{enable} );

				$plugin->{surround} = 'Simple' if( $self->{static} );

				$plugin->{user} = $user;

				my $box = $plugin->get_surround()->render( "widget" => $plugin, "id" => "meprints_widget_$widget_id", "session" => $session  );

				if( defined $box )
				{
					# wrapper for scriptaculous
					my $wrapper_style = $self->{static} ? "ep_column_item_static" : "ep_column_item";
					my $wrapper = $session->make_element( "div", id=>"epprofile".$colname."_$counter", class => $wrapper_style );
					$column->appendChild( $wrapper );
					$wrapper->appendChild( $box );
					$counter++;
				}
				else
				{
					$column->appendChild( $self->render_placeholder( "$widget_id") );
				}
			}
			else
			{
				$column->appendChild( $self->render_placeholder( "$widget_id") );
			}

			$counter++;
		}

		my $rel_path = $session->get_repository->get_conf( "rel_path" );

		unless( $self->{static} )
		{
			# call to scriptaculous
			if($user->get_id() == $session->current_user()->get_id())
			{
				$page->appendChild( $session->make_javascript( <<JS_DRAGNDROP ) );

Sortable.create('ep_profile_leftcol', {containment: ['ep_profile_leftcol', 'ep_profile_rightcol'], tag: 'div', onUpdate: updateList, dropOnEmpty:true });
Sortable.create('ep_profile_rightcol', {containment: ['ep_profile_leftcol', 'ep_profile_rightcol'],tag: 'div', onUpdate: updateList, dropOnEmpty:true });

function updateList(el,eventobj) 
{ 
	var leftcol = document.getElementById( 'ep_profile_leftcol' );
	if( !leftcol )
		return;

	var l_nodes = leftcol.childNodes;
	var l_order = '';
	var is_first = 1;
	for(var i=0;i<l_nodes.length;i++)
	{
		if( l_nodes[i].id != null && l_nodes[i].id == '_internal_message_leftcol' )
		{
			l_nodes[i].parentNode.removeChild( l_nodes[i] );
		}
		else
		{
			var id = l_nodes[i].childNodes[0].id;

			if( id != null )
			{
				id = id.replace( 'meprints_widget_', '' );

				if( is_first )
				{
					l_order += id;
					is_first = 0;
				}
				else
					l_order += ','+id;
			}
		}
	}

	if( l_order.length == 0 )
	{
		var exists = document.getElementById( '_internal_message_leftcol' );
		if( exists == null )
		{
			var msg = document.createElement( 'div' );
			msg.setAttribute( 'id', '_internal_message_leftcol' );
			msg.style.fontStyle = 'italic';
			msg.style.color = '#666666';
			msg.appendChild( document.createTextNode( 'You may drop your widgets here' ) );
			leftcol.appendChild( msg );
		}


	}
	
	var rightcol = document.getElementById( 'ep_profile_rightcol' );
	if( !rightcol )
		return;

	var r_nodes = rightcol.childNodes;
	var r_order = '';
	is_first = 1;
	for(var i=0;i<r_nodes.length;i++)
	{
		var id = r_nodes[i].childNodes[0].id;
		
		id = id.replace( 'ep_profile_', '' );

		if( is_first )
		{
			r_order += id;
			is_first = 0;
		}
		else
			r_order += ','+id;
	}
	
	var prefs = l_order +',__SEPARATOR__,' + r_order;
	
	new Ajax.Request('$rel_path/cgi/users/meprints/save',
		{
			method: 'post',
			parameters: { 
				prefs: prefs,
				leftcol: l_order,
				rightcol: r_order
			}
		});
	return true; 
};
JS_DRAGNDROP

			}
		}
	$widget_wrapper->appendChild($session->make_element("div", "style"=>"height:1px; width:100%; clear:both;"));
	$page->appendChild( $self->render_bottom_controls( ) );
	}
	return $page;
}

sub get_layoutmgr_id
{
        return 'TwoColumn';
}


1;

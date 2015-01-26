package EPrints::Plugin::Screen::User::Homepage;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new(%params);

	return $self if( defined $self->{session} && !$self->{session}->config( "meprints_enabled" ) );

        $self->{appears} = [
                {
                        place => "key_tools",
                        position => 99,
                },
        ];

	# default Layout Manager:
	$self->{layout_mgr} = "MePrints::Layout::TwoColumn";

        return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return 0 unless( defined $self->{session} && $self->{session}->config( 'meprints_enabled' ) );

	return 0 unless( defined $self->{session}->current_user );

	my $user = EPrints::Plugin::MePrints::get_user( $self->{session} );
	return $self->{session}->current_user->allow( "user/view", $user );
}


sub properties_from
{
        my( $self ) = @_;

	my $user = EPrints::Plugin::MePrints::get_user( $self->{session} );

	if( defined $user )
	{
		$self->{processor}->{user} = $user;
		$self->{processor}->{userid} = $user->get_id;
	}
	else
        {
		# sf2 / should never happen since get_user() returns current_user in the worse case
                $self->{processor}->{screenid} = "Error";
                $self->{processor}->add_message( "error",
                        $self->html_phrase(
                                "no_such_user",
                                id => $self->{session}->make_text(
                                                $self->{processor}->{userid} ) ) );
                return;
        }

        $self->{processor}->{dataset} = $self->{processor}->{user}->get_dataset;

}

sub redirect_to_me_url
{
        my( $self ) = @_;

        return $self->SUPER::redirect_to_me_url."&userid=".$self->{processor}->{userid};
}


sub render
{
	my( $self ) = @_;

	my $page = $self->{session}->make_doc_fragment;
	
	my $user = $self->{processor}->{user};
	return $page unless( defined $user );
		
	my $layoutmgr = $self->{session}->plugin( $self->{layout_mgr},
							user => $user, 
							processor => $self->{processor},
	);

	unless( defined $layoutmgr )
	{
		$self->{session}->log("Failed to load the Widget Layout Manager.");
		return $self->html_phrase( "layoutmgr_error" );
	} 


	# render help
	my $imagesurl = $self->{session}->config( "rel_path" )."/style/images";
        my $repo_url = $self->{session}->config( "base_url" );
	
	my $style_url_text = $self->{session}->make_text( $repo_url."/style/meprints_embed.css" );
	my $url_text;
	my $profile_url;

	if( $self->{session}->config( "meprints_profile_with_username" ) )
	{
		my $username = $user->get_value( "username" );
		$url_text = $self->{session}->make_text( $repo_url."/cgi/meprints/embed_js?username=$username"  );

		$profile_url = $self->{session}->make_element( "a", href => "$repo_url/profile/$username" );
		$profile_url->appendChild( $self->{session}->make_text( "$repo_url/profile/$username" ) );
	}
	else
	{
		my $userid = $user->get_id;
		$url_text = $self->{session}->make_text( $repo_url."/cgi/meprints/embed_js?userid=$userid"  );

		$profile_url = $self->{session}->make_element( "a", href => "$repo_url/profile/$userid" );
		$profile_url->appendChild( $self->{session}->make_text( "$repo_url/profile/$userid" ) );
	}

        my %options;
        $options{session} = $self->{session};
        $options{id} = "ep_review_instructions";
        $options{title} = $self->{session}->html_phrase( "Plugin/Screen/User/Homepage:help_title" );

        $options{content} = $self->{session}->html_phrase( "Plugin/Screen/User/Homepage:help",
					profile_url => $profile_url,
					embed_style_url => $style_url_text,
					embed_url => $url_text 
	);
        
	$options{collapsed} = 1;
        $options{show_icon_url} = "$imagesurl/help.gif";
        my $box = $self->{session}->make_element( "div", style=>"text-align: left" );
        $box->appendChild( EPrints::Box::render( %options ) );
        $page->appendChild( $box );

	$page->appendChild( $layoutmgr->render() );
	
	return $page;
}

# DEPRECATED
sub get_user
{
	my( $self ) = @_;

	return EPrints::Plugin::MePrints::get_user( $self->{session} );
}


sub register_furniture
{
	# to avoid Screen::User::register_furniture to be called (this would crash)
}

# this carries out actions performed by Widgets
sub from
{
        my( $self ) = @_;

        my $action_id = $self->{processor}->{action};

        return if( !defined $action_id || $action_id eq "" );

        return if( $action_id eq "null" );

        # If you hit reload after login you can cause a
        # login action, so we'll just ignore it.
        return if( $action_id eq "login" );

	my $widget_id = $self->{session}->param( 'widget' );

        if( !defined $widget_id )
        {
                $self->{processor}->add_message( "error",
                        $self->{session}->html_phrase(
                                "Plugin/Screen:unknown_action",
                                action=>$self->{session}->make_text( $action_id ),
                                screen=>$self->{session}->make_text( $self->{processor}->{screenid} ) ) );
                return;
        }
	
	return unless( $widget_id =~ /^MePrints::/ );

	my $widget = $self->{session}->plugin( "$widget_id", user=>$self->{session}->current_user );

        if( !defined $widget )
        {
                $self->{processor}->add_message( "error",
                        $self->{session}->html_phrase(
                                "Plugin/Screen:unknown_action",
                                action=>$self->{session}->make_text( $action_id ),
                                screen=>$self->{session}->make_text( $self->{processor}->{screenid} ) ) );
                return;
        }

	my $allow = "allow_$action_id";
	if( $widget->$allow )
        {
                my $fn = "action_".$action_id;
                $widget->$fn;
		my $url = $widget->{redirect};
		$self->{processor}->{redirect} = $url if( defined $url );
        }
        else
        {
                $self->{processor}->action_not_allowed(
                        $self->html_phrase( "action:$action_id:title" ) );
        }
}


1;


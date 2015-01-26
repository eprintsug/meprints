package EPrints::Plugin::MePrints;

use strict;
use warnings;

sub get_user
{
	my( $session ) = @_;

	my $user;

	my $userid = $session->param( 'userid' );
	$user = $session->dataset( 'user' )->dataobj( $userid );

	unless( defined $user )
	{
		$user = $session->current_user;
	}

	return $user;
}

our @ISA = qw/ EPrints::Plugin /;

package EPrints::DataObj::User;

no warnings;

sub can_request_view_profile
{
	my( $self, $session ) = @_;

# sf2 - not ideal cos a user might not be allowed by EPrints to "view" a user but the profile is public (which people not logged in could view hence they'd have more "power"
# than a logged-in user, odd)
#
#	if( defined $session->current_user )
#	{
#		return $session->current_user->allow( 'user/view', $self );
#	}
	
	return $self->is_profile_visible;
}

sub is_profile_visible
{
	my( $self ) = @_;

	return ($self->get_value( "real_profile_visibility" ) eq 'public');
}

sub get_url
{
	my( $self ) = @_;

	return $self->_get_url_default() if( !$self->{session}->config( "meprints_enabled" ) );

	unless( $self->{session}->config( "meprints_profile_with_username" ) )
	{
		return $self->{session}->config( "base_url" )."/profile/".$self->get_id;
	}

	return $self->{session}->config( "base_url" )."/profile/".$self->get_value( "username" );
}

sub _get_url_default
{
        my( $self ) = @_;

	return $self->get_control_url;
}

sub get_picture_path
{
	my( $self ) = @_;
	my $userpath = $self->_userid_to_path();
	return $self->{session}->config("archiveroot")."/meprints/$userpath/picture";
}

sub get_picture_url
{
	my( $self ) = @_;
	return $self->{session}->config("rel_path")."/cgi/meprints/thumbnail?userid=".$self->get_id;
}

sub remove_static
{
	my( $self ) = @_;
	EPrints::Utils::rmtree( $self->localpath( ) );
	return;
}

sub localpath
{
	my( $self ) = @_;
	my $userpath = $self->_userid_to_path();
	return $self->{session}->config( "archiveroot" )."/meprints/$userpath/profile";
}

sub generate_static
{
        my( $self ) = @_;

        $self->{session}->{preparing_static_page} = 1;

        $self->remove_static;

	my $full_path = $self->localpath();

	my @created = EPrints::Platform::mkdir( $full_path );

	my $layoutmgr = $self->{session}->plugin( "MePrints::Layout::TwoColumn",
							static => 1,
							user => $self 
	);

	unless( defined $layoutmgr )
	{
		$self->{session}->log( "Error: failed to load the Widget Layout Manager." );
		return $self->{session}->html_phrase( "layoutmgr_error" );
	} 

	my $page = $self->{session}->make_doc_fragment;

	my $title;
	if( defined $self->{session}->config( 'meprints', 'profile', 'use_name_as_title' ) &&
		 $self->{session}->config( 'meprints', 'profile', 'use_name_as_title' ) )
	{
		$title = $self->render_value( 'name' );
	}
	else
	{
	#  EPrints Services/pjw 2011-01-31 http://servicesjira.eprints.org:8080/browse/EDGE-58
		$title = $self->{session}->html_phrase( "meprints:profile:title" );
	}
	my $links = $self->{session}->make_doc_fragment();
	
	$page->appendChild( $layoutmgr->render() );
	
	$self->{session}->write_static_page(
		$full_path."/index",
		{title=>$title, page=>$page, head=>$links },
		"default"
	);

	delete $self->{session}->{preparing_static_page};
	
	return $page;
}

sub set_homepage_widgets
{
	my( $self, $widgets ) = @_;

	# Avoid race-conditions
	return 0 if( $self->{setting_homepage} );
	$self->{setting_homepage} = 1;

	$self->set_value( "homepage_preferences", $widgets );
	
	my $rc = $self->commit(1);
	delete $self->{setting_homepage};
	return $rc;
}

sub get_homepage_widgets
{
	my( $self ) = @_;

	my $widgets = $self->get_value( "homepage_preferences" );
	
	return $widgets if( scalar(@$widgets) );

	return $self->{session}->config( "user_homepage_defaults" );
}

sub get_profile_widgets
{
	my( $self ) = @_;

	return $self->{session}->config( "user_profile_defaults" );
}

sub _userid_to_path
{
        my( $self ) = @_;
        my $userid = $self->get_id;
        return unless( $userid =~ m/^\d+$/ );
        my( $a, $b, $c, $d );
        $d = $userid % 100;
        $userid = int( $userid / 100 );
        $c = $userid % 100;
        $userid = int( $userid / 100 );
        $b = $userid % 100;
        $userid = int( $userid / 100 );
        $a = $userid % 100;
        return sprintf( "%02d/%02d/%02d/%02d", $a, $b, $c, $d );
}

1;


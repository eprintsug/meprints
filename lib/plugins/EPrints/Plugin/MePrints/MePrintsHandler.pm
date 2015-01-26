package EPrints::Plugin::MePrints::MePrintsHandler;

use strict;
use warnings;

our @ISA = qw/ EPrints::Plugin /;

use EPrints;
use EPrints::Apache::AnApache;

sub handler
{
	my( $r ) = @_;

	my $uri = $r->uri;

	if( $uri =~ m! ^\/profile\/([0-9a-zA-Z]+)(.*)$ !x )
	{
		my $repository = $EPrints::HANDLE->current_repository;
		return DECLINED if( !defined $repository );

		# MePrints enabled for this repo?
		return DECLINED unless( $repository->config( "meprints_enabled" ) );

		my $user;
		my $user_identifier = $1;

		if( $repository->config( "meprints_profile_with_username" ) )
		{
			if( $user_identifier =~ m! ^([a-zA-Z0-9]+)$ !x )
			{
				# Handle a username.
				$user = $repository->user_by_username( $1 );
			}
		}
		else
		{
			if( $user_identifier =~ m! ^([0-9]+)$ !x )
			{
				# Handle the userid.
				$user = $repository->user( $1 );
			}
		}		
		
		if( defined $user )
		{
			if( $user->can_request_view_profile( $repository ) )
			{
				&update( $repository, $user );

				my $page = $user->localpath."/index.html";

				if( -e $page )
				{
					$r->pnotes( user => $user );
					$r->filename( $page );
					EPrints::Apache::Template::handler( $r ); 
					return OK;
				}
			}
			else
			{
				return FORBIDDEN
			}
		}
	
		# Since the user has not been found they do not exist.
		# As a user profile was requested it is not appropriate
		# to continue to attempt parsing. The lack of any return
		# raises a 404 error which is handled in the standard 
		# way.
		
	}

	return DECLINED;
	
}

sub update
{
	my( $repository, $user ) = @_;

	my $targetfile = $user->localpath()."/index.html";

	# if targetfile does not exist, we need to generate the profile
	if( -e $targetfile )
	{
		my $timestampfile = $repository->config( "variables_path" )."/meprints.timestamp";
		my $need_to_update = 0;
		if( -e $timestampfile )
		{
			my $poketime = (stat( $timestampfile ))[9];
			my $targettime = (stat( $targetfile ))[9];
			if( $targettime < $poketime ) { $need_to_update = 1; }
		}

		return unless $need_to_update;
	}
	$user->generate_static();
}

1;

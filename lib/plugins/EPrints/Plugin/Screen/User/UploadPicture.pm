package EPrints::Plugin::Screen::User::UploadPicture;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use Fcntl qw(:DEFAULT :seek);
use File::Temp qw/ tempfile /;

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	if( defined $self->{session} && !$self->{session}->config( "meprints_enabled" ) )
	{
		return $self;
	}

	$self->{actions} = [qw/ cancel upload resetpic /];

	$self->{appears} = [
		{
			place => "user_actions",
			position => 1000,
		}
	];
        
#	$self->{sizes} = {
#		preview => "120x160",
#		small => "30x40",
#	};

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

        return 0 unless( defined $self->{session} && defined $self->{session}->current_user );

	my $user = EPrints::Plugin::MePrints::get_user( $self->{session} );
        return $self->{session}->current_user->allow( 'user/edit', $user );
}

sub properties_from
{
        my( $self ) = @_;

        $self->EPrints::Plugin::Screen::User::Homepage::properties_from;
}

sub redirect_to_me_url
{
        my( $self ) = @_;

        return $self->SUPER::redirect_to_me_url."&userid=".$self->{processor}->{userid};
}

sub allow_cancel
{
	my( $self ) = @_;

	return $self->can_be_viewed;
}

sub action_cancel
{
	my( $self ) = @_;

	$self->{processor}->{screenid} = "User::Homepage";
}	

sub allow_upload
{
	my( $self ) = @_;

	return $self->can_be_viewed;
}

sub action_upload
{
	my( $self ) = @_;
	
	my $session = $self->{session};
	my $picture = $session->param( "file_0" );

	my $user = $self->{processor}->{user};
	return unless( defined $user );

        unless( EPrints::Utils::is_set( $picture ) )
        {
                $self->{processor}->add_message( "error", $self->html_phrase( "nothing_to_do" ) );
                return;
        }

        my $filename = $picture;

        if( $picture =~ /^(.*)\/(.*)$/ )
        {
                $picture = $2;
        }
        if( $picture =~ /^(.*)\\(.*)$/ )
        {
                $picture = $2;
        }

        my $upload_fh = $self->{session}->{query}->upload( "file_0" );
        my $tmp_file = new File::Temp( UNLINK => 1 );
        my $tmp_fn = $tmp_file->filename;
        $tmp_file->autoflush;

        if(defined $upload_fh && defined $tmp_file)
        {
                seek( $upload_fh, 0, SEEK_SET );
                my $buffer ;
                while( read( $upload_fh, $buffer, 4096 ) )
                {
                        print $tmp_file $buffer;
                }
        }
        else
        {
                $self->{processor}->add_message( "error", $self->html_phrase( "upload_failure" ) );
                return;
        }

	my $convert = $session->config( 'executables', 'convert' );

	unless(defined $convert)
	{
                $self->{processor}->add_message( "error", $self->html_phrase( "upload_failure" ) );
                return;
	}

        unless( -s $tmp_fn )
        {
                $self->{processor}->add_message( "error", $self->html_phrase( "upload_failure" ) );
                return ();
        }


	my $sizes = $self->param( "sizes" );

	if( !$sizes )
	{
        	$sizes = {
			preview => "120x160", 
			small => "30x40"
		};
	}

	foreach my $picname ( keys %{$sizes||{}})
	{
		my $fn = $picname.".png";
		my $picsize = $sizes->{$picname};

		my $dir = $user->get_picture_path();
		
		unless( -e $dir )
		{
			EPrints::Platform::mkdir( $dir );
		}

		system($convert, "-size","$picsize>", $tmp_fn, '-resize', "$picsize>", $dir . '/' . $fn );

		unless( -e "$dir/$fn" ) 
		{
			$self->{processor}->add_message( "error", $self->html_phrase( "upload_failure" ) );
			return;
		}

		EPrints::Utils::chown_for_eprints( "$dir/$fn" );
	}

        $self->{processor}->add_message( "message", $self->html_phrase( "upload_success" ) );
	$self->{processor}->{screenid} = "User::View";
}

sub allow_resetpic
{
	my( $self ) = @_;

	return $self->can_be_viewed;
}


sub action_resetpic
{
	my( $self ) = @_;

	my $user = $self->{processor}->{user};
	return unless( defined $user );

	my $dir = $user->get_picture_path();
	
	if( (! -e $dir) || EPrints::Utils::rmtree( $dir ))
	{
	        $self->{processor}->add_message( "message", $self->html_phrase( "resetpic_success" ) );
	}
	else
	{
        	$self->{processor}->add_message( "error", $self->html_phrase( "resetpic_failure" ) );
	}

	$self->{processor}->{screenid} = "User::View";
}	

sub render
{
        my( $self ) = @_;

        my $session = $self->{session};

	my $chunk = $session->make_doc_fragment;

	my $user = $self->{processor}->{user};
	return $chunk unless( defined $user );

        my $form =  $session->render_form( "post" );
	$chunk->appendChild( $form );

	$form->appendChild( $self->render_hidden_bits );

	my $div = $session->make_element( "div", "class"=>"ed_profilepic_box" );
	$div->appendChild( $self->html_phrase( "profile_blurb" ) );
	$form->appendChild( $div );
	$form->appendChild( $session->render_hidden_field( "userid", $user->get_id ) );

	my $container = $session->make_element( "div", "style"=>"margin-left:auto;margin-right:auto;margin-top:10px;",align=>"center" );
	$div->appendChild( $container );

        my $input = $session->make_element( "input", "type"=>"file",
                                                "name" => "file_0");
        $container->appendChild( $input );
	$form->appendChild( $self->render_buttons );
	
        return $chunk;
}


sub render_buttons
{
	my( $self ) = @_;

	my %buttons = ( _order=>[], _class=>"ep_form_button_bar" );

	push @{$buttons{_order}}, "upload", "resetpic", "cancel";
	$buttons{cancel} = $self->phrase( "cancel" );
	$buttons{upload} = $self->phrase( "upload" );
	$buttons{resetpic} = $self->phrase( "resetpic" );

	return $self->{session}->render_action_buttons( %buttons );
}

1;



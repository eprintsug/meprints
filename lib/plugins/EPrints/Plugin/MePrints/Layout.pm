package EPrints::Plugin::MePrints::Layout;

use strict;

use EPrints::Plugin;
our @ISA = qw/ EPrints::Plugin /;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new(%params);

        $self->{name} = "Widget Layout Abstract Class";

	$self->{user} = $params{user};

        return $self;
}

# render should be overridden by the actual Layout Manager
sub render
{
	my( $self ) = @_;
	return $self->html_phrase( "render_no_subclass" );
}

# to use when there's a problem loading a widget
sub render_placeholder
{
        my ($self, $plugin_id ) = @_;
	return $self->{session}->html_phrase( "Plugin/MePrints/Layout:placeholder", widget_id => $self->{session}->make_text( $plugin_id ) );
}

sub render_widget
{
	my( $self, $widgetid, %params ) = @_;

	my $widget = $self->{session}->plugin( "MePrints::Widget::$widgetid", %params );

	if( !defined $widget )
	{
		return $self->{session}->make_text( "Fatal error with Widget '$widgetid'" );
	}

	return $widget->render( id => "meprints_widget_$widgetid" );
}

sub render_core_widgets
{
	my( $self ) = @_;

	my $session = $self->{session};

	my %params = (
		processor => $self->{processor},
		static => $self->{static},
		user => $self->{user}
	);

	my $frag = $session->make_doc_fragment;

	$frag->appendChild( $self->render_widget( 'Details', %params ) );

	if( !$self->{static} )
	{
		my $bar = $frag->appendChild( $session->make_element( 'div', class => 'meprints_bar' ) );
		$bar->appendChild( $self->render_widget( 'QuickLinks', %params ) );
	}

	return $frag;
}


sub render_bottom_controls
{
	my( $self ) = @_;

	return $self->{session}->make_doc_fragment if( $self->{static} );

	my $user = $self->{user};
	# don't render the bottom controls when we're seeing another user's homepage
	return $self->{session}->make_doc_fragment unless( $user->get_id == $self->{session}->current_user->get_id );

	my $layoutmgr = $self->get_layoutmgr_id();

	my $div = $self->{session}->make_element( "div", style=>"clear:both;" );

	my %users_widgets = map { $_ => 1 } @{$user->get_homepage_widgets()};
	my $all_widgets = $self->get_widgets();

	my $controlbox = $self->{session}->make_element( "div", class=>"ep_columns_add" );
	$div->appendChild( $controlbox );

## ADD WIDGET ##
	my $add_form = $self->{session}->render_form( 'get', $self->{session}->get_repository->get_conf( "rel_path" )."/cgi/users/home" );
	$controlbox->appendChild( $add_form );

	$add_form->appendChild( $self->{session}->render_hidden_field( 'screen', 'User::Homepage' ) );
	$add_form->appendChild( $self->{session}->render_hidden_field( 'widget', "MePrints::Layout::$layoutmgr" ) );

	my $add_list = $self->{session}->make_element( "select", id=>"add_widget_params", name => "add_widget_params" );
	$add_form->appendChild( $add_list );
	
	my $add_button = $self->{session}->make_element( "input",
					type => "submit",
					class => "ep_form_action_button",
					onclick => "return EPJS_button_pushed( '_action_add_widget' );",
					name => "_action_add_widget",
					value => $self->phrase( "add_widget" ) );

	$add_form->appendChild( $add_button );

### REMOVE WIDGET ####
	my $rem_form = $self->{session}->render_form( 'get', $self->{session}->get_repository->get_conf( "rel_path" )."/cgi/users/home" );
	$controlbox->appendChild( $rem_form );

	$rem_form->appendChild( $self->{session}->render_hidden_field( 'screen', 'User::Homepage' ) );
	$rem_form->appendChild( $self->{session}->render_hidden_field( 'widget', "MePrints::Layout::$layoutmgr" ) );

	my $rem_list = $self->{session}->make_element( "select", id=>"remove_widget_params", name => "remove_widget_params" );
	$rem_form->appendChild( $rem_list );

	my $rem_button = $self->{session}->make_element( "input",
					type => "submit",
					class => "ep_form_action_button",
					onclick => "return EPJS_button_pushed( '_action_remove_widget' );",
					name => "_action_remove_widget",
					value => $self->phrase( "remove_widget" ) );
	$rem_form->appendChild( $rem_button );

	my $add_counter = 0;
	my $rem_counter = 0;

	foreach my $widget_id ( @$all_widgets )
	{
		my $widget = $self->{session}->plugin( "MePrints::Widget::$widget_id" );
		next unless( defined $widget && $widget->{enable} );

		next unless( $widget->{show_in_controls} );
		
		my $opt = $self->{session}->make_element( "option", value=>"$widget_id", name=>"$widget_id" );
		$opt->appendChild( $widget->html_phrase( "title" ) );

		if( $users_widgets{$widget_id} )
		{
			# on the remove list
			$rem_list->appendChild( $opt );
			$rem_counter++;
		}
		else
		{
			# on the add list
			$add_list->appendChild( $opt );
			$add_counter++;
		}
	}

	unless( $add_counter )
	{
		$add_button->setAttribute( "disabled", "disabled" );
		$add_list->setAttribute( "disabled", "disabled" );
	}
	
	unless( $rem_counter )
	{
		$rem_button->setAttribute( "disabled", "disabled" );
		$rem_list->setAttribute( "disabled", "disabled" );
	}

	my $reset_form = $self->{session}->render_form( 'get', $self->{session}->get_repository->get_conf( "rel_path" )."/cgi/users/home" );
	$controlbox->appendChild( $reset_form );
	$reset_form->appendChild( $self->{session}->render_hidden_field( 'screen', 'User::Homepage' ) );
	$reset_form->appendChild( $self->{session}->render_hidden_field( 'widget', "MePrints::Layout::$layoutmgr" ) );

	$reset_form->appendChild( $self->{session}->make_element( "input",
					type => "submit",
					class => "ep_form_action_button",
					onclick => "return EPJS_button_pushed( '_action_resetprefs' );",
					name => "_action_resetprefs",
					value => $self->phrase( "resetprefs" ) ));


	return $div;
}

# should be subclassed
sub get_layoutmgr_id
{
	my( $self ) = @_;
	$self->{session}->get_repository->log( "MePrints::Layout::get_layoutmgr_id should be subclassed." );
	return "";
}

sub get_widgets
{
	my( $self ) = @_;
	
	my @ids = $self->{session}->plugin_list( type => 'MePrints' );

	my @widgets;
	
	foreach(@ids)
	{	
		push @widgets, $1 if($_ =~ /^MePrints::Widget::(.*)$/ );
	}
	
	return \@widgets;
}

sub get_users_widgets
{
	my( $self ) = @_;

	my $widget_ids = $self->{user}->get_homepage_widgets if( defined $self->{user} );

	my @users_widgets;
	foreach( @$widget_ids )
	{
		next if( $_ eq '__SEPARATOR__' );
		my $widget = $self->{session}->plugin( "MePrints::Widget::$_" );
		next unless( defined $widget && $widget->{enable} );
		push @users_widgets, $_;
	}

	return \@users_widgets;
}

sub allow_remove_widget
{
	return 1;
}

sub action_remove_widget
{
	my ( $self ) = @_;
	
	my $widget = $self->{session}->param( 'remove_widget_params' );
	
	if( defined $widget )
	{
		my $user_widgets = $self->{session}->current_user->get_homepage_widgets();
		my @new_widgets;

		foreach(@$user_widgets)
		{
			push @new_widgets, $_ unless( $_ eq $widget );
		}

		$self->{session}->current_user->set_homepage_widgets( \@new_widgets );
	}

	return;
}

sub allow_add_widget
{
	return 1;
}

sub action_add_widget
{
	my( $self ) = @_;

	my $widget = $self->{session}->param( 'add_widget_params' );
	
	if( defined $widget )
	{
		my $user_widgets = $self->{session}->current_user->get_homepage_widgets();
		push @$user_widgets, $widget;
		$self->{session}->current_user->set_homepage_widgets( $user_widgets );
	}

	$self->{session}->redirect( $self->{session}->get_repository->get_conf( "rel_path" ).'/cgi/users/home?screen=User::Homepage' );
}

sub allow_resetprefs
{
	return 1;
}

sub action_resetprefs
{
	my( $self ) = @_;

	return unless( defined $self->{user} );

	$self->{user}->set_homepage_widgets( undef );

	$self->{session}->redirect( $self->{session}->get_repository->get_conf( "rel_path" ).'/cgi/users/home?screen=User::Homepage' );
}

1;

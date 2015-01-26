package EPrints::Plugin::MePrints::Widget;

# Top level widget, abstract

use strict;
use EPrints::Plugin;
our @ISA = qw/ EPrints::Plugin /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);	

	$self->{render_title} = 1;

	if ( defined $self->{static} && $self->{static} == 1 )
	{
		$self->{surround} = "Simple";
	}

	$self->{enable} = 1;
	$self->{show_in_controls} = 1;

	return $self;
}

sub has_title
{
	my( $self ) = @_;

	return ( defined $self->{render_title} ) ? $self->{render_title} : 1;
}

sub render
{
	my( $self, %params ) = @_;

	$params{widget} = $self;
	$params{session} = $self->{session};

	return $self->get_surround()->render( %params );
}

sub render_title
{
	my( $self ) = @_;

	if( $self->has_title() )
	{
		return $self->html_phrase( 'title' );
	}

	return $self->{session}->make_doc_fragment;
}

sub render_content
{
	my( $self ) = @_;

	return $self->{session}->html_phrase( "Plugin/MePrints/Widget:no_render_subclass" );
}

sub about_to_render 
{
	my( $self ) = @_;
}

sub can_be_viewed
{
	my( $self ) = @_;
	return 1;
}

sub is_collapsed
{
	my( $self ) = @_;
	return 0;
}

sub get_surround
{
        my( $self ) = @_;

        my $surround = "Box";

        if( EPrints::Utils::is_set( $self->{surround} ) )
        {
                $surround = $self->{surround};
        }

        my $surround_obj = $self->{session}->plugin( "MePrints::Render::$surround" );

        if( !defined $surround_obj )
        {
                $surround_obj = $self->{session}->plugin( "MePrints::Render::Box" );
        }

        return $surround_obj;
}

sub is_static
{
	my( $self ) = @_;

	my $is_static = 0;

	if( defined $self->{static} && $self->{static} == 1 )
	{
		$is_static = 1;
	}

	return $is_static;
}
1;


package EPrints::Plugin::MePrints::Render::Simple;

use strict;

use EPrints::Plugin;
our @ISA = qw/ EPrints::Plugin /;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new(%params);

        $self->{name} = "Widget Render Simple";

        return $self;
}

sub render
{
	my( $self, %options ) = @_;

	for( 'widget', 'session' )
	{
		EPrints::abort( "Plugin::Widget::Render::Simple::render called without param '$_'" ) if( !defined $options{$_} );
	}

	my $session = $options{session};
	my $widget = $options{widget};

	my $id = $options{id};
	my $contentid = $id."_content";

	my $content = $session->make_element( "div", id=>$id, style=> $options{content_style} );
	
	if( $widget->has_title() )
	{
		my $title = $content->appendChild( $session->make_element( "h2" ) );
		$title->appendChild( $widget->render_title() );
	}
	
	$content->appendChild( $widget->render_content() );

	return $content;	
}

1;


package EPrints::Plugin::MePrints::Render::Box;

use strict;

use EPrints::Plugin;
our @ISA = qw/ EPrints::Plugin /;

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new(%params);

        $self->{name} = "Widget Render Box";

        return $self;
}


sub render
{
	my( $self, %options ) = @_;

	if( !defined $options{session} ) { EPrints::abort( "Plugin::Widget::Render::Box::render called without a session. Bad bad bad." ); }
	if( !defined $options{widget} ) { EPrints::abort( "Plugin::Widget::Render::Box::render called without a widget. Bad bad bad." ); }
	if( !defined $options{id} ) { EPrints::abort( "Plugin::Widget::Render::Box::render called without a id. Bad bad bad." ); }

	my $widget = $options{widget};
	$options{content} = $widget->render_content();
	$options{title} = $widget->render_title();
	$options{collapsed} = $widget->is_collapsed();

	my $session = $options{session};
	my $imagesurl = $session->get_repository->get_conf( "rel_path" );
	if( !defined $options{show_icon_url} ) { $options{show_icon_url} = "$imagesurl/style/images/plus.png"; }
	if( !defined $options{hide_icon_url} ) { $options{hide_icon_url} = "$imagesurl/style/images/minus.png"; }

	my $id = $options{id};
		
	my $contentid = $id."_content";
	my $colbarid = $id."_colbar";
	my $barid = $id."_bar";
	my $div = $session->make_element( "div", class=>"meprints_box", id=>$id );

	# Title
	my $div_title = $session->make_element( "div", class=>"meprints_box_title" );
	$div->appendChild( $div_title );

	my $nojstitle = $session->make_element( "div", class=>"ep_no_js" );
	$nojstitle->appendChild( $session->clone_for_me( $options{title},1 ) );
	$div_title->appendChild( $nojstitle );

	my $collapse_bar = $session->make_element( "div", class=>"ep_only_js", id=>$colbarid );
	$collapse_bar->appendChild( $session->clone_for_me( $options{title},1 ) );
	$div_title->appendChild( $collapse_bar );

	my $a = "true";
	my $b = "false";
	
	my $uncollapse_bar = $session->make_element( "div", class=>"ep_only_js", id=>$barid );
	my $uncollapse_link = $session->make_element( "a", id=>$barid, class=>"ep_box_collapse_link", onclick => "EPJS_blur(event); EPJS_toggleSlideScroll('${contentid}',false,'${id}');EPJS_toggle('${colbarid}',$a);EPJS_toggle('${barid}',$b);return false", href=>"#" );
	$uncollapse_link->appendChild( $session->make_element( "img", alt=>"+", src=>$options{show_icon_url}, border=>0 ) );
	$uncollapse_link->appendChild( $session->make_text( " " ) );
	$uncollapse_link->appendChild( $session->clone_for_me( $options{title},1 ) );
	$uncollapse_bar->appendChild( $uncollapse_link );
	$div_title->appendChild( $uncollapse_bar );

	# Body	
	my $div_body = $session->make_element( "div", class=>"meprints_box_body", id=>$contentid );
	my $div_body_inner = $session->make_element( "div", id=>$contentid."_inner", style=>$options{content_style} );
	$div_body->appendChild( $div_body_inner );
	$div->appendChild( $div_body );
	$div_body_inner->appendChild( $options{content} );

	if( $options{collapsed} ) 
	{ 
		$collapse_bar->setAttribute( "style", "display: none" ); 
		$div_body->setAttribute( "style", "display: none" ); 
	}
	else
	{
		$uncollapse_bar->setAttribute( "style", "display: none" ); 
	}
		
	return $div;
}

1;


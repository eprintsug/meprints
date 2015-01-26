package EPrints::Plugin::Screen::EPMC::MePrints;

@ISA = ( 'EPrints::Plugin::Screen::EPMC' );

use strict;

sub new
{
      my( $class, %params ) = @_;

      my $self = $class->SUPER::new( %params );

      $self->{actions} = [qw( enable disable )];
      $self->{disable} = 0; # always enabled, even in lib/plugins

      $self->{package_name} = "meprints";

      return $self;
}

=item $screen->action_enable( [ SKIP_RELOAD ] )

Enable the L<EPrints::DataObj::EPM> for the current repository.

If SKIP_RELOAD is true will not reload the repository configuration.

=cut

sub action_enable
{
      my( $self, $skip_reload ) = @_;

      $self->SUPER::action_enable( $skip_reload );

      my $repo = $self->{repository};

      my $xml = <<XML;

 <workflow xmlns="http://eprints.org/ep3/workflow" xmlns:epc="http://eprints.org/ep3/control">

   <flow>
	   <epc:if test="\$config{meprints_enabled}"><stage ref="meprints"/></epc:if>
   </flow>

   <stage name="meprints">
	<component type="Field::Multi">
		<title><epc:phrase ref="user_section_meprints" /></title>
		<field ref="user_profile_visibility" required="yes"/>
		<field ref="jobtitle"/>
		<field ref="expertise"/>
		<field ref="biography"/>
		<field ref="qualifications"/>
	</component>
   </stage>

</workflow>

XML

      my $filename = $repo->config( "config_path" )."/workflows/user/default.xml";

      EPrints::XML::add_to_xml( $filename, $xml, $self->{package_name} );

      my $timestamp_path = $repo->config( "archiveroot" )."/var/meprints.timestamp"; 

	if( !-e $timestamp_path )
	{
		# create the file
		open( TIMESTAMP, "+>$timestamp_path" );
		print TIMESTAMP "MePrints timestamp file\n";
		close( TIMESTAMP );
	}

      $self->reload_config if !$skip_reload;
}

=item $screen->action_disable( [ SKIP_RELOAD ] )

Disable the L<EPrints::DataObj::EPM> for the current repository.

If SKIP_RELOAD is true will not reload the repository configuration.

=cut

sub action_disable
{
      my( $self, $skip_reload ) = @_;

      $self->SUPER::action_disable( $skip_reload );
      my $repo = $self->{repository};

      my $filename = $repo->config( "config_path" )."/workflows/user/default.xml";
 
      EPrints::XML::remove_package_from_xml( $filename, $self->{package_name} );

      my $timestamp_path = $repo->config( "archiveroot" )."/var/meprints.timestamp"; 

	if( -e $timestamp_path )
	{
		unlink $timestamp_path;
	}
      
      $self->reload_config if !$skip_reload;

}

1;


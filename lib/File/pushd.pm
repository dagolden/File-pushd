package File::pushd;
use strict;
use warnings;
use Carp;
use File::Spec;
use Cwd;

use overload 
    q{""} => \&as_string
;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT);
	$VERSION     = '0.10';
	@ISA         = qw (Exporter);
	@EXPORT      = qw (pushd);
}

#--------------------------------------------------------------------------#
# main pod documentation 
#--------------------------------------------------------------------------#

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

File::pushd - temporary chdir until the end of a scope 

=head1 SYNOPSIS

 use File::pushd;

 chdir $ENV{HOME};

 {
     # changes to /tmp
     my $dir = pushd( '/tmp' );
 }
 
 # working directory reverted to $ENV{HOME}

=head1 DESCRIPTION

Description...

=head1 USAGE

Usage...

=cut

#--------------------------------------------------------------------------#
# pushd()
#--------------------------------------------------------------------------#

=head2 pushd

 $dir = pushd( $target_directory);

Description of pushd...

=cut

sub pushd {
    my ($target_dir) = @_;
    
    my $orig = Cwd::abs_path();
    chdir Cwd::abs_path( File::Spec->catdir( $orig, $target_dir ) );
    my $self = { 
        original => $orig,
        cwd => Cwd::abs_path(),
    };
    bless $self, __PACKAGE__;
    return $self;
}

#--------------------------------------------------------------------------#
# DESTROY()
#--------------------------------------------------------------------------#

=head2 DESTROY

 $rv = DESTROY();

Description of DESTROY...

=cut

sub DESTROY {
	my ($self) = @_;
    chdir $self->{original};
}


#--------------------------------------------------------------------------#
# as_string()
#--------------------------------------------------------------------------#

=head2 as_string

 $rv = as_string();

Description of as_string...

=cut

sub as_string {
	my ($self) = @_;
    return $self->{cwd};
}


1; #this line is important and will help the module return a true value
__END__

=head1 BUGS

Please report bugs using the CPAN Request Tracker at 
http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-pushd

=head1 AUTHOR

David A Golden (DAGOLDEN)

dagolden@cpan.org

http://dagolden.com/

=head1 COPYRIGHT

Copyright (c) 2005 by David A Golden

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

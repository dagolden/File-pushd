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

=head1 NAME

File::pushd - temporary chdir until File::pushd object goes out of scope

=head1 SYNOPSIS

 use File::pushd;

 chdir $ENV{HOME};
 {
     my $dir = pushd( '/tmp' );
     # working directory changed to /tmp
 }
 # working directory reverted to $ENV{HOME}

=head1 DESCRIPTION

File::pushd does a temporary C<chdir> that is easily and automatically
reverted.  It works by creating a simple object that caches the original
working directory.  When the object is destroyed, the destructor calls C<chdir>
to revert to the working directory at the time the object was created.

=head1 USAGE

 use File::pushd;

Using File::pushd automatically imports the C<pushd> function.

File::pushd also overloads stringification so that objects created with
C<pushd> stringify as the absolute filepath that was set when the object was
created.

=cut

#--------------------------------------------------------------------------#
# pushd()
#--------------------------------------------------------------------------#

=head2 pushd

 $dir = pushd( $target_directory);

Caches the current working directory, changes the working directory to the
target directory, and returns a File::pushd object.  When the object is
destroyed, the working directory is reverted to the original directory.

=cut

sub pushd {
    my ($target_dir) = @_;
    
    my $orig = Cwd::abs_path();
    my $dest 
        = File::Spec->file_name_is_absolute( $target_dir )
        ? $target_dir
        : File::Spec->catdir( $orig, $target_dir );
    
    chdir $dest or croak "Couldn't chdir to nonexistant directory $dest";

    my $self = { 
        original => $orig,
        cwd => Cwd::abs_path(),
    };
    bless $self, __PACKAGE__;
    return $self;
}

#--------------------------------------------------------------------------#
# DESTROY()
# Revert to original directory as object is destroyed
#--------------------------------------------------------------------------#

sub DESTROY {
	my ($self) = @_;
    chdir $self->{original};
}

#--------------------------------------------------------------------------#
# as_string()
#--------------------------------------------------------------------------#

=head2 as_string

 print "$dir"; # calls $dir->as_string()

Returns the absolute path of the working directory set by the pushd object.
Used automatically when the object is stringified.

=cut

sub as_string {
	my ($self) = @_;
    return $self->{cwd};
}

1; #this line is important and will help the module return a true value
__END__

=head1 SEE ALSO

L<File::chdir>

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

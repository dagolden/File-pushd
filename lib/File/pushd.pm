package File::pushd;
use strict;
use warnings;
use Carp;
use File::Spec;
use File::Temp qw();
use File::Path qw();
use Cwd;

use overload 
    q{""} => \&as_string
;

BEGIN {
    use Exporter qw();
    use vars qw ($VERSION @ISA @EXPORT);
    $VERSION     = '0.20';
    @ISA         = qw (Exporter);
    @EXPORT      = qw (pushd tempd);
}

#--------------------------------------------------------------------------#
# main pod documentation 
#--------------------------------------------------------------------------#

=head1 NAME

File::pushd - temporary chdir for a limited scope

=head1 SYNOPSIS

 use File::pushd;

 chdir $ENV{HOME};
 
 # change directory again for a limited scope
 {
     my $dir = pushd( '/tmp' );
     # working directory changed to /tmp
 }
 # working directory has reverted to $ENV{HOME}

 # equivalent to pushd( File::Temp::tempdir )
 {
     my $dir = tempd();
 }

=head1 DESCRIPTION

File::pushd does a temporary C<chdir> that is easily and automatically
reverted.  It works by creating a simple object that caches the original
working directory.  When the object is destroyed, the destructor calls C<chdir>
to revert to the original working directory.  By storing the object in a
lexical variable with a limited scope, this happens automatically at the end of
the scope.

As this is very handy when working with temporary directories for tasks like
testing, a function is provided to streamline getting a temporary
directory from L<File::Temp>.  

=head1 USAGE

 use File::pushd;

Using File::pushd automatically imports the C<pushd> and C<tempd> functions.

File::pushd also overloads stringification so that objects created with
C<pushd> or C<tempd> stringify as the absolute filepath that was set when the
object was created.

=cut

#--------------------------------------------------------------------------#
# pushd()
#--------------------------------------------------------------------------#

=head2 pushd

 {
     my $dir = pushd( $target_directory );
 }

Caches the current working directory, calls C<chdir> to change to the target
directory, and returns a File::pushd object.  When the object is destroyed, the
working directory reverts to the original directory.

The target directory can either be a relative or absolute path. If called with
no arguments, it uses the current directory as its target and returns to the
current directory when the object is destroyed.

=cut

sub pushd {
    my ($target_dir) = @_;
    
    my $orig = Cwd::abs_path();
    my $dest;

    if ( $target_dir ) {
        $dest   = File::Spec->file_name_is_absolute( $target_dir )
                ? $target_dir 
                : File::Spec->catdir( $orig, $target_dir );
    }
    else {
        $dest = '';
    }
    
    if ( $dest ) {
        chdir $dest or croak "Couldn't chdir to nonexistant directory $dest";
    }

    my $self = { 
        original => $orig,
        cwd => Cwd::abs_path(),
    };
    bless $self, __PACKAGE__;
    return $self;
}

#--------------------------------------------------------------------------#
# tempd()
#--------------------------------------------------------------------------#

=head2 tempd

 {
     my $dir = tempd();
 }

Like C<pushd> but automatically create and C<chdir> to a temporary directory
from L<File::Temp>. Unlike normal L<File::Temp> cleanup which happens at the
end of the program, this temporary directory is removed when the object is
destroyed.  A warning will be issued if the directory cannot be removed.

=cut

sub tempd {
    my $dir = pushd( File::Temp::tempdir() );
    $dir->{cleanup} = 1;
    return $dir;
}


#--------------------------------------------------------------------------#
# DESTROY()
# Revert to original directory as object is destroyed and cleanup
# if necessary
#--------------------------------------------------------------------------#

sub DESTROY {
    my ($self) = @_;
    chdir $self->{original};
    if ( $self->{cleanup} ) {
        eval { File::Path::rmtree( $self->{cwd} ) };
        carp $@ if $@;
    }
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

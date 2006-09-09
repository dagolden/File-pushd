package File::pushd;
use strict;
use warnings;
use Carp;
use Exporter 'import';
use File::Temp qw();
use Path::Class;
use base 'Path::Class::Dir';

BEGIN {
    use vars qw ($VERSION @EXPORT);
    $VERSION     = "0.23";
    @EXPORT      = qw (pushd tempd);
}

#--------------------------------------------------------------------------#
# main pod documentation 
#--------------------------------------------------------------------------#

=head1 NAME

File::pushd - change directory temporarily for a limited scope

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

 # $dir is a Path::Class::Dir object
 {
     my $dir = pushd( '/tmp' );
     print "Contents of $dir:\n";
     print "  $_\n" for $dir->children();
 }

=head1 DESCRIPTION

File::pushd does a temporary C<chdir> that is easily and automatically
reverted, similar to C<pushd> in some Unix command shells.  It works by
creating an object that caches the original working directory.  When the object
is destroyed, the destructor calls C<chdir> to revert to the original working
directory.  By storing the object in a lexical variable with a limited scope,
this happens automatically at the end of the scope.

This is very handy when working with temporary directories for tasks like
testing; a function is provided to streamline getting a temporary
directory from L<File::Temp>.  

The directory objects created are subclassed from L<Path::Class::Dir>, and 
provide all the power and simplicity of L<Path::Class>.

=head1 USAGE

 use File::pushd;

Using File::pushd automatically imports the C<pushd> and C<tempd> functions.

=cut

#--------------------------------------------------------------------------#
# pushd()
#--------------------------------------------------------------------------#

=head2 pushd

 {
     my $dir = pushd( $target_directory );
 }

Caches the current working directory, calls C<chdir> to change to the target
directory, and returns a File::pushd object (which is a subclass of a
L<Path::Class::Dir> object with an absolute pathname).  When the object is
destroyed, the working directory reverts to the original directory.

The provided target directory can either be a relative or absolute path. If
called with no arguments, it uses the current directory as its target and
returns to the current directory when the object is destroyed.

=cut

sub pushd {
    my ($target_dir) = @_;
    
    my $orig = dir()->absolute;
    my $dest;

    if ( $target_dir ) {
        my $tgt = dir($target_dir);
        $dest   = $tgt->is_absolute
                ? $tgt 
                : $orig->subdir( $tgt )->absolute;
    }
    else {
        $dest = '';
    }
    
    if ( $dest ) {
        chdir $dest or croak "Couldn't chdir to nonexistant directory $dest";
    }

    my $self = bless dir()->absolute, __PACKAGE__;
    $self->{__PACKAGE__ . "_original"} = $orig;
    return $self;
}

#--------------------------------------------------------------------------#
# tempd()
#--------------------------------------------------------------------------#

=head2 tempd

 {
     my $dir = tempd();
 }

This function is like C<pushd> but automatically creates and calls C<chdir> to
a temporary directory as created by L<File::Temp>. Unlike normal L<File::Temp>
cleanup which happens at the end of the program, this temporary directory is
removed when the object is destroyed. (But also see C<preserve>.)  A warning
will be issued if the directory cannot be removed.

=cut

sub tempd {
    my $dir = pushd( File::Temp::tempdir() );
    $dir->{__PACKAGE__ . "_tempd"} = 1;
    return $dir;
}

=head2 preserve 

 {
     my $dir = tempd();
     $dir->preserve;      # mark to preserve at end of scope
     $dir->preserve(0);   # mark to delete at end of scope
 }

Controls whether a temporary directory will be cleaned up when the object is
destroyed.  With no arguments, C<preserve> sets the directory to be preserved.
With an argument, the directory will be preserved if the argument is true, or
marked for cleanup if the argument is false.  Only C<tempd> objects may be
marked for cleanup.  (Target directories to C<pushd> are always preserved.)
C<preserve> returns true if the directory will be preserved, and false
otherwise.

=cut

sub preserve {
    my $self = shift;
    return 1 if ! $self->{__PACKAGE__. "_tempd"};
    if ( @_ == 0 ) {
        return $self->{__PACKAGE__ . "_preserve"} = 1;
    }
    else {
        return $self->{__PACKAGE__ . "_preserve"} = $_[0] ? 1 : 0;
    }
}
    
#--------------------------------------------------------------------------#
# new() -- make this give an actual Path::Class::Dir object
# done this way to prevent Test::Pod::Coverage from complaining
#--------------------------------------------------------------------------#

=head2 new
 
C<new> should never be used directly.  It is a passthrough function that exists
to ensure that directories derived from a C<File::pushd> are just regular
C<Path::Class::Dir> objects.

=cut

sub new { 
    shift; 
    return dir( @_ );
}

#--------------------------------------------------------------------------#
# DESTROY()
# Revert to original directory as object is destroyed and cleanup
# if necessary
#--------------------------------------------------------------------------#

sub DESTROY {
    my ($self) = @_;
    my $orig = $self->{__PACKAGE__ . "_original"};
    chdir $orig if $orig; # should always be so, but just in case...
    if ( $self->{__PACKAGE__ . "_tempd"} && 
        !$self->{__PACKAGE__ . "_preserve"} ) {
        eval { $self->rmtree };
        carp $@ if $@;
    }
}

1; #this line is important and will help the module return a true value
__END__

=head1 SEE ALSO

L<Path::Class>, L<File::chdir>

=head1 BUGS

Please report bugs using the CPAN Request Tracker at 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-pushd>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHOR

David A Golden (DAGOLDEN)

dagolden@cpan.org

L<http://dagolden.com/>

=head1 COPYRIGHT

Copyright (c) 2005 by David A Golden

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

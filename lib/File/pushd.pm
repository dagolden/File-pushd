use 5.005;
use strict;
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }
package File::pushd;
# ABSTRACT: change directory temporarily for a limited scope
# VERSION

use vars qw/@EXPORT @ISA/;
@EXPORT  = qw( pushd tempd );
@ISA     = qw( Exporter );

use Exporter;
use Carp;
use Cwd         qw( cwd abs_path );
use File::Path  qw( rmtree );
use File::Temp  qw();
use File::Spec;

use overload 
    q{""} => sub { File::Spec->canonpath( $_[0]->{_pushd} ) },
    fallback => 1;

#--------------------------------------------------------------------------#
# pushd()
#--------------------------------------------------------------------------#

sub pushd {
    my ($target_dir, $options) = @_;
    $options->{untaint_pattern} ||= qr{^([-+@\w./]+)$};
    
    my $tainted_orig = cwd;
    my $orig;
    if ( $tainted_orig =~ $options->{untaint_pattern} ) {
      $orig = $1;
    }
    else {
      $orig = $tainted_orig;
    }
    
    my $tainted_dest;
    eval { $tainted_dest   = $target_dir ? abs_path( $target_dir ) : $orig };

    my $dest;
    if ( $tainted_dest =~ $options->{untaint_pattern} ) {
      $dest = $1;
    }
    else {
      $dest = $tainted_dest;
    }
    
    croak "Can't locate directory $target_dir: $@" if $@;
    
    if ($dest ne $orig) { 
        chdir $dest or croak "Can't chdir to $dest\: $!";
    }

    my $self = bless { 
        _pushd => $dest,
        _original => $orig
    }, __PACKAGE__;

    return $self;
}

#--------------------------------------------------------------------------#
# tempd()
#--------------------------------------------------------------------------#

sub tempd {
    my ($options) = @_;
    my $dir;
    eval { $dir = pushd( File::Temp::tempdir( CLEANUP => 0 ), $options ) };
    croak $@ if $@;
    $dir->{_tempd} = 1;
    return $dir;
}

#--------------------------------------------------------------------------#
# preserve()
#--------------------------------------------------------------------------#

sub preserve {
    my $self = shift;
    return 1 if ! $self->{"_tempd"};
    if ( @_ == 0 ) {
        return $self->{_preserve} = 1;
    }
    else {
        return $self->{_preserve} = $_[0] ? 1 : 0;
    }
}
    
#--------------------------------------------------------------------------#
# DESTROY()
# Revert to original directory as object is destroyed and cleanup
# if necessary
#--------------------------------------------------------------------------#

sub DESTROY {
    my ($self) = @_;
    my $orig = $self->{_original};
    chdir $orig if $orig; # should always be so, but just in case...
    if ( $self->{_tempd} && 
        !$self->{_preserve} ) {
        eval { rmtree( $self->{_pushd} ) };
        carp $@ if $@;
    }
}

1;

__END__

=begin wikidoc

= SYNOPSIS

 use File::pushd;

 chdir $ENV{HOME};
 
 # change directory again for a limited scope
 {
     my $dir = pushd( '/tmp' );
     # working directory changed to /tmp
 }
 # working directory has reverted to $ENV{HOME}

 # tempd() is equivalent to pushd( File::Temp::tempdir )
 {
     my $dir = tempd();
 }

 # object stringifies naturally as an absolute path
 {
    my $dir = pushd( '/tmp' );
    my $filename = File::Spec->catfile( $dir, "somefile.txt" );
    # gives /tmp/somefile.txt
 }
    
= DESCRIPTION

File::pushd does a temporary {chdir} that is easily and automatically
reverted, similar to {pushd} in some Unix command shells.  It works by
creating an object that caches the original working directory.  When the object
is destroyed, the destructor calls {chdir} to revert to the original working
directory.  By storing the object in a lexical variable with a limited scope,
this happens automatically at the end of the scope.

This is very handy when working with temporary directories for tasks like
testing; a function is provided to streamline getting a temporary
directory from [File::Temp].

For convenience, the object stringifies as the canonical form of the absolute
pathname of the directory entered.

= USAGE

 use File::pushd;

Using File::pushd automatically imports the {pushd} and {tempd} functions.

== pushd

 {
     my $dir = pushd( $target_directory );
 }

Caches the current working directory, calls {chdir} to change to the target
directory, and returns a File::pushd object.  When the object is
destroyed, the working directory reverts to the original directory.

The provided target directory can be a relative or absolute path. If
called with no arguments, it uses the current directory as its target and
returns to the current directory when the object is destroyed.

If the target directory does not exist or if the directory change fails 
for some reason, {pushd} will die with an error message.

== tempd

 {
     my $dir = tempd();
 }

This function is like {pushd} but automatically creates and calls {chdir} to
a temporary directory created by [File::Temp]. Unlike normal [File::Temp]
cleanup which happens at the end of the program, this temporary directory is
removed when the object is destroyed. (But also see {preserve}.)  A warning
will be issued if the directory cannot be removed.

As with {pushd}, {tempd} will die if {chdir} fails.

== preserve 

 {
     my $dir = tempd();
     $dir->preserve;      # mark to preserve at end of scope
     $dir->preserve(0);   # mark to delete at end of scope
 }

Controls whether a temporary directory will be cleaned up when the object is
destroyed.  With no arguments, {preserve} sets the directory to be preserved.
With an argument, the directory will be preserved if the argument is true, or
marked for cleanup if the argument is false.  Only {tempd} objects may be
marked for cleanup.  (Target directories to {pushd} are always preserved.)
{preserve} returns true if the directory will be preserved, and false
otherwise.

= SEE ALSO

* [File::chdir]

=end wikidoc

=cut


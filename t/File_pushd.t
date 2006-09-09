# File::pushd - check module loading and create testing directory
use strict;
use warnings;

use Test::More tests =>  19 ;
use Cwd qw( abs_path );
use File::Spec;
use File::Path;

#--------------------------------------------------------------------------#
# Test import
#--------------------------------------------------------------------------#

BEGIN { use_ok( 'File::pushd' ); }
can_ok( 'main', 'pushd', 'tempd' );

#--------------------------------------------------------------------------#
# Setup
#--------------------------------------------------------------------------#

sub abscatdir {
    return abs_path( File::Spec->catdir( @_ ) );
}

my ( $new_dir, $temp_dir, $err );
my $original_dir = abs_path();
my $target_dir = 't';
my $expected_dir = abscatdir( $original_dir, $target_dir );
my $nonexistant = 'DFASDFASDFASDFAS';

#--------------------------------------------------------------------------#
# Test error handling on bad target
#--------------------------------------------------------------------------#

eval { $new_dir = pushd($nonexistant) };
$err = $@;
like( $@, qr/\ACouldn't chdir to nonexistant directory/,
    "pushd to nonexistant directory croaks" );

#--------------------------------------------------------------------------#
# Test changing to relative path directory
#--------------------------------------------------------------------------#

$new_dir = pushd($target_dir);

isa_ok( $new_dir, 'File::pushd' );

is( abs_path(), $expected_dir, "change directory on pushd (relative path)" );

#--------------------------------------------------------------------------#
# Test stringification
#--------------------------------------------------------------------------#

is( "$new_dir", $expected_dir, "object stringifies" );

#--------------------------------------------------------------------------#
# Test reverting directory
#--------------------------------------------------------------------------#

undef $new_dir;

is( abs_path(), $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing to absolute path directory and reverting
#--------------------------------------------------------------------------#

$new_dir = pushd($expected_dir);
is( abs_path(), $expected_dir, "change directory on pushd (absolute path)" );

undef $new_dir;
is( abs_path(), $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing upwards
#--------------------------------------------------------------------------#

$new_dir = pushd("..");
$expected_dir = abscatdir($original_dir, "..");

is( abs_path(), $expected_dir, "change directory on pushd (upwards)" );
undef $new_dir;
is( abs_path(), $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing to root 
#--------------------------------------------------------------------------#

$new_dir = pushd( File::Spec->rootdir() );

is( abs_path(), abs_path(File::Spec->rootdir()) , 
    "change directory on pushd (root)" );
undef $new_dir;
is( abs_path(), $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing in place
#--------------------------------------------------------------------------#

$new_dir = pushd( );

is( abs_path(), $original_dir, 
    "pushd with no argument doesn't change directory" 
);
chdir "t";
is( abs_path(), abscatdir( $original_dir, "t" ),
    "changing manually to another directory"
);
undef $new_dir;
is( abs_path(), $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing to temporary dir
#--------------------------------------------------------------------------#

$new_dir = tempd();
$temp_dir = "$new_dir";

ok( abs_path() ne $original_dir, "tempd changes to new temporary directory" );

undef $new_dir;
is( abs_path(), $original_dir,
    "revert directory when variable goes out of scope"
);

ok( ! -e $temp_dir, "temporary directory cleaned up" );


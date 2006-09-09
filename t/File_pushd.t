# File::pushd - check module loading and create testing directory

use Test::More tests =>  6 ;
use Cwd qw( abs_path );
use File::Spec;

#--------------------------------------------------------------------------#
# Test import
#--------------------------------------------------------------------------#

BEGIN { use_ok( 'File::pushd' ); }
can_ok( 'main', 'pushd' );

#--------------------------------------------------------------------------#
# Setup
#--------------------------------------------------------------------------#

my $original_dir = abs_path();
my $target_dir = 't';
my $expected_dir 
    = abs_path( File::Spec->catdir( $original_dir, $target_dir ) );

#--------------------------------------------------------------------------#
# Test changing to relative directory
#--------------------------------------------------------------------------#

my $new_dir = pushd($target_dir);

isa_ok( $new_dir, 'File::pushd' );

is( abs_path(), $expected_dir, "change directory on pushd (relative)" );

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

    


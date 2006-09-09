# File::pushd - check module loading and create testing directory
use strict;
use warnings;

use Test::More tests =>  36 ;
use Path::Class;

#--------------------------------------------------------------------------#
# Test import
#--------------------------------------------------------------------------#

BEGIN { use_ok( 'File::pushd' ); }
can_ok( 'main', 'pushd', 'tempd' );

#--------------------------------------------------------------------------#
# Setup
#--------------------------------------------------------------------------#


my ( $new_dir, $temp_dir, $err );
my $original_dir = dir()->absolute;
my $target_dir = 't';
my $expected_dir = $original_dir->subdir($target_dir);
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
isa_ok( $new_dir, 'Path::Class::Dir' );

my $derived = $new_dir->parent;
is( ref $derived, 'Path::Class::Dir', 
    "derived directories revert to Path::Class::Dir" 
);

is( dir()->absolute, $expected_dir, "change directory on pushd (relative path)" );

#--------------------------------------------------------------------------#
# Test stringification
#--------------------------------------------------------------------------#

is( "$new_dir", $expected_dir, "object stringifies" );

#--------------------------------------------------------------------------#
# Test reverting directory
#--------------------------------------------------------------------------#

undef $new_dir;

is( dir()->absolute, $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing to absolute path directory and reverting
#--------------------------------------------------------------------------#

$new_dir = pushd($expected_dir);
is( dir()->absolute, $expected_dir, "change directory on pushd (absolute path)" );

undef $new_dir;
is( dir()->absolute, $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing upwards
#--------------------------------------------------------------------------#

$new_dir = pushd("..");
$expected_dir = $original_dir->parent;

is( dir()->absolute, $expected_dir, "change directory on pushd (upwards)" );
undef $new_dir;
is( dir()->absolute, $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing to root 
#--------------------------------------------------------------------------#

$new_dir = pushd( dir('') );

# roundtrip dir() to drop volume (File::Spec bug workaround)
my $curdir = dir()->absolute->relative->absolute;

is( $curdir, dir('')->absolute,
    "change directory on pushd (root)" );
undef $new_dir;
is( dir()->absolute(), $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing in place
#--------------------------------------------------------------------------#

$new_dir = pushd( );

is( dir()->absolute(), $original_dir, 
    "pushd with no argument doesn't change directory" 
);
chdir "t";
is( dir()->absolute(), $original_dir->subdir( "t" ) ,
    "changing manually to another directory"
);
undef $new_dir;
is( dir()->absolute(), $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing to temporary dir
#--------------------------------------------------------------------------#

$new_dir = tempd();
$temp_dir = "$new_dir";

ok( dir()->absolute() ne $original_dir, 
    "tempd changes to new temporary directory" );

undef $new_dir;
is( dir()->absolute(), $original_dir,
    "revert directory when variable goes out of scope"
);

ok( ! -e $temp_dir, "temporary directory cleaned up" );

#--------------------------------------------------------------------------#
# Test changing to temporary dir but preserving it
#--------------------------------------------------------------------------#

$new_dir = tempd();
$temp_dir = dir($new_dir);

ok( dir()->absolute() ne $original_dir, 
    "tempd changes to new temporary directory" );

ok( $new_dir->preserve(1), "mark temporary directory for preservation" );
    
undef $new_dir;
is( dir()->absolute(), $original_dir,
    "revert directory when variable goes out of scope"
);

ok( -e $temp_dir, "temporary directory preserved" );

ok( $temp_dir->rmtree, "temporary directory manually cleaned up" ); 

#--------------------------------------------------------------------------#
# Test changing to temporary dir, preserve it, then revert
#--------------------------------------------------------------------------#

$new_dir = tempd();
$temp_dir = dir($new_dir);

ok( dir()->absolute() ne $original_dir, 
    "tempd changes to new temporary directory" );

ok( $new_dir->preserve, "mark temporary directory for preservation" );
ok( ! $new_dir->preserve(0), "mark temporary directory for removal" );
    
undef $new_dir;
is( dir()->absolute(), $original_dir,
    "revert directory when variable goes out of scope"
);

ok( ! -e $temp_dir, "temporary directory removed" );
#--------------------------------------------------------------------------#
# Test preserve failing on non temp directory
#--------------------------------------------------------------------------#

$new_dir = pushd( $original_dir->subdir( $target_dir ) );

is( dir()->absolute, $original_dir->subdir( $target_dir ), 
    "change directory on pushd" );
$temp_dir = dir($new_dir);

ok( $new_dir->preserve, "regular pushd is automatically preserved" );
ok( $new_dir->preserve(0), "can't mark regular pushd for deletion" );
    
undef $new_dir;
is( dir()->absolute(), $original_dir,
    "revert directory when variable goes out of scope"
);

ok( -e $expected_dir, "original directory not removed" );



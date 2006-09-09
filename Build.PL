use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new( 
    module_name         => 'File::pushd',
    dist_author         => 'David A Golden <dagolden@cpan.org>',
    license             => 'perl',
    create_readme       => 1,
    create_makefile_pl  => 'traditional',
    requires            => {
        perl            => 5.005,
        Test::More      => 0.48,
        File::Path      => 0,
        File::Spec      => 0,
        File::Temp      => 0,
        Path::Class     => 0.13,
    },
)->create_build_script;

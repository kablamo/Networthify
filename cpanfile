# Moose stuff
requires 'Moose';
requires 'MooseX::Params::Validate';
requires 'MooseX::ClassAttribute';

# Catalyst stuff
requires 'Catalyst';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::View::JSON';
requires 'Catalyst::View::TT';
requires 'Catalyst::Plugin::Assets';
requires 'Catalyst::Plugin::Cache::HTTP';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Log::Dispatch';
requires 'Catalyst::Plugin::StackTrace';
requires 'CatalystX::AuthenCookie';
requires 'CatalystX::Test::MockContext';

# Catalyst Devel stuff
requires 'Catalyst::Devel';
requires 'Catalyst::Helper::Model::DBIC::Schema';
requires 'MooseX::MarkAsMethods';
requires 'MooseX::NonMoose';
requires 'MooseX::Test::Role';

# Plack stuff
requires "Plack";
requires 'Plack::Middleware::Deflater';
requires 'Plack::Middleware::AccessLog::Timed';
requires 'Plack::Middleware::Assets';
requires 'Plack::Middleware::Rewrite';
requires 'Server::Starter';
requires 'Starman';
requires 'Net::Server::SS::PreFork';


# database stuff
requires 'DBD::SQLite';
requires 'DBI';
requires 'DBIx::Class';
requires "DBIx::Class::Schema::Loader";
requires "DBIx::Class::FilterColumn";
requires "DBIx::Class::InflateColumn::Authen::Passphrase";
requires "DBIx::Class::Helpers";
requires "SQL::Translator";

# random web stuff
requires 'Authen::Passphrase';
requires 'Config::General';
requires 'HTML::Scrubber';
#requires 'Math::Random::MT';
requires 'Time::HiRes';
requires 'URI::Escape';

# random stuff
requires 'DateTime';
requires 'JSON';
requires 'JSON::XS';
requires 'List::MoreUtils';
requires 'Log::Dispatch';
requires 'Log::Dispatch::Config';
requires 'Path::Class';
requires 'Directory::Scratch';
requires 'Number::Format';
requires 'Math::Round';
requires 'Data::Currency';
requires 'Text::CSV';
requires 'Text::Diff';
requires 'Locale::Currency';
requires 'File::Copy';
requires 'DateTime::Format::SQLite';
requires 'DateTime::Format::Natural';
requires 'List::AllUtils';
requires 'Clone';
requires 'List::Util';

# testing
requires 'Data::Printer';
requires 'Test::Most';

# vim: set ft=perl

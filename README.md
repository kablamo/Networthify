# Networthify

Personal finance for savings extremists and early retirement savants.

Track your financial progress and get useful detailed analytics. Know at a
glance how many working days you have left before retirement.

# How to contribute

## Step 1: Install cpanm

[cpanm](https://metacpan.org/pod/App::cpanminus) allows you to install Perl
modules from [CPAN](https://metacpan.org/).

There are Debian packages, RPMs, FreeBSD ports, and packages for other
operation systems available. Or you can do this:

    curl -L https://cpanmin.us | perl - --sudo App::cpanminus

## Step 2: Install Carton

[Carton](https://metacpan.org/pod/Carton) is a Perl module dependency manager
(aka Bundler for Perl).  

    cpanm Carton

## Step 3: Install SQLite3

[SQLite3](https://www.sqlite.org/) is a simple database. Recommended to install
via system packages.

## Step 4: Setup the website

    git clone git@github.com:kablamo/Networthify.git
    cd Networthify
    carton
    cat schema.sql | sqlite3 networth.db.dev
    script/createDemoUser
    script/updateDemoUser
    carton exec plackup

In your browser go to: http://localhost:5000

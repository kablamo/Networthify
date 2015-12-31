# Networthify

Personal finance for savings extremists and early retirement savants

Track your financial progress and get useful detailed analytics. Know at a
glance how many working days you have left before retirement.

# Setup

    # git clone 
    # cd Networth
    carton
    cat schema.sql | sqlite3 networth.db.dev
    script/createDemoUser
    script/updateDemoUser
    carton exec plackup

    # in your browser go to: http://localhost:5000

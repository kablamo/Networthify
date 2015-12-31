CREATE TABLE Account (
   accountId       integer not null primary key autoincrement,
   userId          integer not null,
   name            varchar not null,
   parentAccountId integer default null,
   foreign key (userId)          references User (userId),
   foreign key (parentAccountId) references Account (accountId)
);
CREATE TABLE Asset (
   assetId     integer not null primary key autoincrement,
   userId      integer not null,
   accountId   integer not null,
   description varchar not null,
   value       float   not null,
   date        date    not null,
   tag         varchar default null,
   foreign key (userId)     references User (userId),
   foreign key (accountId)  references Account (accountId)
);
CREATE TABLE ImportLog (
    importLogId          integer  not null primary key autoincrement,
    userId               integer  not null,
    accountId            integer  not null,
    date                 datetime default current_timestamp,
    assetId              integer  not null,
    foreign key (userId)     references User    (userId),
    foreign key (accountId)  references Account (accountId),
    foreign key (assetId)    references Asset   (assetId)
);
CREATE TABLE MailingList (
   email      varchar not null primary key,
   beta       varchar default 'n'
);
CREATE TABLE Networth (
   networthId  integer not null primary key autoincrement,
   userId      integer not null,
   total       float   not null,
   date        date    not null,
   foreign key (userId) references User (userId)
);
CREATE TABLE Preferences (
   userId         integer not null primary key autoincrement,
   currencyCode   varchar default null,
   lastChanged    date    default CURRENT_TIMESTAMP,
   withdrawalRate float   default 4.0,
   roi            float   default 7.0,
   hourlyWage     float   default 20,
   workDay        float   default 8,
   daysPerYear    float   default 232,
   foreign key (userId) references User (userId)
);
CREATE TABLE TransactionHistory (
    transactionHistoryId integer  not null primary key autoincrement,
    action               varchar  not null,
    assetId              integer  not null,
    userId               integer  not null,
    accountId            integer  not null,
    date                 datetime default current_timestamp,
    newDescription       varchar  default null,
    newValue             float    default null,
    newDate              date     default null,
    newTag               varchar  default null,
    oldDescription       varchar  default null,
    oldValue             float    default null,
    oldDate              date     default null,
    oldTag               varchar  default null,
    foreign key (userId)     references User    (userId),
    foreign key (accountId)  references Account (accountId),
    foreign key (assetId)    references Asset   (assetId)
);
CREATE TABLE TransferLog (
    transferLogId        integer  not null primary key autoincrement,
    userId               integer  not null,
    date                 datetime default current_timestamp,
    toAccountId          integer  not null,
    toAssetId            integer  not null,
    fromAccountId        integer  not null,
    fromAssetId          integer  not null,
    description          varchar  default null,
    value                float    not null,
    transactionDate      date     not null,
    tag                  varchar  default null,
    foreign key (userId)         references User    (userId),
    foreign key (toAccountId)    references Account (accountId),
    foreign key (toAssetId)      references Asset   (assetId)
    foreign key (fromAccountId)  references Account (accountId),
    foreign key (fromAssetId)    references Asset   (assetId)
);
CREATE TABLE User (
   userId     integer not null primary key autoincrement,
   facebookId varchar default null,
   openId     varchar default null,
   username   varchar not null,
   password   varchar default null,
   email      varchar default null,
   gravatar   varchar default null,
   guest      varchar default 'y',
   slug       varchar default null,
   unique (username),
   unique (facebookId),
   unique (openId),
   unique (email)
);

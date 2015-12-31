-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Tue Dec  3 06:52:12 2013
-- 

BEGIN TRANSACTION;

--
-- Table: MailingList
--
DROP TABLE MailingList;

CREATE TABLE MailingList (
  email varchar NOT NULL,
  beta varchar DEFAULT 'n',
  PRIMARY KEY (email)
);

--
-- Table: User
--
DROP TABLE User;

CREATE TABLE User (
  userid INTEGER PRIMARY KEY NOT NULL,
  facebookid varchar DEFAULT null,
  openid varchar DEFAULT null,
  username varchar NOT NULL,
  password varchar DEFAULT null,
  email varchar DEFAULT null,
  gravatar varchar DEFAULT null,
  guest varchar DEFAULT 'y',
  slug varchar DEFAULT null
);

CREATE UNIQUE INDEX email_unique ON User (email);

CREATE UNIQUE INDEX facebookid_unique ON User (facebookid);

CREATE UNIQUE INDEX openid_unique ON User (openid);

CREATE UNIQUE INDEX username_unique ON User (username);

--
-- Table: p
--
DROP TABLE p;

CREATE TABLE p (
  userid int,
  currencycode text,
  lastchanged num,
  withdrawalrate real,
  roi real,
  hourlywage real,
  workday real,
  daysperyear real
);

--
-- Table: Account
--
DROP TABLE Account;

CREATE TABLE Account (
  accountid INTEGER PRIMARY KEY NOT NULL,
  userid integer NOT NULL,
  name varchar NOT NULL,
  parentaccountid integer DEFAULT null,
  FOREIGN KEY (parentaccountid) REFERENCES Account(accountid) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (userid) REFERENCES User(userid) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX Account_idx_parentaccountid ON Account (parentaccountid);

CREATE INDEX Account_idx_userid ON Account (userid);

--
-- Table: Networth
--
DROP TABLE Networth;

CREATE TABLE Networth (
  networthid INTEGER PRIMARY KEY NOT NULL,
  userid integer NOT NULL,
  total float NOT NULL,
  date date NOT NULL,
  FOREIGN KEY (userid) REFERENCES User(userid) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX Networth_idx_userid ON Networth (userid);

--
-- Table: Preferences
--
DROP TABLE Preferences;

CREATE TABLE Preferences (
  userid INTEGER PRIMARY KEY NOT NULL,
  currencycode varchar DEFAULT null,
  lastchanged date DEFAULT current_timestamp,
  withdrawalrate float DEFAULT 4.0,
  roi float DEFAULT 7.0,
  hourlywage float DEFAULT 20,
  workday float DEFAULT 8,
  daysperyear float DEFAULT 232,
  FOREIGN KEY (userid) REFERENCES User(userid) ON DELETE NO ACTION ON UPDATE NO ACTION
);

--
-- Table: Asset
--
DROP TABLE Asset;

CREATE TABLE Asset (
  assetid INTEGER PRIMARY KEY NOT NULL,
  userid integer NOT NULL,
  accountid integer NOT NULL,
  description varchar NOT NULL,
  value float NOT NULL,
  date date NOT NULL,
  tag varchar DEFAULT null,
  FOREIGN KEY (accountid) REFERENCES Account(accountid) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (userid) REFERENCES User(userid) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX Asset_idx_accountid ON Asset (accountid);

CREATE INDEX Asset_idx_userid ON Asset (userid);

--
-- Table: ImportLog
--
DROP TABLE ImportLog;

CREATE TABLE ImportLog (
  importlogid INTEGER PRIMARY KEY NOT NULL,
  userid integer NOT NULL,
  accountid integer NOT NULL,
  date datetime DEFAULT current_timestamp,
  assetid integer NOT NULL,
  FOREIGN KEY (accountid) REFERENCES Account(accountid) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (assetid) REFERENCES Asset(assetid) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (userid) REFERENCES User(userid) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX ImportLog_idx_accountid ON ImportLog (accountid);

CREATE INDEX ImportLog_idx_assetid ON ImportLog (assetid);

CREATE INDEX ImportLog_idx_userid ON ImportLog (userid);

--
-- Table: TransactionHistory
--
DROP TABLE TransactionHistory;

CREATE TABLE TransactionHistory (
  transactionhistoryid INTEGER PRIMARY KEY NOT NULL,
  action varchar NOT NULL,
  assetid integer NOT NULL,
  userid integer NOT NULL,
  accountid integer NOT NULL,
  date datetime DEFAULT current_timestamp,
  newdescription varchar DEFAULT null,
  newvalue float DEFAULT null,
  newdate date DEFAULT null,
  newtag varchar DEFAULT null,
  olddescription varchar DEFAULT null,
  oldvalue float DEFAULT null,
  olddate date DEFAULT null,
  oldtag varchar DEFAULT null,
  FOREIGN KEY (accountid) REFERENCES Account(accountid) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (assetid) REFERENCES Asset(assetid) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (userid) REFERENCES User(userid) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX TransactionHistory_idx_accountid ON TransactionHistory (accountid);

CREATE INDEX TransactionHistory_idx_assetid ON TransactionHistory (assetid);

CREATE INDEX TransactionHistory_idx_userid ON TransactionHistory (userid);

--
-- Table: TransferLog
--
DROP TABLE TransferLog;

CREATE TABLE TransferLog (
  transferlogid INTEGER PRIMARY KEY NOT NULL,
  userid integer NOT NULL,
  date datetime DEFAULT current_timestamp,
  toaccountid integer NOT NULL,
  toassetid integer NOT NULL,
  fromaccountid integer NOT NULL,
  fromassetid integer NOT NULL,
  description varchar DEFAULT null,
  value float NOT NULL,
  transactiondate date NOT NULL,
  tag varchar DEFAULT null,
  FOREIGN KEY (fromaccountid) REFERENCES Account(accountid) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (fromassetid) REFERENCES Asset(assetid) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (toaccountid) REFERENCES Account(accountid) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (toassetid) REFERENCES Asset(assetid) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (userid) REFERENCES User(userid) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX TransferLog_idx_fromaccountid ON TransferLog (fromaccountid);

CREATE INDEX TransferLog_idx_fromassetid ON TransferLog (fromassetid);

CREATE INDEX TransferLog_idx_toaccountid ON TransferLog (toaccountid);

CREATE INDEX TransferLog_idx_toassetid ON TransferLog (toassetid);

CREATE INDEX TransferLog_idx_userid ON TransferLog (userid);

COMMIT;

-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Thu Dec 31 01:42:43 2015
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
  userId INTEGER PRIMARY KEY NOT NULL,
  facebookId varchar DEFAULT null,
  openId varchar DEFAULT null,
  username varchar NOT NULL,
  password varchar DEFAULT null,
  email varchar DEFAULT null,
  gravatar varchar DEFAULT null,
  guest varchar DEFAULT 'y',
  slug varchar DEFAULT null
);

CREATE UNIQUE INDEX email_unique ON User (email);

CREATE UNIQUE INDEX facebookid_unique ON User (facebookId);

CREATE UNIQUE INDEX openid_unique ON User (openId);

CREATE UNIQUE INDEX username_unique ON User (username);

--
-- Table: Account
--
DROP TABLE Account;

CREATE TABLE Account (
  accountId INTEGER PRIMARY KEY NOT NULL,
  userId integer NOT NULL,
  name varchar NOT NULL,
  parentAccountId integer DEFAULT null,
  FOREIGN KEY (parentAccountId) REFERENCES Account(accountId) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (userId) REFERENCES User(userId) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX Account_idx_parentAccountId ON Account (parentAccountId);

CREATE INDEX Account_idx_userId ON Account (userId);

--
-- Table: Networth
--
DROP TABLE Networth;

CREATE TABLE Networth (
  networthId INTEGER PRIMARY KEY NOT NULL,
  userId integer NOT NULL,
  total float NOT NULL,
  date date NOT NULL,
  FOREIGN KEY (userId) REFERENCES User(userId) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX Networth_idx_userId ON Networth (userId);

--
-- Table: Preferences
--
DROP TABLE Preferences;

CREATE TABLE Preferences (
  userId INTEGER PRIMARY KEY NOT NULL,
  currencyCode varchar DEFAULT null,
  lastChanged date DEFAULT current_timestamp,
  withdrawalRate float DEFAULT 4.0,
  roi float DEFAULT 7.0,
  hourlyWage float DEFAULT 20,
  workDay float DEFAULT 8,
  daysPerYear float DEFAULT 232,
  FOREIGN KEY (userId) REFERENCES User(userId) ON DELETE NO ACTION ON UPDATE NO ACTION
);

--
-- Table: Asset
--
DROP TABLE Asset;

CREATE TABLE Asset (
  assetId INTEGER PRIMARY KEY NOT NULL,
  userId integer NOT NULL,
  accountId integer NOT NULL,
  description varchar NOT NULL,
  value float NOT NULL,
  date date NOT NULL,
  tag varchar DEFAULT null,
  FOREIGN KEY (accountId) REFERENCES Account(accountId) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (userId) REFERENCES User(userId) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX Asset_idx_accountId ON Asset (accountId);

CREATE INDEX Asset_idx_userId ON Asset (userId);

--
-- Table: ImportLog
--
DROP TABLE ImportLog;

CREATE TABLE ImportLog (
  importLogId INTEGER PRIMARY KEY NOT NULL,
  userId integer NOT NULL,
  accountId integer NOT NULL,
  date datetime DEFAULT current_timestamp,
  assetId integer NOT NULL,
  FOREIGN KEY (accountId) REFERENCES Account(accountId) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (assetId) REFERENCES Asset(assetId) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (userId) REFERENCES User(userId) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX ImportLog_idx_accountId ON ImportLog (accountId);

CREATE INDEX ImportLog_idx_assetId ON ImportLog (assetId);

CREATE INDEX ImportLog_idx_userId ON ImportLog (userId);

--
-- Table: TransactionHistory
--
DROP TABLE TransactionHistory;

CREATE TABLE TransactionHistory (
  transactionHistoryId INTEGER PRIMARY KEY NOT NULL,
  action varchar NOT NULL,
  assetId integer NOT NULL,
  userId integer NOT NULL,
  accountId integer NOT NULL,
  date datetime DEFAULT current_timestamp,
  newDescription varchar DEFAULT null,
  newValue float DEFAULT null,
  newDate date DEFAULT null,
  newTag varchar DEFAULT null,
  oldDescription varchar DEFAULT null,
  oldValue float DEFAULT null,
  oldDate date DEFAULT null,
  oldTag varchar DEFAULT null,
  FOREIGN KEY (accountId) REFERENCES Account(accountId) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (assetId) REFERENCES Asset(assetId) ON DELETE NO ACTION ON UPDATE NO ACTION,
  FOREIGN KEY (userId) REFERENCES User(userId) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE INDEX TransactionHistory_idx_accountId ON TransactionHistory (accountId);

CREATE INDEX TransactionHistory_idx_assetId ON TransactionHistory (assetId);

CREATE INDEX TransactionHistory_idx_userId ON TransactionHistory (userId);

COMMIT;

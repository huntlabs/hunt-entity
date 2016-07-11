module database.dbdrive.pgsql;

version(USE_PGSQL) :

import database.database;
import database.dbdrive.impl;

import std.database.front;
import std.database.postgres.database;

alias PGSqlDB = Database!DefaultPolicy;

alias PGDataBase = DataBaseImpl!(PGSqlDB);
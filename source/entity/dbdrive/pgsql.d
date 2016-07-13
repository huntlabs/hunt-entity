module entity.dbdrive.pgsql;

version(USE_PGSQL) :

import entity.database;
import entity.dbdrive.impl;

import std.database.front;
import std.database.postgres.database;

alias PGSqlDB = Database!DefaultPolicy;

alias PGDataBase = DataBaseImpl!(PGSqlDB);
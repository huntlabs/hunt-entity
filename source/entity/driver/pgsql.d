module entity.driver.pgsql;

version(USE_PGSQL) :

import entity.database;
import entity.driver.impl;

import std.database.front;
import std.database.postgres.database;

alias PGSqlDB = Database!DefaultPolicy;

alias PGDataBase = DataBaseImpl!(PGSqlDB);
module database.dbdrive.sqlite;

version(USE_SQLITE) :

import database.database;
import database.dbdrive.impl;

import std.database.front;
import std.database.sqlite.database;

alias LiteSqlDB = Database!DefaultPolicy;

alias LiteDataBase = DataBaseImpl!(LiteSqlDB);
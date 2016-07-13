module entity.dbdrive.sqlite;

version(USE_SQLITE) :

import entity.database;
import entity.dbdrive.impl;

import std.database.front;
import std.database.sqlite.database;

alias LiteSqlDB = Database!DefaultPolicy;

alias LiteDataBase = DataBaseImpl!(LiteSqlDB);
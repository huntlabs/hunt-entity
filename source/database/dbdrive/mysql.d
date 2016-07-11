module database.dbdrive.mysql;

version(USE_MYSQL) :

import database.database;
import database.dbdrive.impl;

import std.database.front;
import std.database.mysql.database;

alias MySqlDB = Database!DefaultPolicy;

alias MyDataBase = DataBaseImpl!(MySqlDB);
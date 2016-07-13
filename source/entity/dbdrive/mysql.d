module entity.dbdrive.mysql;

version(USE_MYSQL) :

import entity.database;
import entity.dbdrive.impl;

import std.database.front;
import std.database.mysql.database;

alias MySqlDB = Database!DefaultPolicy;

alias MyDataBase = DataBaseImpl!(MySqlDB);
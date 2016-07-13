module entity.driver.mysql;

version(USE_MYSQL) :

import entity.database;
import entity.driver.impl;

import std.database.front;
import std.database.mysql.database;

alias MySqlDB = Database!DefaultPolicy;

alias MyDataBase = DataBaseImpl!(MySqlDB);
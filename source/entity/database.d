module entity.database;

import ddbc.core;

import entity.query;

Query!T getQuery(T)(Connection con) if(isEntity!T){
	return Query!T(con.createStatement());
}


alias DateBase = Connection;
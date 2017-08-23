module entity.querybuilder.defined;

import entity;

/***
  MYSQL 5.7 SELECT Syntax https://dev.mysql.com/doc/refman/5.7/en/select.html
  SELECT
  [ALL | DISTINCT | DISTINCTROW ]
  [HIGH_PRIORITY]
  [STRAIGHT_JOIN]
  [SQL_SMALL_RESULT] [SQL_BIG_RESULT] [SQL_BUFFER_RESULT]
  [SQL_CACHE | SQL_NO_CACHE] [SQL_CALC_FOUND_ROWS]
  select_expr [, select_expr ...]
  [FROM table_references
  [PARTITION partition_list]
  [WHERE where_condition]
  [GROUP BY {col_name | expr | position}
  [ASC | DESC], ... [WITH ROLLUP]]
  [HAVING where_condition]
  [ORDER BY {col_name | expr | position}
  [ASC | DESC], ...]
  [LIMIT {[offset,] row_count | row_count OFFSET offset}]
  [PROCEDURE procedure_name(argument_list)]
  [INTO OUTFILE 'file_name'
  [CHARACTER SET charset_name]
  export_options
  | INTO DUMPFILE 'file_name'
  | INTO var_name [, var_name]]
  [FOR UPDATE | LOCK IN SHARE MODE]]

  MYSQL 5.7 INSERT Syntax https://dev.mysql.com/doc/refman/5.7/en/insert.html
  INSERT [LOW_PRIORITY | DELAYED | HIGH_PRIORITY] [IGNORE]
  [INTO] tbl_name
  [PARTITION (partition_name,...)]
  [(col_name,...)]
  {VALUES | VALUE} ({expr | DEFAULT},...),(...),...
  [ ON DUPLICATE KEY UPDATE
  col_name=expr
  [, col_name=expr] ... ]

  MYSQL 5.7 DELETE Syntax https://dev.mysql.com/doc/refman/5.7/en/delete.html
  DELETE [LOW_PRIORITY] [QUICK] [IGNORE] FROM tbl_name
  [PARTITION (partition_name,...)]
  [WHERE where_condition]
  [ORDER BY ...]
  [LIMIT row_count]

  MYSQL 5.7 UPDATE Syntax https://dev.mysql.com/doc/refman/5.7/en/update.html
  UPDATE [LOW_PRIORITY] [IGNORE] table_reference
  SET col_name1={expr1|DEFAULT} [, col_name2={expr2|DEFAULT}] ...
  [WHERE where_condition]
  [ORDER BY ...]
  [LIMIT row_count]
 ***/
enum JoinMethod {
	InnerJoin = " INNER JOIN ",
	LeftJoin = " LEFT JOIN ",
	RightJoin = " RIGHT JOIN ",
	FullJoin = " FULL JOIN ",
	CrossJoin = " CROSS JOIN ",
}
enum Method {
	Select = " SELECT ",
	Insert = " INSERT ",
	Update = " UPDATE ",
	Delete = " DELETE FROM"
}
enum Relation {
	And, 
	Or
}
enum CompareType {
    eq = "=", 
    ne = "!=", 
    gt = ">", 
    lt = "<", 
    ge = ">=", 
    le = "<=", 
    eqnull = "is",
    nenull = "is not"
}

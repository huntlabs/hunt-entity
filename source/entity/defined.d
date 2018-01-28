module entity.defined;

import entity;

//TableName
string Table(string name){return name;}
//ColumnName
string[] Column(string name){return ["Column",name];}

//Attribute
enum {
	Auto = 1001,
	AutoIncrement,
	PrimaryKey,
	NotNull,
}
//Relation
enum {
	None = 2001,
	Embedded,
	OneToOne,
	OneToMany,
	ManyToOne,
	ManyToMany,
}

class EntityFieldType{}

class String : EntityFieldType {

}

class Text : EntityFieldType {

}

class Integer : EntityFieldType {

}

class Real : EntityFieldType {

}

class Blob : EntityFieldType {

}

class Numeric : EntityFieldType {

}

class Monetary : EntityFieldType {

}

class Character : EntityFieldType {

}

class BinaryData : EntityFieldType {

}

class DataTime : EntityFieldType {

}

class Boolean : EntityFieldType {

}

class Enumerated : EntityFieldType {

}

class Geometric : EntityFieldType {

}

class NetworkAddress : EntityFieldType {

}

class BitString : EntityFieldType {

}

class TextSearch : EntityFieldType {

}

class UUID : EntityFieldType {

}

class XML : EntityFieldType {

}

class JSON : EntityFieldType {

}

class Array : EntityFieldType {

}

class Composite : EntityFieldType {

}

class Range : EntityFieldType {

}

class ObjectIdentifier : EntityFieldType {

}

class Pglsn : EntityFieldType {

}

class Pseudeo : EntityFieldType {

}

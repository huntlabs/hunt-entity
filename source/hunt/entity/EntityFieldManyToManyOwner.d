module hunt.entity.EntityFieldManyToManyOwner;


import hunt.entity;
import hunt.logging;


class EntityFieldManyToManyOwner(T : Object, F : Object = T,string MAPPEDBY = "") : EntityFieldInfo {
    
    private ManyToMany _mode;
    private string _primaryKey;
    private string _findString;
    private T[][string] _decodeCache;
    private EntityManager _em;

    this(EntityManager manager, string fileldName, string primaryKey, string tableName, ManyToMany mode, F owner, bool isMainMapped ) {
        // logDebug("ManyToManyOwner(%s,%s) not main mapped ( %s , %s , %s , %s ,%s )".format(T.stringof,F.stringof,fileldName,primaryKey,tableName,mode,isMainMapped));
        _em = manager;
        super(fileldName, "", tableName);
        _isMainMapped = isMainMapped;
        init(primaryKey, mode, owner);
    }

    this(EntityManager manager, string fileldName, string primaryKey, string tableName, ManyToMany mode, F owner, 
            bool isMainMapped ,JoinTable joinTable , JoinColumn jc  ,InverseJoinColumn ijc ) {
        // logDebug("ManyToManyOwner(%s,%s) main mapped( %s , %s , %s , %s ,%s , %s , %s , %s )".format(T.stringof,F.stringof,fileldName,primaryKey,tableName,mode,isMainMapped,joinTable,jc,ijc));
        _em = manager;
        super(fileldName, "", tableName);
        _isMainMapped = isMainMapped;
        _joinColumn = jc.name;
        _inverseJoinColumn = ijc.name;
        _joinTable = joinTable.name;
        init(primaryKey, mode, owner);
    }

    private void init(string primaryKey,  ManyToMany mode, F owner) {
        _mode = mode;       
        _enableJoin = _mode.fetch == FetchType.EAGER;    
        _primaryKey = primaryKey;
        static if(MAPPEDBY != "")
        {
            if(!_isMainMapped )
            {
                _inverseJoinColumn =  hunt.entity.utils.Common.getInverseJoinColumn!(T,MAPPEDBY).name;
                _joinColumn =   hunt.entity.utils.Common.getJoinColumn!(T,MAPPEDBY).name;
                _joinTable =   _em.getPrefix() ~ hunt.entity.utils.Common.getJoinTableName!(T,MAPPEDBY);
            }
        }
        
        // logDebug("----(%s , %s ,%s )".format(_joinColumn,_inverseJoinColumn,_joinTable));
        
        initJoinData();
    }

    private void initJoinData() {
        _joinSqlData = new JoinSqlBuild(); 
        _joinSqlData.tableName = _joinTable;
        if(_isMainMapped)
            _joinSqlData.joinWhere = getTableName() ~ "." ~ _primaryKey ~ " = " ~ _joinTable ~ "." ~ _joinColumn;
        else
            _joinSqlData.joinWhere = getTableName() ~ "." ~ _primaryKey ~ " = " ~ _joinTable ~ "." ~ _inverseJoinColumn;
        _joinSqlData.joinType = JoinType.LEFT;
        // foreach(value; _entityInfo.getFields()) {
        //     _joinSqlData.columnNames ~= value.getSelectColumn();
        // }
        // logDebug("many to many owner join sql : %s ".format(_joinSqlData));
    }

    override public string getSelectColumn() {
        return "";
    }



    public string getPrimaryKey() {return _primaryKey;}
    public ManyToMany getMode() {return _mode;}



    public T[] deSerialize(Row[] rows, int startIndex, bool isFromManyToOne) {
        T[] ret;
        if (_mode.fetch == FetchType.LAZY)
            return ret;
        return ret;
    }


    public void setMode(ManyToMany mode) {
        _mode = mode;
        _enableJoin = _mode.fetch == FetchType.EAGER;    
    }

    public LazyData getLazyData(Row row) {
        // logDebug("--- MappedBy : %s , row : %s ".format(_mode.mappedBy,row));

        RowData data = row.getAllRowData(getTableName());
        // logDebug("---data : %s , _primaryKey : %s ".format(data,_primaryKey));
        if (data is null)
            return null;
        if (data.getData(_primaryKey) is null)
            return null;
        // logDebug("---------------------");
        LazyData ret = new LazyData(_mode.mappedBy, data.getData(_primaryKey).value);
        return ret;
    }

}



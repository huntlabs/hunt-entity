module entity.criteria.Join;

import entity;

class Join(F,T) : Root!T{

    private JoinType _joinType;
    private EntityFieldInfo _info;
    private Root!F _from;

    this(Dialect dialect, EntityFieldInfo info, Root!F from, JoinType joinType = JoinType.INNER) {
        _info = info;
        _joinType = joinType;
        _from = from;
        super(dialect);
    }

    public EntityInfo!T opDispatch(string name)() {
        return super.opDispatch!(name)();
    }

    public string getJoinOnString() {
        return getTableName() ~ "." ~ getEntityInfo().getPrimaryKeyString() ~ " = " ~ _from.getTableName() ~ "." ~ _info.getJoinColumn();
    }





}
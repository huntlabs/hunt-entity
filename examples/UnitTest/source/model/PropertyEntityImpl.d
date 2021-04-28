module model.PropertyEntityImpl;


import hunt.entity;
import hunt.Exceptions;
import hunt.collection.Map;
import hunt.collection.HashMap;
import hunt.String;
/**
 * @author Tom Baeyens
 * @author Joram Barrez
 */
@Table("ACT_GE_PROPERTY")
class PropertyEntityImpl : Model {
     mixin MakeModel;

    @PrimaryKey
    @Column("NAME_")
     string name;

    @Column("VALUE_")
     string value;

    @Column("REV_")
     int rev;


    public string getIdPrefix() {
        // The name of the property is also the id of the property
        // therefore the id prefix is not needed
        return "";
    }


    public string getName() {
        return name;
    }


    public void setName(string name) {
        this.name = name;
    }


    public string getValue() {
        return value;
    }


    public void setValue(string value) {
        this.value = value;
    }


    public string getId() {
        return name;
    }


    public Object getPersistentState() {
        Map!(string,Object) object = new HashMap!(string,Object);
        object.put("value", new String(value));
        return cast(Object)object;
    }


    public void setId(string id) {
        throw new Exception("only provided id generation allowed for properties");
    }

    // common methods //////////////////////////////////////////////////////////


    override
    public string toString() {
        return "PropertyEntity[name=" ~ name ~ ", value=" ~ value ~ "]";
    }


}

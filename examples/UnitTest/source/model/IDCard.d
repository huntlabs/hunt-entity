module model.IDCard;

import hunt.entity;
import model.UserInfo;

@Table("IDCard")
class IDCard : Model {

    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;

    
    @Column("user_id")
    int uid;

    string desc;

    @OneToOne()
    @JoinColumn(uid.stringof, UserInfo.id.stringof)
    // @JoinColumn("user_id", UserInfo.id.stringof)
    UserInfo user;
}
